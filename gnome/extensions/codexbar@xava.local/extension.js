import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Clutter from 'gi://Clutter';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const REFRESH_SECONDS = 60;
const COMMAND = ['/usr/bin/codexbar', 'usage', '--provider', 'codex',
    '--format', 'json', '--no-color'];

Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

function clamp(value) {
    return Math.max(0, Math.min(100, Number(value) || 0));
}

function remainingText(used) {
    return `${Math.round(100 - clamp(used))}%`;
}

function resetText(iso) {
    if (!iso)
        return '—';

    const date = GLib.DateTime.new_from_iso8601(iso, null);
    if (!date)
        return '—';

    const now = GLib.DateTime.new_now_local();
    const local = date.to_timezone(now.get_timezone());
    const seconds = Math.max(0, Math.floor(local.difference(now) / GLib.TIME_SPAN_SECOND));
    if (seconds < 60)
        return '<1 dk';
    if (seconds < 3600)
        return `${Math.ceil(seconds / 60)} dk`;
    if (seconds < 86400)
        return `${Math.floor(seconds / 3600)} sa ${Math.ceil((seconds % 3600) / 60)} dk`;
    return `${Math.floor(seconds / 86400)} gün ${Math.floor((seconds % 86400) / 3600)} sa`;
}

const UsageRow = GObject.registerClass(
class UsageRow extends St.BoxLayout {
    _init(title) {
        super._init({vertical: true, style_class: 'codexbar-usage-row'});

        const header = new St.BoxLayout({x_expand: true});
        this._title = new St.Label({text: title, x_expand: true,
            y_align: Clutter.ActorAlign.CENTER});
        this._value = new St.Label({style_class: 'codexbar-value',
            y_align: Clutter.ActorAlign.CENTER});
        header.add_child(this._title);
        header.add_child(this._value);
        this.add_child(header);

        this._track = new St.Bin({style_class: 'codexbar-progress-track', x_expand: true});
        this._fill = new St.Widget({style_class: 'codexbar-progress-fill'});
        this._track.set_child(this._fill);
        this.add_child(this._track);
        this._remaining = 0;
        this._track.connect('notify::width', () => this._resizeFill());

        this._reset = new St.Label({style_class: 'codexbar-reset'});
        this.add_child(this._reset);
    }

    update(window) {
        const used = clamp(window?.usedPercent);
        this._remaining = 100 - used;
        this._value.text = `${remainingText(used)} kaldı`;
        this._reset.text = `Yenilenmesine ${resetText(window?.resetsAt)}`;
        this._resizeFill();
    }

    _resizeFill() {
        this._fill.width = Math.max(2, Math.round(this._track.width * this._remaining / 100));
    }
});

const CodexBarIndicator = GObject.registerClass(
class CodexBarIndicator extends PanelMenu.Button {
    _init(extensionPath) {
        super._init(0.0, 'CodexBar Usage', false);

        const box = new St.BoxLayout({style_class: 'panel-status-menu-box codexbar-panel'});
        const iconFile = Gio.File.new_for_path(
            GLib.build_filenamev([extensionPath, 'icons', 'robot-symbolic.svg']));
        this._icon = new St.Icon({gicon: new Gio.FileIcon({file: iconFile}),
            style_class: 'system-status-icon'});
        box.add_child(this._icon);
        this.add_child(box);

        const titleItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        this._account = new St.Label({text: 'Codex', style_class: 'codexbar-account'});
        titleItem.add_child(this._account);
        this.menu.addMenuItem(titleItem);

        const usageItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        const rows = new St.BoxLayout({vertical: true, x_expand: true});
        this._primary = new UsageRow('5 saatlik limit');
        this._secondary = new UsageRow('Haftalık limit');
        rows.add_child(this._primary);
        rows.add_child(this._secondary);
        usageItem.add_child(rows);
        this.menu.addMenuItem(usageItem);

        this._metaItem = new PopupMenu.PopupMenuItem('Veri bekleniyor…', {reactive: false});
        this.menu.addMenuItem(this._metaItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.menu.addAction('Şimdi yenile', () => this.refresh());

        this._busy = false;
        this._timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT,
            REFRESH_SECONDS, () => {
                this.refresh();
                return GLib.SOURCE_CONTINUE;
            });
        this.refresh();
    }

    async refresh() {
        if (this._busy)
            return;
        this._busy = true;
        this._icon.add_style_class_name('codexbar-refreshing');

        try {
            const process = Gio.Subprocess.new(COMMAND,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
            const [stdout, stderr] = await process.communicate_utf8_async(null, null);
            if (!process.get_successful())
                throw new Error(stderr?.trim() || `codexbar ${process.get_exit_status()}`);

            const result = JSON.parse(stdout);
            const entry = Array.isArray(result) ? result[0] : result;
            if (entry?.error)
                throw new Error(entry.error.message || 'CodexBar hatası');
            if (!entry?.usage)
                throw new Error('Kullanım verisi bulunamadı');
            this._render(entry);
        } catch (error) {
            this._metaItem.label.text = `Hata: ${error.message}`;
            logError(error, 'CodexBar verisi alınamadı');
        } finally {
            this._busy = false;
            this._icon.remove_style_class_name('codexbar-refreshing');
        }
    }

    _render(entry) {
        const usage = entry.usage;
        const primary = usage.primary;
        const secondary = usage.secondary;
        this._account.text = usage.accountEmail || usage.identity?.accountEmail || 'Codex';
        this._primary.update(primary);
        this._secondary.update(secondary);
        const source = entry.source ? ` · ${entry.source}` : '';
        const resetCount = usage.codexResetCredits?.availableCount ?? 0;
        this._metaItem.label.text = `Kesin veri${source} · ${resetCount} reset hakkı`;
    }

    destroy() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = 0;
        }
        super.destroy();
    }
});

export default class CodexBarExtension extends Extension {
    enable() {
        this._indicator = new CodexBarIndicator(this.path);
        Main.panel.addToStatusArea(this.uuid, this._indicator, 0, 'right');
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}

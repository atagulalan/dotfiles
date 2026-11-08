// SPDX-License-Identifier: GPL-2.0-or-later
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {QuickSettingsItem} from 'resource:///org/gnome/shell/ui/quickSettings.js';
import {IconActor, SNIStatus} from './appIndicator.js';
import {Client} from './dbusMenu.js';
import {connectSmart} from './util.js';

const ICON_BUTTON = 44;
const ICON_GAP = 12;

export const TraySection = GObject.registerClass(
class TraySection extends QuickSettingsItem {
    _init() {
        super._init({hasMenu: true, reactive: false, can_focus: false,
            style_class: 'xava-tray', x_expand: true});
        this._items = new Map();
        this._allocWidth = 0;
        const box = new St.BoxLayout({orientation: Clutter.Orientation.VERTICAL,
            x_expand: true});
        this.set_child(box);
        box.add_child(new St.Label({text: 'System Tray', style_class: 'xava-tray-heading', x_align: Clutter.ActorAlign.START}));
        this._empty = new St.Label({text: 'No tray applications running',
            style_class: 'xava-tray-empty', x_expand: true});
        this._empty.clutter_text.line_wrap = true;
        box.add_child(this._empty);
        this._scroll = new St.ScrollView({style_class: 'xava-tray-scroll',
            x_expand: true,
            hscrollbar_policy: St.PolicyType.NEVER, vscrollbar_policy: St.PolicyType.AUTOMATIC});
        this._rows = new St.BoxLayout({orientation: Clutter.Orientation.VERTICAL,
            style_class: 'xava-tray-rows', x_expand: true});
        this._scroll.set_child(this._rows);
        box.add_child(this._scroll);
        this.connect('notify::allocation', () => this._onAllocated());
        this.connect('destroy', () => {
            this._clearMenu();
            this.menu.destroy();
            for (const button of this._items.values())
                button.destroy();
            this._items.clear();
        });
        this._layout();
    }

    // Keep preferred width tiny so icon rows never stretch the Quick Settings menu.
    // Icons reflow to whatever width the grid actually allocates.
    vfunc_get_preferred_width(_forHeight) {
        return [ICON_BUTTON, ICON_BUTTON];
    }

    _onAllocated() {
        const width = this.allocation.get_width();
        if (width <= 1 || width === this._allocWidth)
            return;
        this._allocWidth = width;
        this._layout();
    }

    _columnCount() {
        const width = this._allocWidth;
        // Match qs-columns@xava.local (3×44px toggles) until we know allocated width.
        if (width < ICON_BUTTON)
            return 3;
        return Math.max(1, Math.floor((width + ICON_GAP) / (ICON_BUTTON + ICON_GAP)));
    }

    setMessage(message) {
        this._empty.text = message;
    }

    addIndicator(indicator) {
        const button = new St.Button({can_focus: true, reactive: true,
            style_class: 'xava-tray-icon',
            child: new IconActor(indicator, 24)});
        this._items.set(indicator, button);
        const sync = () => {
            button.visible = indicator.isReady && indicator.status !== SNIStatus.PASSIVE;
            button.accessible_name = indicator.accessibleName || indicator.id || 'Tray application';
            if (indicator.status === SNIStatus.NEEDS_ATTENTION)
                button.add_style_class_name('needs-attention');
            else
                button.remove_style_class_name('needs-attention');
            if (this._selected === indicator && !button.visible)
                this._clearMenu();
            this._layout();
        };
        for (const signal of ['ready', 'status', 'accessible-name', 'reset'])
            connectSmart(indicator, signal, button, sync);
        connectSmart(indicator, 'menu', button, () => {
            if (this._selected === indicator) {
                this._clearMenu();
                this._showMenu(indicator);
            }
        });
        connectSmart(indicator, 'destroy', button, () => {
            if (this._selected === indicator)
                this._clearMenu();
            this._items.delete(indicator);
            button.destroy();
            this._layout();
        });
        button.connect('clicked', () => this._showMenu(indicator));
        button.connect('button-press-event', (_actor, event) => {
            const [x, y] = event.get_coords();
            if (event.get_button() === Clutter.BUTTON_MIDDLE) {
                indicator.secondaryActivate(event.get_time(), x, y).catch(logError);
                return Clutter.EVENT_STOP;
            }
            if (event.get_button() === Clutter.BUTTON_SECONDARY) {
                this._showMenu(indicator);
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        });
        button.connect('scroll-event', (_actor, event) => {
            if (event.get_scroll_direction() !== Clutter.ScrollDirection.SMOOTH)
                return Clutter.EVENT_PROPAGATE;
            indicator.scroll(...event.get_scroll_delta());
            return Clutter.EVENT_STOP;
        });
        sync();
    }

    _layout() {
        // Reflow only active icons; passive items must not leave empty cells.
        for (const button of this._items.values())
            button.get_parent()?.remove_child(button);
        this._rows.destroy_all_children();
        const visible = [...this._items.values()].filter(button => button.visible);
        const cols = this._columnCount();
        visible.forEach((button, index) => {
            if (index % cols === 0)
                this._rows.add_child(new St.BoxLayout({style_class: 'xava-tray-row', x_align: Clutter.ActorAlign.START}));
            this._rows.get_last_child().add_child(button);
        });
        this._empty.visible = visible.length === 0;
        this._scroll.visible = visible.length > 0;
    }

    _clearMenu() {
        this.menu.close();
        this._client?.destroy();
        this._client = null;
        this._selected = null;
        this.menu.removeAll();
    }

    _showMenu(indicator) {
        if (this._selected === indicator && this.menu.isOpen) {
            this.menu.close();
            return;
        }
        this._clearMenu();
        this._selected = indicator;
        if (!indicator.menuPath) {
            const [x, y] = this.get_transformed_position();
            indicator.open(Math.round(x), Math.round(y), global.get_current_time()).catch(logError);
            Main.panel.statusArea.quickSettings.menu.close();
            return;
        }
        this.menu.setHeader('view-app-grid-symbolic', indicator.accessibleName || indicator.id);
        const loading = new PopupMenu.PopupMenuItem('Loading…', {reactive: false});
        this.menu.addMenuItem(loading);
        const client = new Client(indicator.busName, indicator.menuPath, indicator);
        this._client = client;
        const attach = () => {
            if (this._client !== client || !client.isReady)
                return;
            client.attachToMenu(this.menu);
            // The loading menu can open before the asynchronous client is ready.
            // Replay its current state so the pinned backend receives live updates.
            client._onMenuOpenStateChanged(this.menu, this.menu.isOpen);
        };
        client.connect('ready-changed', attach);
        attach();
        this.menu.open();
    }
});

import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Clutter from 'gi://Clutter';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as ModalDialog from 'resource:///org/gnome/shell/ui/modalDialog.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const ReminderDialog = GObject.registerClass(
class ReminderDialog extends ModalDialog.ModalDialog {
    _init(onSave) {
        super._init();
        this._onSave = onSave;
        this._minutes = 0;

        this._title = new St.Label({
            text: 'Kaç dakika sonra?',
            style_class: 'modal-dialog-headline',
        });
        this._hint = new St.Label({text: 'Hatırlatmanın ne zaman gösterileceğini yaz.'});
        this._entry = new St.Entry({
            hint_text: 'Dakika',
            can_focus: true,
            x_expand: true,
        });
        this._error = new St.Label({text: '', style: 'color: #ff7b7b; min-height: 18px;'});

        const content = new St.BoxLayout({vertical: true, style: 'spacing: 12px; min-width: 380px;'});
        content.add_child(this._title);
        content.add_child(this._hint);
        content.add_child(this._entry);
        content.add_child(this._error);
        this.contentLayout.add_child(content);

        this._entry.clutter_text.connect('activate', () => this._next());
        this._entry.clutter_text.connect('text-changed', () => this._error.text = '');
        this._minuteStep();
    }

    _minuteStep() {
        this._step = 1;
        this._title.text = 'Kaç dakika sonra?';
        this._hint.text = 'Hatırlatmanın ne zaman gösterileceğini yaz.';
        this._entry.hint_text = 'Dakika';
        this._entry.set_text('');
        this._buttons('İptal', () => this.close(), 'Devam');
        this._focus();
    }

    _messageStep() {
        this._step = 2;
        this._title.text = 'Neyi hatırlatayım?';
        this._hint.text = `${this._minutes} dakika sonra gösterilecek.`;
        this._entry.hint_text = 'Hatırlatma metni';
        this._entry.set_text('');
        this._buttons('Geri', () => this._minuteStep(), 'Hatırlat');
        this._focus();
    }

    _buttons(backLabel, backAction, nextLabel) {
        this.setButtons([
            {label: backLabel, action: backAction, key: Clutter.KEY_Escape},
            {label: nextLabel, action: () => this._next(), default: true},
        ]);
    }

    _focus() {
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this._entry.grab_key_focus();
            return GLib.SOURCE_REMOVE;
        });
    }

    _next() {
        if (this._step === 1) {
            const minutes = Number(this._entry.get_text().trim());
            if (!Number.isInteger(minutes) || minutes < 1 || minutes > 525600) {
                this._error.text = 'Geçerli bir dakika gir.';
                return;
            }
            this._minutes = minutes;
            this._messageStep();
            return;
        }

        const message = this._entry.get_text().trim();
        if (!message) {
            this._error.text = 'Hatırlatma metnini yaz.';
            return;
        }
        this._onSave(this._minutes, message);
        this.close();
    }
});

const ReminderIndicator = GObject.registerClass(
class ReminderIndicator extends PanelMenu.Button {
    _init() {
        super._init(0, 'Reminders');
        this.add_child(new St.Icon({icon_name: 'alarm-symbolic', style_class: 'system-status-icon'}));
        this.menu.addAction('Set reminder', () => this._openDialog());
        this._timers = new Set();
    }

    _openDialog() {
        this.menu.close();
        const dialog = new ReminderDialog((minutes, message) => {
            const id = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, minutes * 60, () => {
                this._timers.delete(id);
                Main.notify('Hatırlatma', message);
                return GLib.SOURCE_REMOVE;
            });
            this._timers.add(id);
            Main.notify('Hatırlatma ayarlandı', `${minutes} dakika sonra`);
        });
        dialog.connect('closed', () => dialog.destroy());
        dialog.open();
    }

    destroy() {
        for (const id of this._timers)
            GLib.source_remove(id);
        this._timers.clear();
        super.destroy();
    }
});

export default class RemindersExtension extends Extension {
    enable() {
        this._indicator = new ReminderIndicator();
        Main.panel.addToStatusArea(this.uuid, this._indicator, 1, 'right');
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}

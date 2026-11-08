// SPDX-License-Identifier: GPL-2.0-or-later
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Interfaces from './interfaces.js';
import {Logger} from './logger.js';
import {SettingsManager} from './settingsManager.js';
import {NameWatcher} from './util.js';
import {StatusNotifierWatcher, WATCHER_BUS_NAME} from './statusNotifierWatcher.js';
import {TraySection} from './traySection.js';

export default class QuickSettingsTray extends Extension {
    enable() {
        Logger.init(this);
        Interfaces.initialize(this);
        SettingsManager.initialize(this);
        this._tray = new TraySection();
        Main.panel.statusArea.quickSettings.menu.addItem(this._tray, 2);
        // Wait for the initial bus-name result before trying to own the watcher.
        this._watchDog = new NameWatcher(WATCHER_BUS_NAME);
        this._appearedId = this._watchDog.connect('appeared', () => {
            if (!this._watcher)
                this._tray.setMessage('Disable the other tray extension to show icons here.');
        });
        this._vanishedId = this._watchDog.connect('vanished', () => {
            if (!this._watcher) {
                this._tray.setMessage('No tray applications running');
                this._watcher = new StatusNotifierWatcher(this, this._watchDog);
            }
        });
    }

    disable() {
        if (this._watchDog) {
            this._watchDog.disconnect(this._appearedId);
            this._watchDog.disconnect(this._vanishedId);
            this._watchDog.destroy();
        }
        this._appearedId = 0;
        this._vanishedId = 0;
        this._watchDog = null;
        this._watcher?.destroy();
        this._watcher = null;
        this._tray?.destroy();
        this._tray = null;
        SettingsManager.destroy();
        Interfaces.destroy();
        // Keep the logger initialized while cancelled asynchronous work settles.
    }
}

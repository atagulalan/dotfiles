import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';

import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {QuickSettingsItem} from 'resource:///org/gnome/shell/ui/quickSettings.js';

import * as Sensors from './sensors.js';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import * as Values from './values.js';
import * as MenuItem from './menuItem.js';
import * as SensorCatalog from './helpers/catalog.js';

const ICON_BUTTON = 44;

let vitalsSection;

var VitalsSection = GObject.registerClass({
    GTypeName: 'VitalsSection',
}, class VitalsSection extends QuickSettingsItem {
    _init(extensionObject) {
        super._init({
            hasMenu: false,
            reactive: false,
            can_focus: false,
            style_class: 'xava-vitals',
            x_expand: true,
        });

        this._extensionObject = extensionObject;
        this._settings = extensionObject.getSettings();

        this._sensorIcons = SensorCatalog.sensorCatalog;

        // list with the prefixes for the according themes, the index of each
        // item must match the index on the combo box
        this._sensorsIconPathPrefix = ['/icons/original/', '/icons/gnome/'];

        this._sensorMenuItems = {};
        this._hotLabels = {};
        this._hotItems = {};
        this._summaryTiles = {};
        this._groups = {};
        this._widths = {};
        this._numGpus = 1;
        this._newGpuDetected = false;
        this._newGpuDetectedCount = 0;
        this._last_query = new Date().getTime();
        this._refreshTimeoutId = null;
        this._destroyed = false;

        this._sensors = new Sensors.Sensors(this._settings, this._sensorIcons, _);
        this._values = new Values.Values(this._settings, this._sensorIcons);

        // PopupMenuSection hosts the existing accordion via addMenuItem, inline in QS.
        this.menu = new PopupMenu.PopupMenuSection();

        const root = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            x_expand: true,
            style_class: 'xava-vitals-root',
        });
        this.set_child(root);

        // Pinned sensors as a compact 2-column grid
        this._summaryGrid = new St.Widget({
            style_class: 'xava-vitals-summary',
            x_expand: true,
            layout_manager: new Clutter.GridLayout({
                column_homogeneous: true,
                column_spacing: 8,
                row_spacing: 8,
            }),
        });
        root.add_child(this._summaryGrid);

        this._summaryHint = new St.Label({
            style_class: 'xava-vitals-hint',
            text: _('Click a sensor to pin it here'),
            x_expand: true,
        });
        root.add_child(this._summaryHint);

        // "All sensors" expander; the full accordion stays collapsed by default
        this._expanderArrow = new St.Icon({
            style_class: 'popup-menu-arrow',
            icon_name: 'pan-end-symbolic',
            y_align: Clutter.ActorAlign.CENTER,
        });
        const expanderBox = new St.BoxLayout({x_expand: true});
        expanderBox.add_child(new St.Label({
            text: _('All sensors'),
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        }));
        expanderBox.add_child(this._expanderArrow);
        this._expander = new St.Button({
            style_class: 'xava-vitals-expander',
            x_expand: true,
            can_focus: true,
            child: expanderBox,
        });
        this._expander.connect('clicked', () => this._setExpanded(!this._expanded));
        root.add_child(this._expander);

        this._scroll = new St.ScrollView({
            style_class: 'xava-vitals-scroll',
            x_expand: true,
            hscrollbar_policy: St.PolicyType.NEVER,
            vscrollbar_policy: St.PolicyType.AUTOMATIC,
        });
        this._scroll.set_child(this.menu.actor);
        root.add_child(this._scroll);
        this._setExpanded(false);

        this._connectSettingsSignals();
        this._initializeMenu();
        this._rebuildSummary();
        this._querySensors();
        this._initializeTimer();

        this._qsMenu = Main.panel.statusArea.quickSettings.menu;
        this._qsOpenId = this._qsMenu.connect('open-state-changed', (_menu, isOpen) => {
            if (isOpen) {
                this._initializeTimer();
                this._querySensors();
            } else {
                this._setExpanded(false);
            }
        });

        this.connect('destroy', () => this._onDestroy());
    }

    // Keep preferred width tiny so the accordion never stretches Quick Settings.
    vfunc_get_preferred_width(_forHeight) {
        return [ICON_BUTTON, ICON_BUTTON];
    }

    _closeQuickSettings() {
        Main.panel.statusArea.quickSettings.menu.close();
    }

    _setExpanded(expanded) {
        this._expanded = expanded;
        this._scroll.visible = expanded;
        this._expanderArrow.icon_name = expanded ? 'pan-down-symbolic' : 'pan-end-symbolic';
        if (expanded)
            this._expander.add_style_pseudo_class('checked');
        else
            this._expander.remove_style_pseudo_class('checked');
    }

    _pinnedKeys() {
        return this._settings.get_strv('hot-sensors').filter(k => k !== '_default_icon_');
    }

    _rebuildSummary() {
        this._summaryGrid.destroy_all_children();
        this._summaryTiles = {};

        const keys = this._pinnedKeys();
        const layout = this._summaryGrid.layout_manager;
        keys.forEach((key, i) => {
            const row = this._sensorMenuItems[key];
            const tile = new St.BoxLayout({
                style_class: 'xava-vitals-tile',
                x_expand: true,
            });
            const icon = new St.Icon({
                style_class: 'xava-vitals-tile-icon',
                gicon: row?.gicon ?? null,
                y_align: Clutter.ActorAlign.CENTER,
            });
            const value = new St.Label({
                style_class: 'xava-vitals-tile-value',
                text: row?.value ?? '\u2026',
                x_expand: true,
                y_align: Clutter.ActorAlign.CENTER,
            });
            if (row)
                value.style = row.valueStyle;
            tile.add_child(icon);
            tile.add_child(value);
            layout.attach(tile, i % 2, Math.floor(i / 2), 1, 1);
            this._summaryTiles[key] = {icon, value};
        });

        const empty = keys.length === 0;
        this._summaryGrid.visible = !empty;
        this._summaryHint.visible = empty;
    }

    _updateSummaryTile(key, value, style, gicon) {
        const tile = this._summaryTiles[key];
        if (!tile)
            return;
        if (value !== undefined) {
            tile.value.text = value;
            tile.value.style = style || null;
        }
        if (gicon)
            tile.icon.gicon = gicon;
    }

    _connectSettingsSignals() {
        this._settings.connectObject(
            'changed::update-time', this._initializeTimer.bind(this),
            this);

        let settings = [ 'use-higher-precision', 'alphabetize', 'hide-zeros',
                         'fixed-widths', 'hide-icons', 'unit', 'icon-style',
                         'memory-measurement', 'include-public-ip', 'network-public-ip-interval',
                         'network-public-ip-show-flag', 'network-public-ip-provider', 'network-speed-format', 'network-speed-unit', 'storage-measurement',
                         'include-static-info', 'include-processor-cores', 'include-static-gpu-info' ];

        for (let setting of settings)
            this._settings.connectObject('changed::' + setting, this._redrawMenu.bind(this), this);

        this._settings.connectObject('changed::hot-sensors', this._rebuildSummary.bind(this), this);

        for (let setting of SensorCatalog.colorSettingsKeys())
            this._settings.connectObject('changed::' + setting, this._thresholdColorsChanged.bind(this), this);

        for (let sensor in this._sensorIcons)
            this._settings.connectObject('changed::show-' + sensor, this._showHideSensorsChanged.bind(this), this);
    }

    _thresholdColorsChanged() {
        this._values.resetHistory(this._numGpus);
        this._querySensors();
    }

    _initializeMenu() {
        // display sensor categories
        for (let sensor in this._sensorIcons) {
            // groups associated sensors under accordion menu
            if (sensor in this._groups) continue;

            //handle gpus separately.
            if (sensor === 'gpu') continue;

            this._initializeMenuGroup(sensor, sensor);
        }

        for (let i = 1; i <= this._numGpus; i++)
            this._initializeMenuGroup('gpu#' + i, 'gpu', (this._numGpus > 1 ? ' ' + i : ''));
    }

    _initializeMenuGroup(groupName, optionName, menuSuffix = '', position = -1) {
        this._groups[groupName] = new PopupMenu.PopupSubMenuMenuItem(_(this._ucFirst(groupName) + menuSuffix), true);
        this._groups[groupName].icon.gicon = Gio.icon_new_for_string(this._sensorIconPath(groupName));
        // Each PopupSubMenu wraps its rows in its own St.ScrollView, which eats
        // wheel events even when it can't scroll; let them reach our outer scroll.
        this._groups[groupName].menu.actor.enable_mouse_scrolling = false;

        // hide menu items that user has requested to not include
        if (!this._settings.get_boolean('show-' + optionName))
            this._groups[groupName].actor.hide();

        if (!this._groups[groupName]._statusLabel) {
            this._groups[groupName]._statusLabel = this._defaultLabel();
            this._groups[groupName].actor.insert_child_at_index(this._groups[groupName]._statusLabel, 4);
            this._groups[groupName]._statusLabel.text = _('No Data');
        }

        if (position == -1) this.menu.addMenuItem(this._groups[groupName]);
        else this.menu.addMenuItem(this._groups[groupName], position);
    }

    _removeMissingHotSensors(hotSensors) {
        for (let i = hotSensors.length - 1; i >= 0; i--) {
            let sensor = hotSensors[i];

            // make sure default icon (if any) stays visible
            if (sensor == '_default_icon_') continue;

            // removes sensors that are no longer available
            if (!this._sensorMenuItems[sensor]) {
                hotSensors.splice(i, 1);
            }
        }

        return hotSensors;
    }

    _saveHotSensors(hotSensors) {
        // removes any sensors that may not currently be available
        hotSensors = this._removeMissingHotSensors(hotSensors);

        this._settings.set_strv('hot-sensors', hotSensors.filter(
            function(item, pos) {
                return hotSensors.indexOf(item) == pos;
            }
        ));
    }

    _initializeTimer() {
        this._destroyTimer();

        // used to query sensors and update display
        let update_time = this._settings.get_int('update-time');
        this._refreshTimeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            update_time,
            (_self) => {
                this._querySensors();
                return GLib.SOURCE_CONTINUE;
            }
        );
    }

    _showHideSensorsChanged(self, sensor) {
        const sensorName = sensor.substr(5);
        if (sensorName === 'gpu') {
            for (let i = 1; i <= this._numGpus; i++)
                this._groups[sensorName + '#' + i].visible = this._settings.get_boolean(sensor);
        } else
            this._groups[sensorName].visible = this._settings.get_boolean(sensor);

        // prefs may have removed this group's sensors from hot-sensors; rebuild menu
        this._redrawMenu();
    }

    _redrawHotSensors() {
        // Panel hot-sensors are gone; keep pin ornaments in sync via settings only.
        this._values.resetHistory(this._numGpus);
        this._querySensors();
    }

    _redrawMenu() {
        for (let key in this._sensorMenuItems) {
            if (key.includes('-group')) continue;
            let item = this._sensorMenuItems[key];
            delete this._sensorMenuItems[key];
            item.destroy();
        }

        // group headers persist across row rebuilds; refresh pack (original vs gnome)
        for (let groupName in this._groups)
            this._groups[groupName].icon.gicon = Gio.icon_new_for_string(this._sensorIconPath(groupName));

        this._sensors.resetHistory(false);
        this._redrawHotSensors();
    }

    _destroyTimer() {
        if (this._refreshTimeoutId != null) {
            GLib.Source.remove(this._refreshTimeoutId);
            this._refreshTimeoutId = null;
        }
    }

    _updateDisplay(label, value, type, key, style) {
        // have we added this sensor before?
        let item = this._sensorMenuItems[key];
        if (item) {
            // update sensor value in the group
            item.value = value;
            item.valueStyle = style;
            this._updateSummaryTile(key, value, style);
        } else if (type.includes('-group')) {
            // update text next to group header
            let group = type.split('-')[0];
            let statusLabel = this._groups[group]?._statusLabel;
            if (statusLabel) {
                statusLabel.text = value;
                statusLabel.style = style;
                this._sensorMenuItems[type] = this._groups[group];
            }
        } else {
            // add item to group for the first time
            let sensor = { 'label': label, 'value': value, 'type': type }
            this._appendMenuItem(sensor, key);
            this._sensorMenuItems[key].valueStyle = style;
            this._updateSummaryTile(key, value, style, this._sensorMenuItems[key].gicon);
        }
    }

    _appendMenuItem(sensor, key) {
        let split = sensor.type.split('-');
        let type = split[0];
        let icon = (split.length == 2)?'icon-' + split[1]:'icon';
        let gicon = Gio.icon_new_for_string(this._sensorIconPath(type, icon, key));

        let hotSensors = this._settings.get_strv('hot-sensors');
        let item = new MenuItem.MenuItem(gicon, key, sensor.label, sensor.value, hotSensors.includes(key));
        item.connect('toggle', (self) => {
            let pins = this._settings.get_strv('hot-sensors');

            if (self.checked) {
                pins.push(self.key);
            } else {
                pins.splice(pins.indexOf(self.key), 1);
            }

            if (pins.length <= 0) {
                pins.push('_default_icon_');
            } else {
                let defIconPos = pins.indexOf('_default_icon_');
                if (defIconPos >= 0)
                    pins.splice(defIconPos, 1);
            }

            this._saveHotSensors(pins);
        });

        this._sensorMenuItems[key] = item;
        let i = Object.keys(this._sensorMenuItems[key]).length;

        // alphabetize the sensors for these categories
        if (this._settings.get_boolean('alphabetize')) {
            let menuItems = this._groups[type].menu._getMenuItems();
            for (i = 0; i < menuItems.length; i++)
                // use natural sort order for system load, etc
                if (menuItems[i].label.localeCompare(item.label, undefined, { numeric: true, sensitivity: 'base' }) > 0)
                    break;
        }

        this._groups[type].menu.addMenuItem(item, i);
    }

    _defaultLabel() {
        return new St.Label({
               y_expand: true,
                y_align: Clutter.ActorAlign.CENTER
        });
    }

    _sensorIconPath(sensor, icon = 'icon', key = '') {
        let sensorKey = sensor;

        // If the sensor is a numbered gpu, use the gpu icon. Otherwise use whatever icon associated with the sensor name.
        if (sensor.startsWith('gpu')) sensorKey = 'gpu';

        // allows country flags to show
        const icons = this._sensorIcons[sensorKey];
        if (sensorKey === 'network' && icon.startsWith('icon-') && !(icons && icons[icon])) {
            let cc = icon.slice('icon-'.length);
            if (/^[a-z]{2}$/.test(cc))
                return this._extensionObject.path + '/icons/flags/1x1/' + cc + '.svg';
        }

        const iconPathPrefixIndex = this._settings.get_int('icon-style');
        if (sensorKey === 'memory' && iconPathPrefixIndex === 1 && key.startsWith('_memory_swap_'))
            icon = 'icon-swap';
        return this._extensionObject.path + this._sensorsIconPathPrefix[iconPathPrefixIndex] + icons[icon];
    }

    _ucFirst(string) {
        if (string.startsWith('gpu')) return 'Graphics';
        return string.charAt(0).toUpperCase() + string.slice(1);
    }

    _querySensors() {
        // figure out last run time
        let now = new Date().getTime();
        let dwell = (now - this._last_query) / 1000;
        this._last_query = now;

        // Always query the full set — the accordion is the only UI surface now.
        let wantedKeys = null;

        this._sensors.query((label, value, type, format) => {
            // async reads can resolve after disable(); the widgets are gone by then
            if (this._destroyed) return;

            let typeKey = type.replace('-group', '');
            if (/^network-(?!rx$|tx$)/.test(typeKey)) typeKey = 'network';
            let key = '_' + typeKey + '_' + label.replaceAll(' ', '_').toLowerCase() + '_';

            // issue #557 - interface is gone, drop it rather than show its last reading
            if (value == 'destroy') {
                this._values.removeNetworkSensor(key, label, type.replace('network-', ''));
                if (key in this._sensorMenuItems) {
                    this._sensorMenuItems[key].destroy();
                    delete this._sensorMenuItems[key];
                }
                return;
            }

            // if a sensor is disabled, gray it out
            if (key in this._sensorMenuItems) {
                this._sensorMenuItems[key].setSensitive((value!='disabled'));

                // don't continue below, last known value is shown
                if (value == 'disabled') return;
            } else if (value == 'disabled' && type.includes('-group')) {
                // group headers are not menu rows; formatting 'disabled' yields NaN
                return;
            }

            // add/initialize any gpu groups that we haven't added yet
            if (typeKey.startsWith('gpu') && typeKey !== 'gpu#1') {
                const split = typeKey.split('#');
                if (split.length == 2 && this._numGpus < parseInt(split[1])) {
                    // occasionally two lines from nvidia-smi will be read at once
                    // so we only actually update the number of gpus if we have recieved multiple lines at least 3 times in a row
                    // i.e. we make sure that mutiple queries have detected a new gpu back-to-back
                    if (this._newGpuDetectedCount < 2) {
                        this._newGpuDetected = true;
                        return;
                    }

                    this._numGpus = parseInt(split[1]);
                    this._newGpuDetectedCount = 0;
                    this._newGpuDetected = false;
                    // change label for gpu 1 from "Graphics" to "Graphics 1" since we have multiple gpus now
                    this._groups['gpu#1'].label.text = this._ucFirst('gpu#1') + ' 1';
                    for (let i = 2; i <= this._numGpus; i++)
                        if (!('gpu#' + i in this._groups))
                            this._initializeMenuGroup('gpu#' + i, 'gpu', ' ' + i, Object.keys(this._groups).length);
                }
            }

            let items = this._values.returnIfDifferent(dwell, label, value, type, format, key);
            for (let item of items) {
                if (item.type.startsWith('network-') && item.type.length == 10 && item.type != 'network-rx' && item.type != 'network-tx') {
                    // Geo / flags: stable key (no country in key); type stays network-<cc> for icon-us etc.
                    const stem = item.type.slice('network-'.length);
                    let flagGIcon = Gio.icon_new_for_string(this._sensorIconPath('network', 'icon-' + stem));
                    // change icon in dropdown
                    let menuRow = this._sensorMenuItems[item.key];
                    if (menuRow) menuRow.gicon = flagGIcon;
                    this._updateSummaryTile(item.key, undefined, null, flagGIcon);
                }

                this._updateDisplay(_(item.label), item.value, item.type, item.key, item.style);
            }
        }, dwell, wantedKeys);

        //if a new gpu has been detected during the last query, then increment the amount of times we've detected a new gpu
        if (this._newGpuDetected) this._newGpuDetectedCount++;
        else this._newGpuDetectedCount = 0;
        this._newGpuDetected = false;
    }

    _onDestroy() {
        if (this._destroyed)
            return;
        this._destroyed = true;
        this._destroyTimer();
        this._sensors.destroy();

        this._settings.disconnectObject(this);

        if (this._qsMenu && this._qsOpenId) {
            this._qsMenu.disconnect(this._qsOpenId);
            this._qsOpenId = 0;
            this._qsMenu = null;
        }

        this._hotLabels = {};
        this._hotItems = {};
        this._summaryTiles = {};
        this._sensorMenuItems = {};

        this.menu?.destroy();
        this.menu = null;
    }
});

export default class VitalsExtension extends Extension {
    enable() {
        vitalsSection = new VitalsSection(this);
        Main.panel.statusArea.quickSettings.menu.addItem(vitalsSection, 2);
    }

    disable() {
        vitalsSection?.destroy();
        vitalsSection = null;
    }
}

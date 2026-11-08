import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const COLUMNS = 3;

let _oldColumns = 2;
let _oldSpans = null;
let _grid = null;
let _lm = null;
let _childAddedId = 0;
let _timeoutId = 0;
let _hiddenPowerItems = null;

function _quickSettingsPanels() {
    const panels = [];
    const mainQs = Main.panel.statusArea?.quickSettings;
    if (mainQs)
        panels.push(mainQs);
    const dtpPanels = global.dashToPanel?.panels;
    if (dtpPanels) {
        for (const p of dtpPanels) {
            const qs = p.statusArea?.quickSettings;
            if (qs && !panels.includes(qs))
                panels.push(qs);
        }
    }
    return panels;
}

function _hidePowerMode() {
    if (!_hiddenPowerItems)
        _hiddenPowerItems = new Set();
    for (const qs of _quickSettingsPanels()) {
        const indicator = qs._powerProfiles;
        if (!indicator)
            continue;
        for (const item of indicator.quickSettingsItems ?? []) {
            if (!_hiddenPowerItems.has(item)) {
                item._qsColumnsWasVisible = item.visible;
                _hiddenPowerItems.add(item);
            }
            item.visible = false;
        }
        indicator.visible = false;
    }
}

function _restorePowerMode() {
    if (_hiddenPowerItems) {
        for (const item of _hiddenPowerItems) {
            item.visible = item._qsColumnsWasVisible ?? true;
            delete item._qsColumnsWasVisible;
        }
        _hiddenPowerItems = null;
    }
    for (const qs of _quickSettingsPanels()) {
        const indicator = qs._powerProfiles;
        if (indicator)
            indicator.visible = true;
    }
}

function _applySpans(columns) {
    if (!_grid || !_lm)
        return;
    for (const child of _grid.get_children()) {
        try {
            const meta = _lm.get_child_meta(_grid, child);
            if (!meta)
                continue;
            if (!_oldSpans.has(child))
                _oldSpans.set(child, meta.columnSpan);
            if (columns > 2 && meta.columnSpan >= 2)
                meta.columnSpan = columns;
            else if (columns <= 2)
                meta.columnSpan = _oldSpans.get(child) ?? 1;
        } catch (_) {}
    }
    _lm.layout_changed();
}

export function setQuickSettingsColumns(columns = COLUMNS) {
    const qs = Main.panel.statusArea.quickSettings;
    _grid = qs?.menu?._grid ?? null;
    _lm = _grid?.layout_manager ?? null;
    if (!_lm)
        return;

    if (_oldSpans === null) {
        _oldColumns = _lm.nColumns;
        _oldSpans = new Map();
    }

    _lm.nColumns = columns;
    _applySpans(columns);
    _hidePowerMode();

    if (_childAddedId)
        _grid.disconnect(_childAddedId);
    _childAddedId = _grid.connect('child-added', () => {
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            _applySpans(columns);
            _hidePowerMode();
            return GLib.SOURCE_REMOVE;
        });
    });

    // catch async indicator setup
    if (_timeoutId)
        GLib.source_remove(_timeoutId);
    _timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {
        _applySpans(columns);
        _hidePowerMode();
        _timeoutId = 0;
        return GLib.SOURCE_REMOVE;
    });
}

export function restoreQuickSettingsColumns() {
    if (_timeoutId) {
        GLib.source_remove(_timeoutId);
        _timeoutId = 0;
    }
    if (_grid && _childAddedId) {
        _grid.disconnect(_childAddedId);
        _childAddedId = 0;
    }
    if (_lm && _oldSpans !== null) {
        _lm.nColumns = _oldColumns;
        _applySpans(_oldColumns);
    }
    _restorePowerMode();
    _oldSpans = null;
    _grid = null;
    _lm = null;
}

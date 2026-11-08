import GLib from 'gi://GLib';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Tweak these (0–255). ~140 ≈ #8a8a88 vs #dcdcdc lightness.
const INACTIVE_OPACITY = 140;
const ACTIVE_OPACITY = 255;
const HOVER_OPACITY = 220;
const REFRESH_MS = 400;

function iconActor(icon) {
    return icon._dtpIconContainer || icon._iconContainer || icon.icon || icon;
}

function isAppIcon(icon) {
    return icon && icon.app && typeof icon._checkIfFocusedApp === 'function';
}

function forEachAppIcon(cb) {
    const panels = global.dashToPanel?.panels;
    if (!panels)
        return;

    for (const panel of panels) {
        const icons = panel.taskbar?._getAppIcons?.() ?? [];
        for (const icon of icons) {
            if (isAppIcon(icon))
                cb(icon);
        }
    }
}

function desiredOpacity(icon) {
    if (icon._checkIfFocusedApp())
        return ACTIVE_OPACITY;
    if (icon.hover || icon.pseudo_class?.includes?.('hover'))
        return HOVER_OPACITY;
    // St.Widget hover
    try {
        if (icon.get_hover?.() || icon.hover)
            return HOVER_OPACITY;
    } catch (_) {}
    return INACTIVE_OPACITY;
}

function applyOpacity() {
    if (!global.dashToPanel?.panels)
        return;

    forEachAppIcon(icon => {
        const actor = iconActor(icon);
        if (!actor)
            return;
        const next = desiredOpacity(icon);
        if (actor.opacity !== next)
            actor.opacity = next;
    });
}

function restoreOpacity() {
    forEachAppIcon(icon => {
        const actor = iconActor(icon);
        if (actor)
            actor.opacity = ACTIVE_OPACITY;
    });
}

export default class DtpInactiveOpacityExtension extends Extension {
    enable() {
        this._tracker = Shell.WindowTracker.get_default();
        this._signals = [];
        this._timeoutId = 0;
        this._dtpSignalId = 0;

        this._signals.push([
            this._tracker,
            this._tracker.connect('notify::focus-app', () => applyOpacity()),
        ]);
        this._signals.push([
            global.display,
            global.display.connect('notify::focus-window', () => applyOpacity()),
        ]);

        this._hookDashToPanel();

        this._timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, REFRESH_MS, () => {
            if (!this._timeoutId)
                return GLib.SOURCE_REMOVE;
            this._hookDashToPanel();
            applyOpacity();
            return GLib.SOURCE_CONTINUE;
        });

        applyOpacity();
    }

    _hookDashToPanel() {
        if (!global.dashToPanel || this._dtpSignalId)
            return;

        this._dtpSignalId = global.dashToPanel.connect('panels-created', () => {
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                applyOpacity();
                return GLib.SOURCE_REMOVE;
            });
        });
        applyOpacity();
    }

    disable() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = 0;
        }

        if (this._dtpSignalId && global.dashToPanel) {
            global.dashToPanel.disconnect(this._dtpSignalId);
            this._dtpSignalId = 0;
        }

        for (const [obj, id] of this._signals ?? []) {
            try {
                obj.disconnect(id);
            } catch (_) {}
        }
        this._signals = [];

        restoreOpacity();
        this._tracker = null;
    }
}

// Square-ended BarLevel / Slider tracks.
// GNOME Shell draws the bar with hardcoded cairo arcs (ui/barLevel.js
// vfunc_repaint), so CSS border-radius has no effect. This replaces the
// repaint with a flat-ended version; the slider handle stays round.
import Clutter from 'gi://Clutter';
import * as BarLevel from 'resource:///org/gnome/shell/ui/barLevel.js';
import {InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';

function squareRepaint() {
    const cr = this.get_context();
    const themeNode = this.get_theme_node();
    const [width, height] = this.get_surface_size();
    const rtl = this.get_text_direction() === Clutter.TextDirection.RTL;
    // Same offset as upstream so the fill ends under the slider handle
    const inset = Math.min(width, this._barLevelHeight) / 2;
    const fgColor = themeNode.get_foreground_color();
    const top = (height - this._barLevelHeight) / 2;
    const barH = this._barLevelHeight;

    let endX = 0;
    if (this._maxValue > 0) {
        let progress = this._value / this._maxValue;
        if (rtl)
            progress = 1 - progress;
        endX = inset + (width - 2 * inset) * progress;
    }

    let overdriveRatio = this._overdriveStart / this._maxValue;
    if (rtl)
        overdriveRatio = 1 - overdriveRatio;
    const overdriveSeparatorX = inset + (width - 2 * inset) * overdriveRatio;
    const overdriveActive = this._overdriveStart !== this._maxValue;
    const sepW = overdriveActive ? this._overdriveSeparatorWidth : 0;

    const fillSpan = (a, b, color) => {
        const x0 = Math.min(a, b);
        const w = Math.abs(b - a);
        if (w <= 0)
            return;
        cr.rectangle(x0, top, w, barH);
        cr.setSourceColor(color);
        cr.fill();
    };

    /* background bar (full width; progress paints over it) */
    fillSpan(0, width, this._barLevelColor);

    if (this._value > 0) {
        /* normal progress */
        if (!rtl)
            fillSpan(0, Math.min(endX, overdriveSeparatorX - sepW / 2), this._barLevelActiveColor);
        else
            fillSpan(Math.max(endX, overdriveSeparatorX + sepW / 2), width, this._barLevelActiveColor);

        /* overdrive progress */
        if (this._value > this._overdriveStart) {
            const x = !rtl
                ? Math.min(endX, overdriveSeparatorX) + sepW / 2
                : Math.max(endX, overdriveSeparatorX) - sepW / 2;
            fillSpan(x, endX, this._barLevelOverdriveColor);
        }
    }

    /* overdrive separator */
    if (overdriveActive) {
        cr.rectangle(overdriveSeparatorX - sepW / 2, top, sepW, barH);
        cr.setSourceColor(this._value <= this._overdriveStart ? fgColor : this._barLevelColor);
        cr.fill();
    }

    cr.$dispose();
}

let injectionManager = null;
let savedJsRepaint = null;

export function enableSquareBars() {
    const proto = BarLevel.BarLevel.prototype;
    injectionManager = new InjectionManager();
    // GI vfunc: plain BarLevel instances (e.g. OSD level bar)
    injectionManager.overrideMethod(proto, 'vfunc_repaint', () => squareRepaint);
    // JS property: Slider calls super.vfunc_repaint() through the prototype
    savedJsRepaint = proto.vfunc_repaint;
    proto.vfunc_repaint = squareRepaint;
}

export function disableSquareBars() {
    const proto = BarLevel.BarLevel.prototype;
    if (savedJsRepaint) {
        proto.vfunc_repaint = savedJsRepaint;
        savedJsRepaint = null;
    }
    injectionManager?.clear();
    injectionManager = null;
}

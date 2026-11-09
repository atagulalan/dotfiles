var _a;
import Adw from "gi://Adw";
import GObject from "gi://GObject";
import { Window } from "./window.js";
export class APPlaybackRateButton extends Adw.Bin {
    constructor(params) {
        super(params);
    }
    initialize_player() {
        const window = this.get_root();
        if (!window || !(window instanceof Window))
            return;
        window.stream.bind_property("rate", this._adjustment, "value", GObject.BindingFlags.SYNC_CREATE);
        // @ts-expect-error GObject.BindingTransformFunc return arguments are not correctly typed
        window.stream.bind_property_full("rate", this._label, "label", GObject.BindingFlags.SYNC_CREATE, (_binding, from) => {
            const rounded = from.toFixed(1);
            return [true, `× ${rounded}`];
        }, null);
    }
    scale_change_value_cb(_scale, _scroll, value) {
        const window = this.get_root();
        const stream = window === null || window === void 0 ? void 0 : window.stream;
        if (!stream)
            return;
        stream.rate = value;
    }
    adjust_value(increase) {
        const window = this.get_root();
        const stream = window === null || window === void 0 ? void 0 : window.stream;
        if (!stream)
            return;
        stream.rate = increase
            ? this._adjustment.value + this._adjustment.step_increment
            : this._adjustment.value - this._adjustment.step_increment;
    }
    vfunc_root() {
        super.vfunc_root();
        const window = this.get_root();
        let listener = window.connect("notify::stream", () => {
            this.initialize_player();
            if (listener)
                window.disconnect(listener);
            listener = null;
        });
    }
}
_a = APPlaybackRateButton;
(() => {
    GObject.registerClass({
        GTypeName: "APPlaybackRateButton",
        Template: "resource:///org/gnome/Decibels/playback-rate-button.ui",
        InternalChildren: ["adjustment", "label"],
        Properties: {},
    }, _a);
})();

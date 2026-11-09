var _a;
import Adw from "gi://Adw";
import GObject from "gi://GObject";
export class APHeaderBar extends Adw.Bin {
    has_title_widget() {
        const title_widget = this._header_bar.title_widget;
        if (title_widget && title_widget instanceof Adw.WindowTitle) {
            return true;
        }
        return false;
    }
    get title() {
        return this._title;
    }
    set title(title) {
        this._title = title;
        this.notify("title");
        this.render_title();
    }
    get subtitle() {
        return this._subtitle;
    }
    set subtitle(subtitle) {
        this._subtitle = subtitle;
        this.notify("subtitle");
        this.render_title();
    }
    render_title() {
        var _b, _c;
        if (!this._title) {
            this._header_bar.set_title_widget(null);
        }
        let window_title;
        if (this.has_title_widget()) {
            window_title = this._header_bar.title_widget;
        }
        else {
            window_title = new Adw.WindowTitle();
            this._header_bar.title_widget = window_title;
        }
        window_title.set_title((_b = this.title) !== null && _b !== void 0 ? _b : "");
        window_title.set_subtitle((_c = this.subtitle) !== null && _c !== void 0 ? _c : "");
    }
    constructor(params) {
        super(params);
        this._title = null;
        this._subtitle = null;
    }
}
_a = APHeaderBar;
(() => {
    GObject.registerClass({
        GTypeName: "APHeaderBar",
        Template: "resource:///org/gnome/Decibels/header.ui",
        InternalChildren: ["header_bar"],
        Properties: {
            title: GObject.param_spec_string("title", "Title", "The title of the header bar", null, GObject.ParamFlags.READWRITE),
            subtitle: GObject.param_spec_string("subtitle", "Subtitle", "The subtitle of the header bar", null, GObject.ParamFlags.READWRITE),
        },
    }, _a);
})();

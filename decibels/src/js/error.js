var _a;
import Adw from "gi://Adw";
import GLib from "gi://GLib";
import GObject from "gi://GObject";
export class APErrorState extends Adw.Bin {
    constructor(params) {
        super(params);
    }
    show_message(message) {
        this._statusPage.set_description(message);
    }
    show_error(title, error) {
        this._statusPage.title = title;
        if (error instanceof Error) {
            this.show_message(error.message);
        }
        else if (error instanceof GLib.Error) {
            this.show_message(error.message);
        }
        else {
            console.error("error: ", error);
            this.show_message(error ? error.toString() : _("An unknown error happened"));
        }
    }
}
_a = APErrorState;
(() => {
    GObject.registerClass({
        GTypeName: "APErrorState",
        Template: "resource:///org/gnome/Decibels/error.ui",
        InternalChildren: ["statusPage"],
        Children: ["headerbar"],
    }, _a);
})();

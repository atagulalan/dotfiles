var _a;
import Adw from "gi://Adw";
import GObject from "gi://GObject";
export class APEmptyState extends Adw.Bin {
    constructor(params) {
        super(params);
        this._statusPage.icon_name = `${pkg.name}-symbolic`;
    }
}
_a = APEmptyState;
(() => {
    GObject.registerClass({
        GTypeName: "APEmptyState",
        Template: "resource:///org/gnome/Decibels/empty.ui",
        InternalChildren: ["statusPage"],
    }, _a);
})();

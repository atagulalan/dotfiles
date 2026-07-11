/**
 * @file Contains the implementation of the main preferences page.
 * There isn't much logic in this file.
 */
import Adw from 'gi://Adw';
import Gdk from 'gi://Gdk';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import { gettext as _ } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';
import { bindPref, getPref, setPref } from '../../utils/settings.js';
import { EditShadowPage } from './edit_shadow.js';
import { ResetPage } from './reset.js';
export const GeneralPage = GObject.registerClass({
    Template: GLib.uri_resolve_relative(import.meta.url, 'general.ui', GLib.UriFlags.NONE),
    GTypeName: 'PrefsGeneral',
    // Those variables are declared inside of the `general.ui` file and
    // passed into the JS module prefixed with an underscore.
    // (skipLibadwaita -> _skipLibadwaita)
    InternalChildren: [
        'skipLibadwaita',
        'skipLibhandy',
        'separateBorderWidths',
        'borderWidthRow',
        'borderWidth',
        'outerBorderWidthRow',
        'secondaryBorderWidth',
        'borderColor',
        'useFocusedBorderColor',
        'focusedBorderColorRow',
        'focusedBorderColor',
        'cornerRadius',
        'cornerSmoothing',
        'keepShadowForMaximizedFullscreen',
        'keepForMaximized',
        'keepForFullscreen',
        'paddings',
        'tweakKitty',
        'enableDebugLogs',
    ],
}, class extends Adw.PreferencesPage {
    #settings = getPref('global-rounded-corner-settings');
    // Bind all buttons to respective prefs.
    constructor() {
        super();
        bindPref('skip-libadwaita-app', this._skipLibadwaita, 'active', Gio.SettingsBindFlags.DEFAULT);
        bindPref('skip-libhandy-app', this._skipLibhandy, 'active', Gio.SettingsBindFlags.DEFAULT);
        bindPref('separate-border-widths', this._separateBorderWidths, 'active', Gio.SettingsBindFlags.DEFAULT);
        this._separateBorderWidths.connect('notify::active', (swtch) => {
            const active = swtch.get_active();
            if (active) {
                this.#onSeparateBorderWidthsEnabled();
                this.#updateBorderWidthUi(true);
            }
            else {
                // Expand the adjustment range before writing a negative
                // border-width, otherwise the GSettings bind clamps it to 0.
                this.#updateBorderWidthUi(false);
                this.#onSeparateBorderWidthsDisabled();
            }
        });
        bindPref('border-width', this._borderWidth, 'value', Gio.SettingsBindFlags.DEFAULT);
        bindPref('secondary-border-width', this._secondaryBorderWidth, 'value', Gio.SettingsBindFlags.DEFAULT);
        this.#updateBorderWidthUi(this._separateBorderWidths.get_active());
        const color = new Gdk.RGBA();
        [color.red, color.green, color.blue, color.alpha] =
            this.#settings.borderColor;
        this._borderColor.set_rgba(color);
        this._borderColor.connect('notify::rgba', (button) => {
            const color = button.get_rgba();
            this.#settings.borderColor = [
                color.red,
                color.green,
                color.blue,
                color.alpha,
            ];
            this.#updateGlobalConfig();
        });
        bindPref('use-focused-border-color', this._useFocusedBorderColor, 'active', Gio.SettingsBindFlags.DEFAULT);
        const focusedColor = new Gdk.RGBA();
        [focusedColor.red, focusedColor.green, focusedColor.blue, focusedColor.alpha] =
            getPref('focused-border-color');
        this._focusedBorderColor.set_rgba(focusedColor);
        this._focusedBorderColor.connect('notify::rgba', (button) => {
            const color = button.get_rgba();
            setPref('focused-border-color', [
                color.red,
                color.green,
                color.blue,
                color.alpha,
            ]);
        });
        this.#updateFocusedBorderColorUi(this._useFocusedBorderColor.get_active());
        this._useFocusedBorderColor.connect('notify::active', (swtch) => {
            this.#updateFocusedBorderColorUi(swtch.get_active());
        });
        this._cornerRadius.set_value(this.#settings.borderRadius);
        this._cornerRadius.connect('value-changed', (adj) => {
            this.#settings.borderRadius = adj.get_value();
            this.#updateGlobalConfig();
        });
        this._cornerSmoothing.set_value(this.#settings.smoothing);
        this._cornerSmoothing.connect('value-changed', (adj) => {
            this.#settings.smoothing = adj.get_value();
            this.#updateGlobalConfig();
        });
        bindPref('keep-shadow-for-maximized-fullscreen', this._keepShadowForMaximizedFullscreen, 'active', Gio.SettingsBindFlags.DEFAULT);
        this._keepForMaximized.set_active(this.#settings.keepRoundedCorners.maximized);
        this._keepForMaximized.connect('notify::active', (swtch) => {
            this.#settings.keepRoundedCorners.maximized =
                swtch.get_active();
            this.#updateGlobalConfig();
        });
        this._keepForFullscreen.set_active(this.#settings.keepRoundedCorners.fullscreen);
        this._keepForFullscreen.connect('notify::active', (swtch) => {
            this.#settings.keepRoundedCorners.fullscreen =
                swtch.get_active();
            this.#updateGlobalConfig();
        });
        this._paddings.paddingTop = this.#settings.padding.top;
        this._paddings.connect('notify::padding-top', (row) => {
            this.#settings.padding.top = row.paddingTop;
            this.#updateGlobalConfig();
        });
        this._paddings.paddingBottom = this.#settings.padding.bottom;
        this._paddings.connect('notify::padding-bottom', (row) => {
            this.#settings.padding.bottom = row.paddingBottom;
            this.#updateGlobalConfig();
        });
        this._paddings.paddingStart = this.#settings.padding.left;
        this._paddings.connect('notify::padding-start', (row) => {
            this.#settings.padding.left = row.paddingStart;
            this.#updateGlobalConfig();
        });
        this._paddings.paddingEnd = this.#settings.padding.right;
        this._paddings.connect('notify::padding-end', (row) => {
            this.#settings.padding.right = row.paddingEnd;
            this.#updateGlobalConfig();
        });
        bindPref('tweak-kitty-terminal', this._tweakKitty, 'active', Gio.SettingsBindFlags.DEFAULT);
        bindPref('debug-mode', this._enableDebugLogs, 'active', Gio.SettingsBindFlags.DEFAULT);
    }
    showResetPage(_) {
        const root = this.root;
        root.push_subpage(new ResetPage());
    }
    showShadowPage(_) {
        const root = this.root;
        root.push_subpage(new EditShadowPage());
    }
    #updateGlobalConfig() {
        setPref('global-rounded-corner-settings', this.#settings);
    }
    #updateFocusedBorderColorUi(enabled) {
        this._focusedBorderColorRow.set_visible(enabled);
    }
    #onSeparateBorderWidthsEnabled() {
        const current = getPref('border-width');
        setPref('border-width', current > 0 ? current : 0);
        setPref('secondary-border-width', current < 0 ? -current : 0);
    }
    #onSeparateBorderWidthsDisabled() {
        const inner = getPref('border-width');
        const outer = getPref('secondary-border-width');
        setPref('border-width', inner === 0 ? -outer : inner);
        setPref('secondary-border-width', 0);
    }
    #updateBorderWidthUi(separate) {
        this._borderWidthRow.set_title(separate ? _('Inner border width') : _('Border width'));
        this._outerBorderWidthRow.set_visible(separate);
        if (separate) {
            this._borderWidth.set_lower(0);
            this._borderWidth.set_upper(20);
        }
        else {
            this._borderWidth.set_lower(-20);
            this._borderWidth.set_upper(20);
        }
    }
});

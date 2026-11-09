import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {setQuickSettingsColumns, restoreQuickSettingsColumns} from './qsGrid.js';
import {enableSquareBars, disableSquareBars} from './squareBarLevel.js';

export default class QsColumnsExtension extends Extension {
    enable() {
        setQuickSettingsColumns(3);
        enableSquareBars();
    }

    disable() {
        disableSquareBars();
        restoreQuickSettingsColumns();
    }
}

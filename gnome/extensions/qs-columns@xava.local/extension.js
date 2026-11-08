import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {setQuickSettingsColumns, restoreQuickSettingsColumns} from './qsGrid.js';

export default class QsColumnsExtension extends Extension {
    enable() {
        setQuickSettingsColumns(3);
    }

    disable() {
        restoreQuickSettingsColumns();
    }
}

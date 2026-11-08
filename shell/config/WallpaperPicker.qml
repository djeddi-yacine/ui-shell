pragma Singleton
import QtQuick

QtObject {
    // Spawn position: "center", "top" (under the bar) or "bottom".
    readonly property string placement: Placement.defaultMode
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "wallpaper-picker"
    // Lazy first load; retain the existing controls/previews for instant reopens.
    readonly property bool asynchronousPanelLoad: true
    readonly property bool retainPanelAfterClose: true
    readonly property int maximumWidth: 1040
    readonly property int maximumHeight: 660
    readonly property int outerSpacingUnits: 4
    readonly property int innerSpacingUnits: 2
    readonly property int targetWidth: 180
    readonly property int headerInlineThreshold: 720
    readonly property int cellHeight: 180
    readonly property int tileGap: 12
    readonly property int maximumVisibleRows: 3
    readonly property int wideGridThreshold: 840
    readonly property int wideColumns: 4
    readonly property int mediumGridThreshold: 600
    readonly property int narrowColumns: 3
    readonly property int smallGridThreshold: 360
    readonly property int smallColumns: 2
    readonly property int minimumColumns: 1
    readonly property int previewWidth: 360
    readonly property int previewHeight: 200
    readonly property int previewDisplayHeight: 108
    readonly property int tileWidth: 180
    readonly property int tileHeight: 168
    readonly property int tileInset: 8
    readonly property int tileLabelGap: 4
    readonly property int statusMarkerSize: 4
    readonly property int actionWidth: 160
}

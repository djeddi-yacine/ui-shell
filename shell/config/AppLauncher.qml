pragma Singleton
import QtQuick

QtObject {
    // Spawn position: "center", "top" (under the bar) or "bottom".
    readonly property string placement: Placement.defaultMode
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "app-launcher"
    readonly property string runnerExecutable: "app2unit"
    // Service mode hands off promptly; scope mode waits for the application.
    readonly property list<string> runnerArguments: ["-t", "service", "-s", "app-graphical.slice", "-C"]
    readonly property list<string> hiddenEntryIds: []
    readonly property list<string> searchFields: ["name", "genericName", "keywords", "id"]
    readonly property bool showIcons: true
    readonly property bool showRowOutlines: false
    readonly property string defaultIcon: "application-x-executable"
    readonly property bool warmCatalog: true
    readonly property bool asynchronousPanelLoad: true
    readonly property bool retainPanelAfterClose: true
    readonly property int maximumWidth: 680
    readonly property int maximumHeight: 640
    readonly property int outerMargin: 36
    readonly property int panelPadding: 16
    readonly property int sectionSpacing: 8
    readonly property int visibleRows: 12
    readonly property int rowHeight: 32
    readonly property int rowSpacing: 6
    readonly property int rowPaddingY: 4
    readonly property int rowContentSpacing: 8
    readonly property int iconSize: 24
    readonly property int launchIndicatorSize: 8
    readonly property int previousKey: Qt.Key_Up
    readonly property int nextKey: Qt.Key_Down
    readonly property int previousPageKey: Qt.Key_PageUp
    readonly property int nextPageKey: Qt.Key_PageDown
}

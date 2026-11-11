pragma Singleton
import QtQuick

// The shell menu that other programs call through scripts/menu: its own two windows, like the
// clipboard history panel.
QtObject {
    readonly property string namespace: "ui-shell-menu"
    readonly property string scrimNamespace: "ui-shell-menu-scrim"
    readonly property real scrimOpacity: 0.4
    readonly property int cardWidth: 640
    readonly property int cardHeight: 520
    readonly property int outerMargin: 36
    readonly property int panelPadding: 16
    readonly property int sectionSpacing: 8
    readonly property int rowHeight: 36
    readonly property int rowSpacing: 0
    readonly property int rowPaddingY: 4
    // The tab strip height when two or more apps wait.
    readonly property int tabHeight: 32
    readonly property int tabSpacing: 6
    // Ctrl + these keys show the previous and the next app.
    readonly property int tabModifiers: Qt.ControlModifier
    readonly property int previousTabKey: Qt.Key_Left
    readonly property int nextTabKey: Qt.Key_Right
    readonly property int previousKey: Qt.Key_Up
    readonly property int nextKey: Qt.Key_Down
    readonly property int previousPageKey: Qt.Key_PageUp
    readonly property int nextPageKey: Qt.Key_PageDown
    readonly property int firstKey: Qt.Key_Home
    readonly property int lastKey: Qt.Key_End
    readonly property string noMatchText: qsTr("No matching lines")
    // Where scripts/menu and the shell meet: a directory under the runtime directory.
    readonly property string spoolSubdirectory: "ui-shell/menu"
    // The same name scripts/menu gives a caller it cannot name.
    readonly property string unknownApp: "unknown"
    // The call the preview request (UI_SHELL_OPEN_MENU=1) shows.
    readonly property var previewLines: [
        "alpha", "beta (gamma)", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa", "lambda"
    ]
    readonly property string previewPrompt: qsTr("Preview: ")
}

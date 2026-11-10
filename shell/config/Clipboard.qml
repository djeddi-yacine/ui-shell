pragma Singleton
import QtQuick

// The clipboard history panel: its own two windows, like the authentication dialog.
QtObject {
    readonly property string namespace: "ui-shell-clipboard"
    readonly property string scrimNamespace: "ui-shell-clipboard-scrim"
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "clipboard"
    readonly property real scrimOpacity: 0.4
    readonly property int cardWidth: 640
    readonly property int cardHeight: 560
    readonly property int outerMargin: 36
    readonly property int panelPadding: 16
    readonly property int sectionSpacing: 8
    readonly property int rowHeight: 36
    readonly property int rowSpacing: 0
    readonly property int rowPaddingY: 4
    readonly property int rowContentSpacing: 10
    // The kind badge at the start of each row, in pixels.
    readonly property int badgeSize: 24
    // A picture preview is requested only after the selection rests on it this long (milliseconds),
    // so scrolling past pictures does not decode each one.
    readonly property int imageDelayMilliseconds: 200
    readonly property int previewHeight: 180
    // Space (or a right click on an entry) opens and closes the preview under the list.
    readonly property int previewKey: Qt.Key_Space
    // Shift+Enter copies the content of a copied file instead of its address.
    readonly property int copyContentModifiers: Qt.ShiftModifier
    readonly property int previousKey: Qt.Key_Up
    readonly property int nextKey: Qt.Key_Down
    readonly property int previousPageKey: Qt.Key_PageUp
    readonly property int nextPageKey: Qt.Key_PageDown
    readonly property int deleteKey: Qt.Key_Delete
    // Shift+deleteKey asks to clear everything; Enter then confirms and Escape cancels.
    readonly property int clearModifiers: Qt.ShiftModifier
    readonly property int refreshKey: Qt.Key_F5
    // Ctrl+refreshLetterKey refreshes too.
    readonly property int refreshLetterKey: Qt.Key_R
    readonly property string emptyText: qsTr("Nothing copied yet")
    readonly property string noMatchText: qsTr("No matching entries")
}

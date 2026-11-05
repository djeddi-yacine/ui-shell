pragma Singleton
import QtQuick

QtObject {
    readonly property int maximumWidth: 620
    readonly property int maximumDetailsHeight: 220
    readonly property int detailsPadding: 12
    readonly property int scrollBarWidth: 4
    // Actions only: "dismiss" or "copy". Diagnostics are pointer-selectable.
    readonly property string initialFocus: "dismiss"
    readonly property int dismissKey: Keyboard.cancelKey
    readonly property int copyKey: Qt.Key_C
    readonly property int copyModifiers: Qt.ControlModifier | Qt.ShiftModifier
}

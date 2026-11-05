pragma Singleton
import QtQuick

QtObject {
    readonly property int cancelKey: Qt.Key_Escape
    readonly property int applyKey: Qt.Key_Return
    readonly property int alternateApplyKey: Qt.Key_Enter
    readonly property list<int> buttonActivationKeys: [Qt.Key_Return, Qt.Key_Enter]
    readonly property int buttonActivationModifiers: Qt.NoModifier
    readonly property list<int> popupActionKeys: [Qt.Key_Return, Qt.Key_Enter]
    readonly property int popupActionModifiers: Qt.ControlModifier
    readonly property int previousKey: Qt.Key_Left
    readonly property int nextKey: Qt.Key_Right
    readonly property int rowUpKey: Qt.Key_Up
    readonly property int rowDownKey: Qt.Key_Down
    readonly property int selectKey: Qt.Key_Space
    readonly property int searchKey: Qt.Key_F
    readonly property int searchModifiers: Qt.ControlModifier
    readonly property int infoKey: Qt.Key_I
    readonly property int helpKey: Qt.Key_Space
    readonly property int settingsKey: Qt.Key_E
    readonly property int contextModifiers: Qt.ControlModifier
    // Portable Qt key names, shared by native shortcuts and their help text.
    // Extend this explicit table when configuring a non-printable custom key.
    readonly property var namedKeys: [
        { key: Qt.Key_Escape, name: "Esc" }, { key: Qt.Key_Return, name: "Return" },
        { key: Qt.Key_Enter, name: "Enter" }, { key: Qt.Key_Space, name: "Space" },
        { key: Qt.Key_Tab, name: "Tab" }, { key: Qt.Key_Backtab, name: "Backtab" },
        { key: Qt.Key_Up, name: "Up" }, { key: Qt.Key_Down, name: "Down" },
        { key: Qt.Key_Left, name: "Left" }, { key: Qt.Key_Right, name: "Right" },
        { key: Qt.Key_PageUp, name: "PgUp" }, { key: Qt.Key_PageDown, name: "PgDown" },
        { key: Qt.Key_Home, name: "Home" }, { key: Qt.Key_End, name: "End" },
        { key: Qt.Key_Insert, name: "Ins" }, { key: Qt.Key_Delete, name: "Del" },
        { key: Qt.Key_Backspace, name: "Backspace" }
    ]
    function shortcut(key, modifiers) {
        if (modifiers & ~(Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier | Qt.MetaModifier))
            throw new Error("Add an explicit portable name for the configured modifier: " + modifiers)
        const names = []
        if (modifiers & Qt.ControlModifier) names.push("Ctrl")
        if (modifiers & Qt.AltModifier) names.push("Alt")
        if (modifiers & Qt.ShiftModifier) names.push("Shift")
        if (modifiers & Qt.MetaModifier) names.push("Meta")
        const named = namedKeys.find(entry => entry.key === key)
        if (named) names.push(named.name)
        else if (key > Qt.Key_Space && key <= Qt.Key_AsciiTilde) names.push(String.fromCharCode(key))
        else if (key >= Qt.Key_F1 && key <= Qt.Key_F35) names.push("F" + (key - Qt.Key_F1 + 1))
        else throw new Error("Add the configured key to Keyboard.namedKeys: " + key)
        return names.join("+")
    }
}

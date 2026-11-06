pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

// The exit confirmation. The rule (STYLE.md): Esc always leaves. A panel whose work
// would be lost asks first, and here Esc means "dismiss and quit", so leaving a
// panel with unsaved changes takes two Esc presses and a stray one never loses
// anything. A panel that is only a view calls request(false) and leaves at once.
// Keep editing is the default button; clicking outside the dialog also keeps editing.
ContextPopup {
    id: root
    objectName: "exitDialog"
    kind: "exit"
    shortcutsEnabled: false
    z: 2
    property string title: qsTr("Discard changes?")
    property string message: qsTr("Your unsaved changes will be lost.")
    primaryAction: keep
    closePolicy: Popup.CloseOnPressOutside
    // The user confirmed leaving; the panel closes itself.
    signal confirmed()

    // Leaves at once when nothing would be lost; otherwise asks. Returns true when it asked.
    function request(unsaved, previousFocus) {
        if (!unsaved) { confirmed(); return false }
        show("exit", previousFocus)
        return true
    }
    function confirm() { close(); confirmed() }
    onOpened: keep.forceActiveFocus()

    contentItem: FocusScope {
        implicitHeight: layout.implicitHeight
        focus: true
        Keys.onPressed: event => {
            root.inputState.keyboardUsed()
            if (event.key === Config.Keyboard.cancelKey) { root.confirm(); event.accepted = true }
        }
        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: Config.ContextPanels.spacing
            Text {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.style.text
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
                font.weight: root.style.emphasisWeight
                Accessible.role: Accessible.Heading
            }
            Text {
                Layout.fillWidth: true
                text: root.message
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.style.textMuted
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Config.ContextPanels.spacing
                ShellButton {
                    id: discard
                    objectName: "exitDiscard"
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    text: qsTr("Discard and quit")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.tab: keep
                    KeyNavigation.backtab: keep
                    onClicked: root.confirm()
                }
                Item { Layout.fillWidth: true }
                ShellButton {
                    id: keep
                    objectName: "exitKeep"
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    text: qsTr("Keep editing")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.tab: discard
                    KeyNavigation.backtab: discard
                    onClicked: root.close()
                }
            }
        }
    }
}

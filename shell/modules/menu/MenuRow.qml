import QtQuick
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config

// One line of a menu request. The text is shown as plain text, one line, cut at the end.
Item {
    id: root
    required property string line
    required property var style
    required property Controls.InputState inputState
    required property bool selected
    required property bool candidateVisible
    objectName: "menuRow"
    signal chosen()
    signal activated()
    activeFocusOnTab: false
    onFocusChanged: { if (focus) focus = false }
    implicitHeight: Config.Menu.rowHeight
    Accessible.role: Accessible.Button
    Accessible.name: line
    Controls.ShellControlState {
        id: visual
        style: root.style
        emphasis: Theme.Interaction.selectorOptionEmphasis
        enabled: root.enabled
        selected: root.selected && root.candidateVisible
        hovered: root.inputState.pointerActive && pointer.containsMouse
        pressed: pointer.pressed
        focused: root.selected && root.candidateVisible && !root.inputState.pointerActive
    }
    Controls.ShellControlBackground {
        anchors.fill: parent
        controlState: visual
        border.color: visual.focused ? visual.border : "transparent"
    }
    Text {
        objectName: "menuRowLabel"
        anchors.fill: parent
        anchors.leftMargin: root.style.controlPaddingX
        anchors.rightMargin: root.style.controlPaddingX
        anchors.topMargin: Config.Menu.rowPaddingY
        anchors.bottomMargin: Config.Menu.rowPaddingY
        verticalAlignment: Text.AlignVCenter
        text: root.line
        textFormat: Text.PlainText
        maximumLineCount: 1
        color: visual.foreground
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
        font.weight: root.style.bodyWeight
        elide: Text.ElideRight
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.inputState.pointerUsed()
        onClicked: { root.chosen(); root.activated() }
    }
    Controls.PointerTracker { inputState: root.inputState; enabled: root.enabled }
    Accessible.onPressAction: { root.chosen(); root.activated() }
}

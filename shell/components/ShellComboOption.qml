import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../theme" as Theme

ItemDelegate {
    id: root
    required property var style
    required property InputState inputState
    required property string emphasis
    required property bool currentChoice
    required property bool keyboardCandidate
    readonly property bool candidate: keyboardCandidate
    readonly property color foregroundColor: visual.foreground

    implicitHeight: style.controlHeight
    padding: style.controlPaddingY
    leftPadding: style.controlPaddingX
    rightPadding: style.controlPaddingX
    font.family: style.uiFamily
    font.pointSize: style.bodyPointSize
    font.weight: style.bodyWeight
    // One cursor for mouse and keyboard: while the pointer is the active input, hovering a row
    // moves the combo box's highlight (Qt does that for hover-enabled delegates), so there is a
    // single highlighted row and the pointer is never ignored. While the keyboard drives, hover is
    // off, so a pointer resting under a freshly opened list cannot steal the keyboard's choice.
    hoverEnabled: inputState.pointerActive && visual.flags.hover !== "none"
    Accessible.selected: currentChoice
    onPressed: inputState.pointerUsed()

    ShellControlState {
        id: visual
        style: root.style
        emphasis: root.emphasis
        enabled: root.enabled
        // The candidate (keyboard or hover, see above) is the only highlight; no second one here.
        hovered: false
        pressed: root.down
        selected: root.candidate
        current: root.currentChoice
        focused: root.activeFocus
    }
    contentItem: RowLayout {
        spacing: root.style.controlPaddingX
        Rectangle {
            Layout.preferredWidth: Theme.Interaction.committedMarkerSize
            Layout.preferredHeight: Theme.Interaction.committedMarkerSize
            color: root.currentChoice ? visual.markerColor : Theme.Interaction.transparentColor
            Accessible.ignored: true
        }
        Text {
            Layout.fillWidth: true
            text: root.text
            font: root.font
            color: visual.foreground
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
    background: ShellControlBackground {
        controlState: visual
        // The popup owns the perimeter; rows communicate state through their fill.
        border.width: 0
        border.color: Theme.Interaction.transparentColor
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => { root.inputState.keyboardUsed(); event.accepted = false }
    PointerTracker { inputState: root.inputState; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
}

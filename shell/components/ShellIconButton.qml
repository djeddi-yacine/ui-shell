import QtQuick
import "../theme" as Theme

// A button that is its picture: no box, no label. Keyboard, pointer and focus behave as in
// ShellButton. The picture is muted at rest, bright under the pointer, accent while pressed or
// selected, and a focus outline shows only when the keyboard drives. `label` is the accessible name.
ShellButton {
    id: root
    required property string glyph
    required property string label
    property real iconSize: 16
    readonly property bool pointerOver: hovered && inputState.pointerActive
    readonly property bool keyboardFocus: activeFocus && Window.active && !inputState.pointerActive
    text: ""
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    Accessible.name: label
    background: Rectangle {
        color: "transparent"
        radius: root.style.controlRadius
        border.width: root.keyboardFocus ? 2 : 0
        border.color: root.style.focus
    }
    contentItem: Icon {
        name: root.glyph
        size: root.iconSize
        centered: true
        // Idle in the full text colour; hover or keyboard selection lifts it to the control focus
        // role; pressed or selected is the accent, the colour of an action.
        color: !root.enabled ? root.style.controls.disabledText
            : root.down || root.selected ? root.style.accent
            : root.pointerOver || root.keyboardFocus ? root.style.controls.focus : root.style.text
        scale: root.down ? Theme.Motion.pressScale : 1
        Behavior on color { enabled: Theme.Motion.active; ColorAnimation { duration: Theme.Motion.stateDuration } }
        Behavior on scale { enabled: Theme.Motion.active; NumberAnimation { duration: Theme.Motion.stateDuration } }
    }
}

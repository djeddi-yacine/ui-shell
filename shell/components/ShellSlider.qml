import QtQuick
import QtQuick.Controls.Basic
import "../config" as Config
import "../theme" as Theme

// The shared slider: a quiet track and a square handle whose border is the
// focus ring. Used by the colour channels and the control-tuning panel.
Slider {
    id: root
    required property var style
    required property InputState inputState
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    onPressedChanged: if (pressed) inputState.pointerUsed()
    Keys.onPressed: event => { inputState.keyboardUsed(); event.accepted = false }

    ShellControlState { id: visual; style: root.style; control: root
        inputState: root.inputState; emphasis: Theme.Interaction.buttonEmphasis }
    PointerTracker { inputState: root.inputState; enabled: root.enabled }
    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: Config.ThemeEditor.channelTrackHeight
        color: root.style.controls.outline
        // The filled part of the track shows the value without a second control.
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: root.style.controls.primary
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: Config.ThemeEditor.channelHandleSize
        height: Config.ThemeEditor.channelHandleSize
        color: root.pressed ? root.style.controls.primaryPressed : root.style.surfaceRaised
        border.width: Theme.Shape.borderWidth
        border.color: visual.focused ? root.style.controls.focus : root.style.controls.outline
    }
}

import QtQuick
import QtQuick.Controls.Basic
import "../config" as Config
import "../theme" as Theme

// The shared slider, outlined like the reference panels: an outlined track with a
// primary fill and a square handle. Works the same by mouse and keyboard: click the
// track to jump, drag, scroll the wheel (native `wheelEnabled`), arrow keys step,
// Home and End jump to the ends (added here). Programmatic and keyboard changes glide; a drag
// follows the pointer exactly. Used by the colour channels, tuning and audio.
Slider {
    id: root
    required property var style
    required property InputState inputState
    // False while the surrounding list is being scrolled, so a wheel gesture that began
    // scrolling is not captured by the slider it happens to pass over.
    property bool wheelAllowed: true
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    wheelEnabled: wheelAllowed
    onPressedChanged: if (pressed) inputState.pointerUsed()
    // Qt's slider steps with the arrows but has no Home or End. Stepping with its own
    // increase() and decrease() (not assigning `value`) keeps declarative bindings alive.
    function jumpTo(target) {
        const steps = stepSize > 0 ? Math.round(Math.abs(target - value) / stepSize) : 0
        for (let i = 0; i < steps; i++) { if (target > value) increase(); else decrease() }
        moved()
    }
    Keys.onPressed: event => {
        inputState.keyboardUsed()
        const jump = event.key === Qt.Key_Home || event.key === Qt.Key_End
        if (jump) jumpTo(event.key === Qt.Key_Home ? from : to)
        event.accepted = jump
    }

    ShellControlState { id: visual; style: root.style; control: root
        inputState: root.inputState; emphasis: Theme.Interaction.buttonEmphasis }
    PointerTracker { inputState: root.inputState; enabled: root.enabled }

    readonly property real trackHeight: Config.ThemeEditor.channelTrackHeight + 4
    readonly property bool glide: Theme.Motion.active && !root.pressed
    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: root.trackHeight
        color: root.style.surface
        border.width: Theme.Shape.borderWidth
        border.color: visual.focused ? root.style.controls.focus
            : root.hovered ? root.style.controls.hover : root.style.controls.outline
        // The filled part follows the handle, so it glides with it.
        Rectangle {
            x: Theme.Shape.borderWidth
            y: Theme.Shape.borderWidth
            width: Math.max(0, handleItem.x + handleItem.width / 2 - root.leftPadding - Theme.Shape.borderWidth)
            height: parent.height - Theme.Shape.borderWidth * 2
            color: root.enabled ? root.style.controls.primary : root.style.controls.disabledSurface
        }
    }
    handle: Rectangle {
        id: handleItem
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: Config.ThemeEditor.channelHandleSize
        height: Config.ThemeEditor.channelHandleSize
        color: root.pressed ? root.style.controls.primary : visual.focused ? root.style.controls.focusSurface : root.style.surfaceRaised
        border.width: Theme.Shape.borderWidth
        border.color: visual.focused ? root.style.controls.focus
            : root.pressed || root.hovered ? root.style.controls.primary : root.style.controls.outline
        Behavior on x { enabled: root.glide; NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        Behavior on color { enabled: root.glide; ColorAnimation { duration: Theme.Motion.stateDuration } }
    }
}

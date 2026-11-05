import QtQuick
import "../theme" as Theme

Rectangle {
    required property var controlState
    id: root

    radius: Theme.Shape.controlRadius
    color: controlState.fill
    border.width: controlState.borderWidth
    border.color: controlState.border
    Accessible.ignored: true

    // State feedback changes color only; every edge keeps the same geometry.
    Behavior on border.color {
        enabled: Theme.Motion.active && root.visible && root.controlState.flags.animate
            && root.controlState.enabled && !root.controlState.pressed
        ColorAnimation {
            duration: Theme.Motion.stateDuration
            easing.type: Theme.Motion.stateEasing
        }
    }

    Behavior on color {
        enabled: Theme.Motion.active && root.visible && root.controlState.flags.animate
            && root.controlState.enabled && !root.controlState.pressed
        ColorAnimation {
            duration: Theme.Motion.shortDuration
            easing.type: Theme.Motion.enterEasing
        }
    }
}

import QtQuick
import "../theme" as Theme

Item {
    id: root
    required property Item surface
    // The card's scale; panels bind `scale: motion.cardScale` on their card.
    property real cardScale: 1
    property bool closing: false
    signal closed()

    function reset() {
        entry.stop()
        exit.stop()
        cardScale = 1
        surface.opacity = 1
        closing = false
    }
    function enter() {
        reset()
        if (Theme.Motion.active) entry.restart()
    }
    function leave() {
        if (closing || !surface.visible) return
        closing = true
        entry.stop()
        if (Theme.Motion.active) exit.restart()
        else closed()
    }
    Connections {
        target: root.surface
        function onVisibleChanged() {
            if (!root.surface.visible) root.reset()
        }
    }
    ParallelAnimation {
        id: entry
        NumberAnimation {
            target: root; property: "cardScale"
            from: Theme.Motion.panelEnterScale; to: 1
            duration: Theme.Motion.enterDuration
            easing.type: Theme.Motion.enterEasing
        }
        NumberAnimation {
            target: root.surface; property: "opacity"
            from: Theme.Motion.panelEnterOpacity; to: 1
            duration: Theme.Motion.enterDuration
            easing.type: Theme.Motion.enterEasing
        }
    }
    ParallelAnimation {
        id: exit
        NumberAnimation {
            target: root; property: "cardScale"; to: Theme.Motion.panelExitScale
            duration: Theme.Motion.exitDuration
            easing.type: Theme.Motion.exitEasing
        }
        NumberAnimation {
            target: root.surface; property: "opacity"; to: 0
            duration: Theme.Motion.exitDuration
            easing.type: Theme.Motion.exitEasing
        }
        onFinished: root.closed()
    }
}

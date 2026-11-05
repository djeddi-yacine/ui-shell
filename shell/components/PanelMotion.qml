import QtQuick
import "../theme" as Theme

Item {
    id: root
    required property Item surface
    property real offset: 0
    property bool closing: false
    signal closed()

    function reset() {
        entry.stop()
        exit.stop()
        offset = 0
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
            target: root; property: "offset"
            from: Theme.Motion.panelEnterOffset; to: 0
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
            target: root; property: "offset"; to: Theme.Motion.panelExitOffset
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

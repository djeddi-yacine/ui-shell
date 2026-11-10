import QtQuick
import "../theme" as Theme

// The shell's animated list. A ScriptModel diffs new results against the old by identity, so
// the view animates what changed (rows slide, fade in or out) instead of being rebuilt. Rows
// are not pooled: a pooled row would jump to its new place instead of animating there.
// Keyboard selection is owned by the panel, never by the view.
ListView {
    clip: true
    keyNavigationEnabled: false
    reuseItems: false
    highlightMoveDuration: 0
    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
    }
    displaced: Transition {
        NumberAnimation { property: "y"; duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing }
        NumberAnimation { property: "opacity"; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
    }
    move: Transition {
        NumberAnimation { property: "y"; duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing }
        NumberAnimation { property: "opacity"; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
    }
    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
    }
}

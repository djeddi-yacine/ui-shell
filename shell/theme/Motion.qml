pragma Singleton

import QtQuick

QtObject {
    readonly property bool enabled: true
    readonly property bool reducedMotion: false
    readonly property bool active: enabled && !reducedMotion
    readonly property int shortDuration: 80
    readonly property int stateDuration: 80
    readonly property int stateEasing: Easing.OutCubic
    readonly property int standardDuration: 140
    readonly property int enterDuration: 120
    readonly property int exitDuration: 80
    readonly property int enterEasing: Easing.OutCubic
    readonly property int exitEasing: Easing.OutCubic
    // A control that moves on its own (a slider handle gliding to a new value).
    readonly property int glideDuration: standardDuration
    // How long a scroll gesture counts as running after its last movement, and how long a freshly
    // built view waits before it shows its real values so they can animate in.
    readonly property int scrollQuietDelay: 280
    readonly property int revealDelay: 40
    // A panel pops in from slightly smaller (no slide) while it fades up, and shrinks a little as it fades out.
    readonly property real panelEnterScale: 0.96
    readonly property real panelExitScale: 0.98
    readonly property real panelEnterOpacity: 0
    // A filtered list: rows that stay slide to their new place, new rows fade in, dropped rows fade out.
    readonly property int listMoveDuration: 200
    readonly property int listFadeDuration: 100
    readonly property int listMoveEasing: Easing.OutCubic
    readonly property int launchPulseDuration: 360
    readonly property int launchPulseEasing: Easing.InOutSine
    readonly property real launchPulseMinimumOpacity: 0.85
    readonly property real launchPulseMaximumOpacity: 1.0
}

pragma Singleton

import QtQuick

QtObject {
    readonly property bool enabled: true
    readonly property bool reducedMotion: false
    readonly property bool active: enabled && !reducedMotion
    readonly property int shortDuration: 80
    readonly property int stateDuration: 80
    readonly property int stateEasing: Easing.OutCubic
    // A picture-only button shrinks to this while pressed.
    readonly property real pressScale: 0.88
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
    // A notification popup pops in and out like a panel.
    readonly property int popupInDuration: 180
    readonly property int popupOutDuration: 120
    readonly property int listMoveDuration: 200
    readonly property int listFadeDuration: 100
    readonly property int listMoveEasing: Easing.OutCubic
    // The notification drawer slides and fades in and out in this one time.
    readonly property int drawerDuration: 120
    // Notification stack: one spring drives the deck fanning out into a list (and back). Under-damped
    // so the cards overshoot a little; each card starts a beat after the one above it.
    readonly property real stackSpring: 3.2
    readonly property real stackDamping: 0.36
    readonly property real stackEpsilon: 0.001
    readonly property real stackStagger: 0.07
    readonly property int stackStaggerCap: 6
    readonly property int stackLeaveDuration: 220
    readonly property int launchPulseDuration: 360
    readonly property int launchPulseEasing: Easing.InOutSine
    readonly property real launchPulseMinimumOpacity: 0.85
    readonly property real launchPulseMaximumOpacity: 1.0
}

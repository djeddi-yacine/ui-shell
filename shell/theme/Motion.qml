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
    readonly property int enterDuration: 140
    readonly property int exitDuration: 80
    readonly property int enterEasing: Easing.OutCubic
    readonly property int exitEasing: Easing.OutCubic
    readonly property real panelEnterOffset: 8
    readonly property real panelExitOffset: 4
    readonly property real panelEnterOpacity: 0.92
    readonly property int launchPulseDuration: 360
    readonly property int launchPulseEasing: Easing.InOutSine
    readonly property real launchPulseMinimumOpacity: 0.85
    readonly property real launchPulseMaximumOpacity: 1.0
}

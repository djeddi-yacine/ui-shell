pragma Singleton

import QtQuick

QtObject {
    readonly property string preset: "sharp90deg"

    readonly property int surfaceRadius: 0
    readonly property int controlRadius: 0
    readonly property int inputRadius: 0
    readonly property int menuRadius: 0
    readonly property int badgeRadius: 0
    readonly property int indicatorRadius: 0
    readonly property int borderWidth: 1
    // How much of a colour a quiet border, a section rule, an accent chip border and a resting link keep.
    readonly property real softBorderOpacity: 0.7
    readonly property real ruleOpacity: 0.45
    readonly property real accentBorderOpacity: 0.6
    readonly property real linkRestOpacity: 0.85
    readonly property int chevronWidth: 12
    readonly property int chevronHeight: 8
    readonly property int chevronArmLength: 8
    readonly property int chevronStrokeWidth: 2
    readonly property real chevronAngle: 45
}

pragma Singleton

import QtQuick

QtObject {
    readonly property var colorData: ActivePalettes.globalPalette
    readonly property string mode: ActivePalettes.globalPalette.mode
    readonly property var colors: ActivePalettes.globalPalette.colors
    readonly property var hyprland: ActivePalettes.globalPalette.hyprland
    readonly property color background: ActivePalettes.globalPalette.background
    readonly property color surface: ActivePalettes.globalPalette.surface
    readonly property color surfaceVariant: ActivePalettes.globalPalette.surfaceVariant
    readonly property color elevated: ActivePalettes.globalPalette.elevated
    readonly property color text: ActivePalettes.globalPalette.text
    readonly property color textMuted: ActivePalettes.globalPalette.textMuted
    readonly property color accent: ActivePalettes.globalPalette.accent
    readonly property color positive: ActivePalettes.globalPalette.positive
    readonly property color warning: ActivePalettes.globalPalette.warning
    readonly property color negative: ActivePalettes.globalPalette.negative
    readonly property color outline: ActivePalettes.globalPalette.outline
    readonly property color focus: ActivePalettes.globalPalette.focus
    readonly property color scrim: ActivePalettes.globalPalette.scrim
}

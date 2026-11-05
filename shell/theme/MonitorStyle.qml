import QtQuick

QtObject {
    id: root
    required property var palette
    // Optional ControlColors amount overrides for this output (see ControlColors.knobNames).
    property var controlTuning: ({})
    // Optional control mode for this surface; empty follows the global mode.
    property string controlMode: ""
    readonly property ControlColors controls: ControlColors { palette: root.palette; tuning: root.controlTuning; mode: root.controlMode }

    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceVariant: palette.surfaceVariant
    readonly property color surfaceRaised: palette.elevated
    readonly property color text: palette.text
    readonly property color textMuted: controls.muted
    readonly property color accent: palette.accent
    readonly property color positive: palette.positive
    readonly property color warning: palette.warning
    readonly property color negative: palette.negative
    readonly property color outline: palette.outline
    readonly property color focus: palette.focus
    readonly property color scrim: palette.scrim

    readonly property int surfaceRadius: Shape.surfaceRadius
    readonly property int controlRadius: Shape.controlRadius
    readonly property int inputRadius: Shape.inputRadius
    readonly property int menuRadius: Shape.menuRadius
    readonly property int badgeRadius: Shape.badgeRadius
    readonly property int indicatorRadius: Shape.indicatorRadius
    readonly property int spacing: Density.spacing
    readonly property int controlHeight: Density.controlHeight
    readonly property int controlPaddingX: Density.controlPaddingX
    readonly property int controlPaddingY: Density.controlPaddingY
    readonly property int menuMaximumHeight: Density.menuMaximumHeight
    readonly property int menuViewportMargin: Density.menuViewportMargin
    readonly property int barHeight: Density.barHeight
    readonly property string uiFamily: Typography.uiFamily
    readonly property string monoFamily: Typography.monoFamily
    readonly property real bodyPointSize: Typography.bodyPointSize
    readonly property real captionPointSize: Typography.captionPointSize
    readonly property real titlePointSize: Typography.titlePointSize
    readonly property int bodyWeight: Typography.bodyWeight
    readonly property int emphasisWeight: Typography.emphasisWeight
    readonly property bool motionEnabled: Motion.active
    readonly property int shortDuration: Motion.shortDuration
    readonly property int standardDuration: Motion.standardDuration
}

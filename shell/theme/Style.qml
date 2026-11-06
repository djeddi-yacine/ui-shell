pragma Singleton

import QtQuick
import "." as LocalTheme

QtObject {
    id: root
    // Optional ControlColors amount overrides (see ControlColors.knobNames).
    property var controlTuning: ({})
    property string controlMode: ""
    readonly property ControlColors controls: ControlColors { palette: LocalTheme.Palette; tuning: root.controlTuning; mode: root.controlMode }
    readonly property color background: LocalTheme.Palette.background
    readonly property color surface: LocalTheme.Palette.surface
    readonly property color surfaceVariant: LocalTheme.Palette.surfaceVariant
    readonly property color surfaceRaised: LocalTheme.Palette.elevated
    readonly property color text: LocalTheme.Palette.text
    readonly property color textMuted: controls.muted
    readonly property color accent: LocalTheme.Palette.accent
    readonly property color positive: LocalTheme.Palette.positive
    readonly property color warning: LocalTheme.Palette.warning
    readonly property color negative: LocalTheme.Palette.negative
    readonly property color outline: LocalTheme.Palette.outline
    readonly property color focus: LocalTheme.Palette.focus
    readonly property color scrim: LocalTheme.Palette.scrim

    readonly property int surfaceRadius: Shape.surfaceRadius
    readonly property int controlRadius: Shape.controlRadius
    readonly property int inputRadius: Shape.inputRadius
    readonly property int menuRadius: Shape.menuRadius
    readonly property int badgeRadius: Shape.badgeRadius
    readonly property int indicatorRadius: Shape.indicatorRadius
    // Surface rules. A PICKER is a full panel (wallpaper, apps, audio, tuning): the base
    // surface, one outline, the menu radius. A POPUP opens over a picker (context, error,
    // colour, combo menus): one step up (elevated) with a readable outline, so it never
    // blends into the picker beneath. Use these, never raw surface/elevated, for either.
    readonly property color pickerSurface: surface
    readonly property color pickerBorder: controls.outline
    readonly property int pickerRadius: menuRadius
    readonly property color popupSurface: surfaceRaised
    readonly property color popupBorder: Interaction.readable(outline, surfaceRaised, Interaction.minimumStateContrast)
    readonly property int popupRadius: menuRadius
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

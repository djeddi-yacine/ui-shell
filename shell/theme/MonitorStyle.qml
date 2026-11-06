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
    readonly property int spacingTight: Density.spacingTight
    readonly property int spacingLoose: Density.spacingLoose
    readonly property int cardPadding: Density.cardPadding
    readonly property int rowHeight: Density.rowHeight
    readonly property int sliderHeight: Density.sliderHeight
    readonly property int nodeSocketSize: Density.nodeSocketSize
    readonly property int chooserWidth: Density.chooserWidth
    readonly property int readoutWidth: Density.readoutWidth
    readonly property int listVisibleRows: Density.listVisibleRows
    readonly property real microPointSize: Typography.microPointSize
    readonly property real displayPointSize: Typography.displayPointSize
    readonly property real labelLetterSpacing: Typography.labelLetterSpacing
    readonly property real chipLetterSpacing: Typography.chipLetterSpacing
    readonly property int glideDuration: Motion.glideDuration
    // Quiet versions of the control outline and the accent, for cards, rules, chips and resting links.
    readonly property color softOutline: Qt.alpha(controls.outline, Shape.softBorderOpacity)
    readonly property color rule: Qt.alpha(controls.outline, Shape.ruleOpacity)
    readonly property color softAccent: Qt.alpha(controls.primary, Shape.accentBorderOpacity)
    readonly property color restingLink: Qt.alpha(controls.outline, Shape.linkRestOpacity)
    // The dimming over everything behind a panel.
    function scrimColor(opacity) { return Qt.rgba(scrim.r, scrim.g, scrim.b, opacity) }
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

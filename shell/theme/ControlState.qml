import QtQuick

// Resolves one control's fill, foreground and border from its interaction state
// by interpreting the active mode's behaviour profile (ControlTuning.behavior,
// declared in scripts/render-control-tuning). The profile names, per state and
// channel, which colour role to paint; flags decide whether the pointer is heard
// at all, whether a marker shows, and whether changes animate. Nothing about a
// state is hard-coded here.
//
// Emphasis, precedence and the state specs are all in the profile. The shipped
// emphasis are outline (resting outline), flat (no resting border: bar entries,
// menu and list rows) and solid (filled primary action).
QtObject {
    id: root

    required property ControlColors colors
    required property string emphasis
    property bool enabled: true
    property bool hovered: false
    property bool pressed: false
    property bool selected: false
    property bool focused: false
    property bool current: false
    // Overridable per control; defaults to the style's mode (else the global one).
    property var behavior: colors.behavior

    readonly property var flags: behavior.flags
    // Emphasis is a registry in the profile: which family of state specs it uses
    // and its resting border. A new emphasis is data, not a code branch.
    readonly property var emphasisSpec: {
        const entry = behavior.emphasis[emphasis]
        if (!entry)
            throw new Error("ControlState: invalid emphasis '" + emphasis + "'; expected " + Object.keys(behavior.emphasis).join(", "))
        return entry
    }
    readonly property var family: behavior.families[emphasisSpec.family]
    readonly property bool solid: emphasisSpec.family === "solid"
    // A mode can turn pointer hover off entirely (keyboard-first modes).
    readonly property bool pointerHover: hovered && flags.hover !== "none"
    // The profile's precedence list decides which active flag names the state.
    readonly property var activeStates: ({ disabled: !enabled, pressed: pressed, select: selected, focus: focused,
        current: current, hover: pointerHover, normal: true })
    readonly property string state: behavior.precedence.find(name => activeStates[name]) ?? "normal"
    readonly property var spec: family.states[state]
    readonly property color restBorder: role(emphasisSpec.rest === "outline" && flags.restingBorder === "none" ? "none" : emphasisSpec.rest)

    readonly property color selectedColor: colors.primary
    readonly property color currentColor: colors.current
    readonly property color hoverColor: colors.hover
    readonly property color pressedColor: colors.pressed
    readonly property color focusedColor: colors.focus
    // The committed-item marker (a small square); transparent when the mode has none.
    readonly property color markerColor: flags.currentMarker ? colors.current : Interaction.transparentColor

    function role(name) { return name === "rest" ? restBorder : colors.roles[name] }

    readonly property color fill: {
        const base = role(spec.fill)
        // Hover still lifts a selected or applied fill, unless the mode ignores the pointer.
        return pointerHover && family.hoverLift && (state === "select" || state === "current")
            ? colors.layer(base, colors.palette.text, colors.hoverLayer) : base
    }
    readonly property color foreground: role(spec.fg)
    readonly property color stateColor: {
        if (!enabled) return spec.border === "disabledBorder" && restBorder.a === 0 ? Interaction.transparentColor : role(spec.border)
        // The keyboard-focus ring overlays whatever else the control is showing.
        if (focused && flags.focusRing) return role(family.states.focus.border)
        // With the ring off, the focus state shows no border of its own either.
        return state === "focus" && !flags.focusRing ? restBorder : role(spec.border)
    }
    // Secondary text on this control (descriptions, hints), tinted to match its fill.
    readonly property color mutedForeground: !enabled ? colors.disabledText
        : spec.fg === "containerText" || spec.fg === "primaryText" ? role(spec.fg) : colors.muted
    readonly property color border: stateColor
    readonly property int borderWidth: Shape.borderWidth
}

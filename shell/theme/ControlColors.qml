import QtQuick

// Control colour roles derived from one palette, following Material 3's model:
//   surface + state layers   neutral controls and their hover/focus/pressed wash
//   primary / primaryText      filled primary actions (hue-tinted content)
//   container / containerText  tonal fill for selected rows, tiles and buttons
//   current container        the committed (applied) item, in the positive hue
//   disabled                 38% content / 12% container, never a readable role
// Every readable role is verified against the surfaces it can sit on.
QtObject {
    required property var palette
    // Optional per-style overrides of the model amounts (ControlTuning: generated
    // defaults, the saved user file and the tuning panel's draft sit beneath this),
    // e.g. { hoverLayer: 0.12, containerShift: 0.14, textContrast: 4.5 }.
    // Unknown keys are errors, so a typo cannot silently do nothing.
    property var tuning: ({})
    readonly property var knobNames: ControlTuning.schema.map(knob => knob.key)
    readonly property bool tuningValid: {
        for (const key of Object.keys(tuning))
            if (!knobNames.includes(key))
                throw new Error("ControlColors: unknown tuning key '" + key + "'; expected one of " + knobNames.join(", "))
        return true
    }
    // Optional mode for this style alone (a surface can differ from the global mode):
    // its preset sits under `tuning` and above the model's global values.
    property string mode: ""
    readonly property var modeEntry: mode.length > 0 ? ControlTuning.modes.find(entry => entry.key === mode) ?? null : null
    // The behaviour profile controls of this style follow.
    readonly property var behavior: modeEntry ? modeEntry.behavior : ControlTuning.behavior
    function knob(name, fallback) {
        if (!tuningValid) return fallback
        if (tuning[name] !== undefined) return tuning[name]
        return modeEntry && modeEntry.values[name] !== undefined ? modeEntry.values[name] : fallback
    }

    // State layers (Material 3): a translucent content wash over the resting fill.
    readonly property real hoverLayer: knob("hoverLayer", Interaction.hoverLayer)
    readonly property real focusLayer: knob("focusLayer", Interaction.focusLayer)
    readonly property real pressedLayer: knob("pressedLayer", Interaction.pressedLayer)
    // Tonal containers: accent / status colour washed into the surface.
    readonly property real containerShift: knob("containerShift", Interaction.containerShift)
    readonly property real containerChroma: knob("containerChroma", Interaction.containerChroma)
    readonly property real currentShift: knob("currentShift", Interaction.currentShift)
    readonly property real currentChroma: knob("currentChroma", Interaction.currentChroma)
    readonly property real disabledContent: knob("disabledContent", Interaction.disabledContent)
    readonly property real disabledContainer: knob("disabledContainer", Interaction.disabledContainer)
    readonly property real hoverTextMix: knob("hoverTextMix", Interaction.hoverTextMix)
    readonly property real activeTextMix: knob("activeTextMix", Interaction.activeTextMix)
    // Body text aims for this contrast, settling for the 4.5 floor only when the hue cannot reach it.
    // Borders borrow the text colour's hue so they sit in the same tonal family as the labels.
    readonly property real outlineTextMix: knob("outlineTextMix", Interaction.outlineTextMix)
    readonly property real mutedContrast: knob("mutedContrast", Interaction.preferredMutedContrast)
    readonly property real textContrast: knob("textContrast", Interaction.preferredTextContrast)

    readonly property color surface: palette.surface
    readonly property color hoverSurface: layer(surface, palette.text, hoverLayer)
    readonly property color focusSurface: layer(surface, palette.text, focusLayer)
    readonly property color pressedSurface: layer(surface, palette.text, pressedLayer)
    readonly property var feedbackSurfaces: [surface, hoverSurface, focusSurface, pressedSurface]

    // Text must also read on the shell's other surfaces, not only on control states.
    readonly property var textSurfaces: feedbackSurfaces.concat([palette.background ?? surface, palette.elevated ?? surface])

    readonly property color outline: Interaction.readable(Interaction.mix(palette.outline, palette.text, outlineTextMix),
        surface, Interaction.minimumStateContrast)
    readonly property color text: Interaction.readableText(palette.text, textSurfaces, textContrast)
    readonly property color muted: Interaction.readableText(palette.textMuted, textSurfaces, mutedContrast)
    readonly property color hoverText: Interaction.readableText(Interaction.mix(text, palette.accent, hoverTextMix), feedbackSurfaces, textContrast)

    // Filled primary action. `selection` is the same colour for marks and highlights.
    readonly property color primary: Interaction.readableOnSurfaces(palette.accent, [surface, hoverSurface], Interaction.minimumStateContrast)
    // States move the fill away from its content colour (darker under light
    // text, lighter under dark text), so contrast only grows as feedback deepens.
    readonly property bool darkOnPrimary: Interaction.contrast(primary, Interaction.darkForeground)
        >= Interaction.contrast(primary, Interaction.lightForeground)
    readonly property color primaryAnchor: darkOnPrimary ? Interaction.lightForeground : Interaction.darkForeground
    readonly property color primaryHover: layer(primary, primaryAnchor, hoverLayer)
    readonly property color primaryFocus: layer(primary, primaryAnchor, focusLayer + hoverLayer)
    readonly property color primaryPressed: layer(primary, primaryAnchor, pressedLayer + hoverLayer)
    readonly property color primaryText: Interaction.readableText(Interaction.onFill(primary, palette.accent),
        [primary, primaryHover, primaryFocus, primaryPressed], textContrast)
    readonly property color selection: primary
    readonly property color solidHover: primaryHover

    // Tonal container: selected rows, tiles and secondary-button selection.
    readonly property color container: Interaction.tonal(surface, palette.accent, containerShift, containerChroma)
    readonly property color containerHover: layer(container, palette.text, hoverLayer)
    readonly property color containerPressed: layer(container, palette.text, pressedLayer)
    readonly property var containerSurfaces: [container, containerHover, containerPressed]
    readonly property color containerText: Interaction.readableText(Interaction.mix(palette.text, palette.accent, activeTextMix), containerSurfaces, textContrast)
    readonly property color selectionText: containerText

    // The committed item (applied wallpaper, active choice) in the positive hue.
    readonly property color current: Interaction.readableOnSurfaces(palette.positive,
        [surface, hoverSurface, currentContainer], Interaction.minimumStateContrast)
    readonly property color currentContainer: Interaction.tonal(surface, palette.positive, currentShift, currentChroma)
    readonly property color currentText: Interaction.readableText(Interaction.mix(palette.text, palette.positive, activeTextMix),
        [currentContainer, layer(currentContainer, palette.text, hoverLayer)], textContrast)

    readonly property color focus: Interaction.readableOnSurfaces(Interaction.mix(palette.focus, palette.text,
        Interaction.focusMix), [surface, hoverSurface], Interaction.minimumStateContrast)
    readonly property color focusText: text
    readonly property color hover: Interaction.readable(Interaction.mix(outline, primary,
        Interaction.hoverMix), hoverSurface, Interaction.minimumStateContrast)
    readonly property color pressed: primary
    readonly property color pressedText: containerText

    // Unavailable controls: a wash of the text colour, deliberately below the
    // readable roles so they cannot be mistaken for enabled ones.
    readonly property color disabledText: layer(surface, palette.text, disabledContent)
    readonly property color disabledSurface: layer(surface, palette.text, disabledContainer)
    readonly property color disabledBorder: layer(surface, palette.text, disabledContainer)

    // Every colour role a behaviour profile can name (see scripts/render-control-tuning).
    readonly property var roles: ({
        none: Interaction.transparentColor,
        surface: surface, hoverSurface: hoverSurface, focusSurface: focusSurface, pressedSurface: pressedSurface,
        container: container, containerHover: containerHover, containerPressed: containerPressed,
        currentContainer: currentContainer, disabledSurface: disabledSurface,
        primary: primary, primaryHover: primaryHover, primaryFocus: primaryFocus, primaryPressed: primaryPressed,
        text: text, hoverText: hoverText, muted: muted, containerText: containerText, currentText: currentText,
        disabledText: disabledText, primaryText: primaryText,
        outline: outline, focus: focus, hover: hover, current: current,
        disabledBorder: disabledBorder
    })

    function layer(base, tint, amount) { return Interaction.mix(base, tint, amount) }
}

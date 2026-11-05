import QtQuick
import QtQuick.Controls.Basic
import QtTest
import "../shell/theme" as Theme
import "theme-fixtures" as Fixtures

Item {
    id: root
    width: 320
    height: 160
    Fixtures.ImportedPalettes { id: fixtures }
    Component { id: colorsComponent; Theme.ControlColors {} }
    Component { id: probeComponent; Control {} }
    Component { id: applierComponent; Theme.ControlPalette {} }

    TestCase {
        name: "ControlColors"
        when: windowShown
        function test_readableRolePairs_data() { return fixtures.items }
        function test_readableRolePairs(data) {
            const colors = createTemporaryObject(colorsComponent, root, { palette: data })
            verify(!!colors, "Component exists")
            const I = Theme.Interaction
            function readableOn(foreground, surfaces, label) {
                for (const surface of surfaces)
                    verify(I.contrast(foreground, surface) >= I.minimumTextContrast, label + " " + foreground + " on " + surface + " = " + I.contrast(foreground, surface))
            }
            readableOn(colors.text, colors.textSurfaces, "text")
            readableOn(colors.muted, colors.textSurfaces, "muted")
            readableOn(colors.hoverText, colors.feedbackSurfaces, "hoverText")
            readableOn(colors.containerText, colors.containerSurfaces, "containerText")
            readableOn(colors.currentText, [colors.currentContainer], "currentText")
            readableOn(colors.primaryText, [colors.primary, colors.primaryHover, colors.primaryFocus, colors.primaryPressed], "primaryText")
            for (let step = 1; step < 4; step++) {
                readableOn(colors.text, [I.mix(colors.surface, colors.hoverSurface, step / 4),
                    I.mix(colors.pressedSurface, colors.surface, step / 4)], "transition")
            }
            verify(I.contrast(colors.outline, colors.surface) >= I.minimumStateContrast)
            for (const color of [colors.primary, colors.current, colors.focus]) {
                verify(I.contrast(color, colors.surface) >= I.minimumStateContrast)
                verify(I.contrast(color, colors.hoverSurface) >= I.minimumStateContrast)
            }
            compare(colors.surface, data.surface)
        }
        function test_statesAreDistinguishable_data() { return fixtures.items }
        function test_statesAreDistinguishable(data) {
            const colors = createTemporaryObject(colorsComponent, root, { palette: data })
            const I = Theme.Interaction
            const step = 0.012
            // Neutral state layers separate from rest and from each other.
            const layers = [colors.surface, colors.hoverSurface, colors.focusSurface, colors.pressedSurface]
            for (let i = 1; i < layers.length; i++)
                verify(I.distance(layers[i - 1], layers[i]) > step * 0.5, "layer " + i + " visible against the previous")
            verify(I.distance(colors.surface, colors.pressedSurface) > step)
            // Selection and the committed marker are fills, clearly not the resting surface.
            verify(I.distance(colors.container, colors.surface) > 0.025, "selected container distinct from surface")
            verify(I.distance(colors.currentContainer, colors.surface) > 0.015, "current container distinct from surface")
            verify(I.distance(colors.container, colors.currentContainer) > 0.015, "selected differs from current")
            // A primary action changes visibly on every interaction.
            for (const color of [colors.primaryHover, colors.primaryFocus, colors.primaryPressed])
                verify(I.distance(colors.primary, color) > step)
            verify(I.distance(colors.primaryFocus, colors.primaryPressed) > step * 0.5)
            // Disabled is a fade: below muted text, and its container is not a state colour.
            verify(I.contrast(colors.disabledText, colors.surface) < I.contrast(colors.muted, colors.surface))
            verify(I.distance(colors.disabledText, colors.text) > 0.1)
            verify(I.distance(colors.disabledText, colors.muted) > 0.05)
            // Engagement ladder: hover text must not read like pressed/selected text.
            verify(I.distance(colors.hoverText, colors.containerText) > 0.02, "hover and active text differ")
            verify(I.distance(colors.text, colors.hoverText) > 0.003, "hover text differs from rest")
            verify(I.distance(colors.disabledSurface, colors.container) > step)
        }
        function test_contentKeepsItsHue_data() { return fixtures.items }
        function test_contentKeepsItsHue(data) {
            const colors = createTemporaryObject(colorsComponent, root, { palette: data })
            const I = Theme.Interaction
            // Content on a coloured fill carries the accent hue instead of pure black or white.
            const accent = I.toOklch(data.accent)
            const content = I.toOklch(colors.primaryText)
            if (accent.c > 0.08 && content.l > 0.05 && content.l < 0.97)
                verify(content.c > 0.003, "primaryText keeps a trace of the accent hue")
            verify(!Qt.colorEqual(colors.primaryText, "#000000") || content.l < 0.01)
        }
        function test_textAimsForAAAWhenTheHueAllows_data() { return fixtures.items }
        function test_textAimsForAAAWhenTheHueAllows(data) {
            const colors = createTemporaryObject(colorsComponent, root, { palette: data })
            const I = Theme.Interaction
            // Body text is the strongest content; muted text sits at the floor below it.
            verify(I.contrast(colors.text, colors.surface) >= I.contrast(colors.muted, colors.surface))
            verify(I.contrast(colors.text, colors.surface) >= I.preferredTextContrast
                || I.contrast(data.text, data.surface) < I.preferredTextContrast
                || I.contrast(colors.text, colors.surface) >= I.minimumTextContrast)
        }
        function test_tuningOverridesAmounts() {
            const base = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const tuned = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0],
                tuning: { hoverLayer: 0.2, containerShift: 0.16, textContrast: 4.5 } })
            compare(tuned.hoverLayer, 0.2)
            compare(base.hoverLayer, Theme.Interaction.hoverLayer)
            verify(Theme.Interaction.distance(tuned.surface, tuned.hoverSurface)
                > Theme.Interaction.distance(base.surface, base.hoverSurface))
            verify(Theme.Interaction.distance(tuned.surface, tuned.container)
                > Theme.Interaction.distance(base.surface, base.container))
            verify(Theme.Interaction.contrast(tuned.text, tuned.surface) >= 4.5)
        }
        function test_unknownTuningKeyIsAnError() {
            ignoreWarning(/unknown tuning key 'hoverLayr'/)
            const tuned = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0], tuning: { hoverLayr: 0.2 } })
            // The failing binding leaves the amount at its invalid default instead of silently using the typo.
            verify(!tuned || tuned.hoverLayer !== 0.2)
        }
        function test_explicitToneAdjustment() {
            const adjusted = Theme.Interaction.readable("#aaaaaa", "#ffffff", Theme.Interaction.minimumTextContrast)
            verify(Theme.Interaction.contrast(adjusted, "#ffffff") >= Theme.Interaction.minimumTextContrast)
            verify(!Qt.colorEqual(adjusted, "#aaaaaa"))
            compare(Theme.Interaction.readable("#000000", "#ffffff", Theme.Interaction.minimumTextContrast), "#000000")
        }
        function test_qtPaletteThemesQtDefaultControls_data() { return fixtures.items }
        function test_qtPaletteThemesQtDefaultControls(data) {
            const colors = createTemporaryObject(colorsComponent, root, { palette: data })
            const control = createTemporaryObject(probeComponent, root)
            verify(!!control, "Probe control exists")
            // Both inputs are passed at creation, so no binding sees a missing value.
            verify(!!createTemporaryObject(applierComponent, control, { palette: control.palette, colors: colors }))
            const qt = control.palette
            verify(Qt.colorEqual(qt.window, colors.surface))
            verify(Qt.colorEqual(qt.disabled.text, colors.disabledText), "disabled menu entries fade " + qt.disabled.text + " want " + colors.disabledText + " enabled " + qt.text)
            verify(!Qt.colorEqual(qt.disabled.text, qt.text))
            verify(Qt.colorEqual(qt.windowText, colors.text))
            verify(Qt.colorEqual(qt.dark, colors.outline))
            // Menu text is drawn on the window, highlighted (light) and pressed (midlight) items.
            for (const surface of [qt.window, qt.light, qt.midlight])
                verify(Theme.Interaction.contrast(qt.windowText, surface) >= Theme.Interaction.minimumTextContrast)
        }
    }
}

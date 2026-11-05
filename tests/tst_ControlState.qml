import QtQuick
import QtTest
import "../shell/theme" as Theme

Item {
    id: root
    width: 200
    height: 200

    QtObject {
        id: darkPalette
        readonly property Theme.ControlColors controls: Theme.ControlColors { palette: darkPalette }
        readonly property color accent: "#c5bfff"
        readonly property color positive: "#e8b9d4"
        readonly property color text: "#f1eef8"
        readonly property color textMuted: "#b8b4c0"
        readonly property color surface: "#1b1b21"
        readonly property color background: "#101014"
        readonly property color focus: "#c5bfff"
        readonly property color outline: "#8c8894"
    }
    QtObject {
        id: lightPalette
        readonly property Theme.ControlColors controls: Theme.ControlColors { palette: lightPalette }
        readonly property color accent: "#574295"
        readonly property color positive: "#80516c"
        readonly property color text: "#1d1928"
        readonly property color textMuted: "#514b5f"
        readonly property color surface: "#f9f6ff"
        readonly property color background: "#efebf7"
        readonly property color focus: "#574295"
        readonly property color outline: "#797181"
    }
    Component {
        id: stateComponent
        Theme.ControlState {}
    }

    TestCase {
        name: "ControlState"
        when: windowShown

        function snapshot(color) { return Qt.rgba(color.r, color.g, color.b, color.a) }

        function test_precedence_data() {
            return [{ tag: "outline", emphasis: "outline" },
                { tag: "solid", emphasis: "solid" }]
        }
        function test_precedence(data) {
            const state = createTemporaryObject(stateComponent, root, { colors: darkPalette.controls, emphasis: data.emphasis })
            verify(!!state, "Component exists")
            compare(state.state, "normal")
            state.hovered = true
            compare(state.state, "hover")
            state.current = true
            compare(state.state, "current")
            state.focused = true
            compare(state.state, "focus")
            state.selected = true
            compare(state.state, "select")
            state.pressed = true
            compare(state.state, "pressed")
            state.enabled = false
            compare(state.state, "disabled")
        }

        function test_everyStateRecolorsTheFill_data() {
            return [{ tag: "dark-outline", palette: darkPalette, emphasis: "outline" },
                { tag: "light-outline", palette: lightPalette, emphasis: "outline" },
                { tag: "dark-solid", palette: darkPalette, emphasis: "solid" },
                { tag: "light-solid", palette: lightPalette, emphasis: "solid" }]
        }
        function test_everyStateRecolorsTheFill(data) {
            const state = createTemporaryObject(stateComponent, root, { colors: data.palette.controls, emphasis: data.emphasis })
            verify(!!state, "Component exists")
            const I = Theme.Interaction
            const rest = snapshot(state.fill)
            const seen = {}
            // Selection and keyboard focus are fills, not just borders.
            for (const name of ["hovered", "focused", "current", "selected", "pressed"]) {
                state[name] = true
                verify(I.distance(rest, state.fill) > 0.006, name + " changes the fill")
                verify(I.contrast(state.foreground, state.fill) >= I.minimumTextContrast, name + " keeps text readable")
                seen[name] = snapshot(state.fill)
                state[name] = false
            }
            if (data.emphasis === "outline")
                verify(I.distance(seen.selected, data.palette.surface) > 0.025, "selected row is a tonal container")
            state.enabled = false
            verify(I.contrast(state.foreground, state.fill) < I.contrast(data.palette.controls.muted, state.fill),
                "disabled content is fainter than muted text")
            compare(state.foreground, state.colors.disabledText)
        }

        function test_primaryActionIsFilled_data() {
            return [{ tag: "dark", palette: darkPalette }, { tag: "light", palette: lightPalette }]
        }
        function test_primaryActionIsFilled(data) {
            const state = createTemporaryObject(stateComponent, root, { colors: data.palette.controls, emphasis: "solid" })
            const colors = data.palette.controls
            compare(state.fill, colors.primary)
            compare(state.foreground, colors.primaryText)
            state.hovered = true
            compare(state.fill, colors.primaryHover)
            state.focused = true
            compare(state.fill, colors.primaryFocus)
            // The ring contrasts with the surface even when it matches the fill.
            compare(state.border, colors.primaryText)
            state.focused = false
            compare(state.border, colors.primary)
            state.selected = true
            compare(state.fill, colors.primaryPressed)
            compare(state.border, colors.primary)
            state.enabled = false
            compare(state.fill, colors.disabledSurface)
            compare(state.foreground, colors.disabledText)
            verify(!Qt.colorEqual(state.fill, colors.primary))
        }

        function test_selectionUsesTonalContainer_data() {
            return [{ tag: "dark", palette: darkPalette }, { tag: "light", palette: lightPalette }]
        }
        function test_selectionUsesTonalContainer(data) {
            const colors = data.palette.controls
            const state = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline", selected: true })
            compare(state.fill, colors.container)
            compare(state.foreground, colors.containerText)
            compare(state.border, colors.outline)
            // Focus joins selection without changing its fill and adds the ring;
            // hover only lifts the container.
            state.focused = true
            compare(state.fill, colors.container)
            compare(state.border, colors.focus)
            state.hovered = true
            compare(state.fill, colors.containerHover)
            state.pressed = true
            compare(state.fill, colors.containerPressed)
            compare(state.border, colors.focus)
            compare(state.borderWidth, Theme.Shape.borderWidth)
        }

        function test_currentUsesThemePositive_data() {
            return [{ tag: "dark", palette: darkPalette }, { tag: "light", palette: lightPalette }]
        }
        function test_currentUsesThemePositive(data) {
            const colors = data.palette.controls
            const state = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline", current: true })
            compare(state.fill, colors.currentContainer)
            compare(state.foreground, colors.currentText)
            compare(state.border, colors.outline)
            verify(!Qt.colorEqual(state.fill, colors.container))
            verify(Theme.Interaction.contrast(colors.current, colors.surface) >= Theme.Interaction.minimumStateContrast)
        }

        function test_borderIsOnlyTheFocusRing_data() {
            return [{ tag: "dark-outline", palette: darkPalette, emphasis: "outline" },
                { tag: "light-outline", palette: lightPalette, emphasis: "outline" },
                { tag: "dark-solid", palette: darkPalette, emphasis: "solid" },
                { tag: "light-solid", palette: lightPalette, emphasis: "solid" }]
        }
        function test_borderIsOnlyTheFocusRing(data) {
            const state = createTemporaryObject(stateComponent, root, { colors: data.palette.controls, emphasis: data.emphasis })
            const rest = snapshot(state.border)
            // Pointer and selection states never touch the perimeter colour.
            for (const name of ["hovered", "current", "selected", "pressed"]) {
                state[name] = true
                verify(Qt.colorEqual(state.border, rest), name + " leaves the border alone")
                state[name] = false
            }
            state.focused = true
            verify(!Qt.colorEqual(state.border, rest), "focus draws the ring")
            // An outlined ring reads against the surface; a filled control's ring reads against its own fill.
            verify(Theme.Interaction.contrast(state.border, data.emphasis === "solid" ? state.fill : data.palette.surface)
                >= Theme.Interaction.minimumStateContrast, "focus ring is visible")
            state.enabled = false
            compare(state.border, state.colors.disabledBorder)
        }

        function test_behaviorProfileDrivesEveryChannel() {
            const colors = darkPalette.controls
            // A profile is data: here select is a border-only state painted in the primary.
            const profile = JSON.parse(JSON.stringify(Theme.ControlTuning.behavior))
            profile.families.outline.states.select = { fill: "surface", fg: "containerText", border: "primary" }
            const state = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline", behavior: profile })
            state.selected = true
            compare(state.fill, colors.surface)
            compare(state.foreground, colors.containerText)
            compare(state.border, colors.primary)
            profile.flags.focusRing = false
            const noRing = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline",
                behavior: profile, focused: true })
            compare(noRing.border, colors.outline, "focus ring switched off")
        }

        function test_modeFlagsChangeBehaviourNotJustColour() {
            const colors = darkPalette.controls
            function profileFor(key) { return Theme.ControlTuning.modes.find(mode => mode.key === key).behavior }
            const cursor = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline",
                behavior: profileFor("cursor"), hovered: true })
            compare(cursor.state, "normal", "cursor mode ignores pointer hover")
            compare(cursor.fill, colors.surface)
            const tonal = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline",
                behavior: profileFor("tonal"), hovered: true })
            compare(tonal.state, "hover")
            const hush = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline", behavior: profileFor("hush") })
            compare(hush.border.a, 0, "hush has no resting border")
            compare(hush.markerColor.a, 0, "hush draws no applied marker")
            const ink = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline",
                behavior: profileFor("ink"), selected: true })
            compare(ink.border, colors.primary, "ink outlines a selection")
            const wash = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "outline",
                behavior: profileFor("wash"), selected: true })
            compare(wash.border.a, 0, "wash selection has no border")
        }

        function test_distinctColors_data() {
            return [{ tag: "dark", palette: darkPalette }, { tag: "light", palette: lightPalette }]
        }
        function test_distinctColors(data) {
            const state = createTemporaryObject(stateComponent, root, { colors: data.palette.controls, emphasis: "outline" })
            const colors = [state.selectedColor, state.currentColor, state.hoverColor, state.focusedColor]
            for (let first = 0; first < colors.length; first++) {
                compare(colors[first].a, 1)
                for (let second = first + 1; second < colors.length; second++)
                    verify(!Qt.colorEqual(colors[first], colors[second]))
            }
        }

        function test_flatHasNoRestingBorder() {
            const colors = darkPalette.controls
            const state = createTemporaryObject(stateComponent, root, { colors: colors, emphasis: "flat" })
            compare(state.border.a, 0)
            state.hovered = true
            state.selected = true
            compare(state.border.a, 0)
            compare(state.fill, colors.containerHover)
            state.focused = true
            compare(state.border, colors.focus)
            state.enabled = false
            compare(state.border.a, 0)
        }

        function test_borderWidthNeverChanges() {
            for (const emphasis of ["outline", "solid"]) {
                const state = createTemporaryObject(stateComponent, root, { colors: darkPalette.controls, emphasis: emphasis })
                for (const name of ["hovered", "focused", "current", "selected", "pressed"]) {
                    state[name] = true
                    compare(state.borderWidth, Theme.Shape.borderWidth)
                }
                state.enabled = false
                compare(state.borderWidth, Theme.Shape.borderWidth)
            }
        }
    }
}

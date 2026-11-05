import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme
import "theme-fixtures" as Fixtures

Item {
    id: root
    width: 840
    height: 100
    Rectangle { anchors.fill: parent; color: Theme.Style.surfaceRaised; z: -1 }
    Fixtures.ImportedPalettes { id: fixtures }
    Controls.InputState { id: input; pointerActive: false }
    QtObject {
        id: fakeStore
        property bool ready: true
        property bool busy: false
        property string error: ""
        property var savedValues: null
        signal saved()
        property string savedMode: ""
        function save(mode, values) { savedMode = mode; savedValues = values }
    }
    Component { id: colorsComponent; Theme.ControlColors {} }
    Component { id: stateComponent; Theme.ControlState {} }
    Component {
        id: editorComponent
        Controls.ControlTuningEditor {
            width: 800
            style: Theme.Style
            inputState: input
            store: fakeStore
        }
    }

    TestCase {
        name: "ControlTuning"
        when: windowShown
        function cleanup() {
            Theme.ControlTuning.draft = ({})
            Theme.ControlTuning.draftMode = ""
            Theme.ControlTuning.overrides = ({})
        }

        function test_schemaIsTheSingleSourceOfDefaults() {
            const tuning = Theme.ControlTuning
            verify(tuning.schema.length >= 10)
            for (const knob of tuning.schema) {
                verify(knob.min < knob.max && knob.step > 0, knob.key + " has a usable range")
                verify(knob.default >= knob.min && knob.default <= knob.max, knob.key + " default is in range")
                compare(tuning.defaults[knob.key], knob.default)
                compare(tuning.values[knob.key], knob.default)
                verify(knob.group.length > 0 && knob.label.length > 0 && knob.description.length > 0)
            }
            // Interaction no longer owns the numbers: it reads them from the model.
            compare(Theme.Interaction.hoverLayer, tuning.defaults.hoverLayer)
            compare(Theme.Interaction.preferredTextContrast, tuning.defaults.textContrast)
        }

        function test_layersCombineDefaultsSavedAndDraft() {
            const tuning = Theme.ControlTuning
            tuning.overrides = { hoverLayer: 0.2, focusLayer: 0.2 }
            compare(tuning.values.hoverLayer, 0.2)
            compare(tuning.values.pressedLayer, tuning.defaults.pressedLayer)
            tuning.draft = { hoverLayer: 0.25 }
            compare(tuning.values.hoverLayer, 0.25, "draft wins over saved")
            compare(tuning.values.focusLayer, 0.2, "saved still applies beneath the draft")
            tuning.draft = ({})
            compare(tuning.values.hoverLayer, 0.2)
        }

        function test_draftRecolorsControlsLive() {
            const colors = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const before = Theme.Interaction.distance(colors.surface, colors.hoverSurface)
            const containerBefore = Theme.Interaction.distance(colors.surface, colors.container)
            Theme.ControlTuning.draft = { hoverLayer: 0.28, containerShift: 0.22 }
            verify(Theme.Interaction.distance(colors.surface, colors.hoverSurface) > before, "hover layer follows the draft")
            verify(Theme.Interaction.distance(colors.surface, colors.container) > containerBefore, "container follows the draft")
            Theme.ControlTuning.draft = ({})
            fuzzyCompare(Theme.Interaction.distance(colors.surface, colors.hoverSurface), before, 0.0001)
        }

        function test_editorBuildsOneSliderPerSchemaKnobAndPreviewsLive() {
            const editor = createTemporaryObject(editorComponent, root)
            verify(!!editor, "editor exists")
            editor.begin()
            for (const knob of Theme.ControlTuning.schema)
                verify(!!findChild(editor, "tuning-" + knob.key), "slider for " + knob.key)
            const slider = findChild(editor, "tuning-hoverLayer")
            const colors = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const before = colors.hoverLayer
            editor.setValue(Theme.ControlTuning.schema.find(knob => knob.key === "hoverLayer"), 0.2)
            compare(Theme.ControlTuning.draft.hoverLayer, 0.2)
            compare(colors.hoverLayer, 0.2, "controls recolour while the slider moves")
            verify(before !== 0.2)
            editor.reset()
            compare(Theme.ControlTuning.draft.hoverLayer, Theme.ControlTuning.defaults.hoverLayer)
            verify(!editor.modified)
            editor.discard()
            compare(Object.keys(Theme.ControlTuning.draft).length, 0, "closing drops the unsaved draft")
        }

        function test_savesEditorPicture() {
            const editor = createTemporaryObject(editorComponent, root, { x: 10, y: 10 })
            editor.begin()
            root.height = editor.implicitHeight + 40
            wait(150)
            let saved = false
            verify(root.grabToImage(result => { saved = result.saveToFile("/artifacts/build/tests/gallery/tuning-editor.png") }))
            tryVerify(() => saved, 5000)
        }

        function test_modesAreValidPresetsOverTheSchema() {
            const tuning = Theme.ControlTuning
            verify(tuning.modes.length >= 4)
            compare(tuning.modes[0].key, tuning.mode, "the first mode is the default")
            compare(Object.keys(tuning.modes[0].values).length, 0, "the default mode overrides nothing")
            for (const mode of tuning.modes) {
                verify(mode.label.length > 0 && mode.description.length > 0)
                for (const key of Object.keys(mode.values)) {
                    const knob = tuning.schema.find(entry => entry.key === key)
                    verify(!!knob, mode.key + " names a known knob: " + key)
                    verify(mode.values[key] >= knob.min && mode.values[key] <= knob.max, mode.key + "." + key + " is in range")
                }
            }
        }

        function test_everyModeKeepsTextReadableOnEveryPalette_data() {
            const rows = []
            for (const palette of fixtures.items)
                for (const mode of Theme.ControlTuning.modes)
                    rows.push({ tag: palette.tag + "/" + mode.key, palette: palette, mode: mode.key })
            return rows
        }
        function test_everyModeKeepsTextReadableOnEveryPalette(data) {
            Theme.ControlTuning.draft = Theme.ControlTuning.presetValues(data.mode)
            const colors = createTemporaryObject(colorsComponent, root, { palette: data.palette })
            const I = Theme.Interaction
            for (const surface of colors.textSurfaces)
                verify(I.contrast(colors.text, surface) >= I.minimumTextContrast, "text")
            for (const surface of colors.containerSurfaces)
                verify(I.contrast(colors.containerText, surface) >= I.minimumTextContrast, "container text")
            verify(I.contrast(colors.currentText, colors.currentContainer) >= I.minimumTextContrast, "current text")
            verify(I.contrast(colors.primaryText, colors.primary) >= I.minimumTextContrast, "primary text")
            verify(I.distance(colors.surface, colors.pressedSurface) > 0.008, "pressed is visible")
            Theme.ControlTuning.draft = ({})
        }

        function test_everyModeProfileResolvesToRealColours() {
            const colors = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            for (const mode of Theme.ControlTuning.modes) {
                verify(mode.behavior.flags !== undefined, mode.key + " has flags")
                for (const family of ["outline", "solid"])
                    for (const state of ["normal", "hover", "focus", "select", "current", "pressed", "disabled"]) {
                        const spec = mode.behavior.families[family].states[state]
                        verify(!!spec, mode.key + "." + family + "." + state + " is declared")
                        for (const channel of ["fill", "fg", "border"])
                            verify(spec[channel] === "rest" || colors.roles[spec[channel]] !== undefined,
                                mode.key + "." + family + "." + state + "." + channel + " names a real role: " + spec[channel])
                    }
            }
        }

        function test_vocabularyIsExactlyWhatControlColorsProvides() {
            const colors = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const vocabulary = Theme.GeneratedControlTuning.vocabulary
            const named = new Set([].concat(vocabulary.fill, vocabulary.fg, vocabulary.border))
            for (const role of named)
                verify(role === "rest" || colors.roles[role] !== undefined, "ControlColors provides " + role)
            // And nothing is provided that no profile may name: one vocabulary, one provider.
            for (const role of Object.keys(colors.roles))
                verify(named.has(role), "vocabulary names provided role " + role)
        }

        function test_aSurfaceCanFollowItsOwnMode() {
            const global = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const bar = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0], mode: "cursor" })
            compare(global.behavior.flags.hover, "pointer")
            compare(bar.behavior.flags.hover, "none", "the bar's own mode drives its behaviour")
            compare(bar.focusLayer, Theme.ControlTuning.modes.find(entry => entry.key === "cursor").values.focusLayer,
                "and its numeric preset")
            const tuned = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0], mode: "cursor", tuning: { focusLayer: 0.02 } })
            compare(tuned.focusLayer, 0.02, "per-style tuning still wins over the mode")
            const state = createTemporaryObject(stateComponent, root, { colors: bar, emphasis: "outline", hovered: true })
            compare(state.state, "normal")
            state.destroy()
        }

        function test_previewedModeChangesWhatControlsDo() {
            const colors = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            const state = createTemporaryObject(stateComponent, root,
                { colors: colors, emphasis: "outline", hovered: true })
            compare(state.state, "hover")
            Theme.ControlTuning.draftMode = "cursor"
            compare(state.state, "normal", "previewing cursor mode silences hover live")
            Theme.ControlTuning.draftMode = ""
            compare(state.state, "hover")
            state.destroy()
        }

        function test_modeSwitchPreviewsAndSavesWithItsName() {
            const editor = createTemporaryObject(editorComponent, root)
            editor.begin()
            editor.applyMode("wash")
            compare(editor.draftMode, "wash")
            compare(Theme.ControlTuning.draft.containerChroma, 0)
            verify(!editor.modified)
            editor.setValue(Theme.ControlTuning.schema.find(knob => knob.key === "hoverLayer"), 0.2)
            verify(editor.modified, "a slider move marks the mode modified")
            editor.save()
            compare(fakeStore.savedMode, "wash")
            editor.discard()
        }

        function test_saveHandsTheDraftToTheStore() {
            const editor = createTemporaryObject(editorComponent, root)
            editor.begin()
            editor.setValue(Theme.ControlTuning.schema.find(knob => knob.key === "containerShift"), 0.15)
            editor.save()
            verify(fakeStore.savedValues !== null)
            compare(fakeStore.savedValues.containerShift, 0.15)
            verify(editor.committing)
            // The store confirming the write closes the draft and signals the popup.
            let closed = false
            editor.saved.connect(() => { closed = true })
            fakeStore.saved()
            verify(closed)
            compare(Object.keys(Theme.ControlTuning.draft).length, 0)
        }

        function test_perStyleTuningStillWinsOverTheModel() {
            Theme.ControlTuning.overrides = { hoverLayer: 0.2 }
            const styled = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0], tuning: { hoverLayer: 0.05 } })
            compare(styled.hoverLayer, 0.05)
            const plain = createTemporaryObject(colorsComponent, root, { palette: fixtures.items[0] })
            compare(plain.hoverLayer, 0.2)
        }

        function test_everyKnobKeepsTheContrastFloor_data() {
            const rows = []
            for (const palette of fixtures.items.slice(0, 6))
                rows.push({ tag: palette.tag, palette: palette })
            return rows
        }
        function test_everyKnobKeepsTheContrastFloor(data) {
            // Extreme but legal values must never break the readable-text guarantee.
            const extremes = {}
            for (const knob of Theme.ControlTuning.schema) extremes[knob.key] = knob.max
            for (const draft of [extremes, (function() {
                const lows = {}
                for (const knob of Theme.ControlTuning.schema) lows[knob.key] = knob.min
                return lows })()]) {
                Theme.ControlTuning.draft = draft
                const colors = createTemporaryObject(colorsComponent, root, { palette: data.palette })
                const I = Theme.Interaction
                for (const surface of colors.textSurfaces)
                    verify(I.contrast(colors.text, surface) >= I.minimumTextContrast, "text readable on " + surface)
                for (const surface of colors.containerSurfaces)
                    verify(I.contrast(colors.containerText, surface) >= I.minimumTextContrast, "container text readable")
                Theme.ControlTuning.draft = ({})
            }
        }
    }
}

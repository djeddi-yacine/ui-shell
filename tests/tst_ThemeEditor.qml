import QtQuick
import QtTest
import "../shell/modules/themes" as Themes
import "../shell/components" as Controls
import "../shell/config" as Config
import "../shell/theme" as Theme

Item {
    id: root
    width: 760
    height: 720
    readonly property string outputName: "__DRAFT_TEST_OUTPUT__"
    readonly property var profileColors: Config.GeneratedRuntime.profileColors
    function paletteForOutput(name) {
        return Object.prototype.hasOwnProperty.call(profileColors.byOutput, name)
            ? profileColors.byOutput[name] : profileColors.defaultPalette
    }
    Controls.InputState { id: input; pointerActive: false }
    Component {
        id: editorComponent
        Themes.ThemeEditor {
            width: 700
            height: 640
            style: Theme.Style
            inputState: input
            screenName: root.outputName
            profileModel: model
            property QtObject model: QtObject {
                property var snapshot: null
                property bool snapshotReady: false
                property bool busy: false
                property string operation: ""
                property var wallpaperSelection: null
                property int reads: 0
                property string loadedProfile: ""
                property string loadedPalette: ""
                property bool requestedWallpaperColors: false
                property var savedDraft: null
                signal ready()
                signal paletteReady(var palette)
                signal committed()
                signal failed(var failure)
                function refresh(wallpaperColors = false) {
                    requestedWallpaperColors = wallpaperColors
                    snapshotReady = false
                    reads += 1
                }
                function loadProfile(path) { loadedProfile = path; refresh() }
                function readPalette(path) { loadedPalette = path }
                function save(id, output, source, mode, colorData, writeDefinition, definitionPath) {
                    savedDraft = { id: id, output: output, source: source,
                        mode: mode, colors: Object.assign({}, colorData,
                            { colors: Object.assign({}, colorData.colors), hyprland: Object.assign({}, colorData.hyprland) }),
                        wallpaper: Object.assign({}, wallpaperSelection),
                        writeDefinition: writeDefinition, definitionPath: definitionPath }
                }
            }
        }
    }
    SignalSpy { id: backSpy; signalName: "back" }
    TestCase {
        name: "ThemeEditor"
        when: windowShown
        function selection(name) {
            return { id: root.outputName, folderId: "project", name: name,
                path: String(Qt.resolvedUrl("../wallpapers/" + name)).replace(/^file:\/\//, ""), fitMode: "cover" }
        }
        function publish(editor, chosen, source, accent) {
            const colors = Object.assign({}, root.profileColors.defaultPalette, {
                schema: 2,
                accent: accent,
                colors: Object.assign({}, root.profileColors.defaultPalette.colors, {
                    bright_background: "#123456", custom_token: "#abcdef"
                }),
                hyprland: { active_border: "rgba(112233ff) rgba(aabbccff) 45deg",
                    inactive_border: "rgba(445566ff)" }
            })
            editor.profileModel.snapshot = { profileId: "default", profilePath: "/profiles/default/profile.ini",
                source: source, definition: "", definitionOverrides: {},
                defaultPalette: colors, byOutput: {}, baseRevision: "test-revision",
                draftWallpaper: Object.assign({}, chosen, { colors: colors }),
                profiles: [{ id: "default", label: qsTr("Default"), path: "/profiles/default/profile.ini" }],
                palettes: [{ id: "default", label: qsTr("Default"), path: "/themes/default/config.ini" }] }
            editor.profileModel.snapshotReady = true
            editor.profileModel.ready()
        }
        function loadedEditor(source) {
            const editor = createTemporaryObject(editorComponent, root)
            verify(!!editor, "Component exists")
            const chosen = selection("wallhaven-02.png")
            editor.begin(chosen)
            publish(editor, chosen, source, "#2468ac")
            if (source === "file") {
                choose(editor, "custom")
                editor.profileId = "custom-test"
                editor.customName = "custom-test"
            }
            return editor
        }
        function choose(editor, kind) {
            const choice = editor.sourceChoices.find(entry => entry.kind === kind)
            verify(!!choice, "Named source exists")
            editor.chooseSource(choice)
            return choice
        }
        function control(editor, name) {
            const item = findChild(editor, name)
            verify(!!item, "Object exists")
            return item
        }
        function test_beginReadsDraftWithoutChangingLiveColors() {
            const before = JSON.stringify(root.paletteForOutput(root.outputName))
            const editor = loadedEditor("wallpaper")
            compare(editor.profileModel.reads, 1)
            compare(editor.wallpaper.name, "wallhaven-02.png")
            compare(editor.colors.accent, "#2468ac")
            compare(editor.source, "wallpaper")
            compare(editor.targetOutput, root.outputName)
            verify(control(editor, "themeSourceChoice").activeFocus)
            verify(!control(editor, "themeName").visible)
            compare(findChild(editor, "themeProfileScope"), null)
            compare(findChild(editor, "themeProfileChoice"), null)
            compare(findChild(editor, "themePaletteBase"), null)
            compare(JSON.stringify(root.paletteForOutput(root.outputName)), before)
        }
        function test_sourceOffersSavedThemesWallpaperAndCustomOnly() {
            const editor = loadedEditor("wallpaper")
            compare(editor.sourceChoices.length, editor.profileModel.snapshot.palettes.length + Config.ThemeEditor.sources.length)
            compare(editor.sourceChoices.filter(choice => choice.kind !== "theme").map(choice => choice.id).sort(),
                ["custom", "wallpaper"])
            const theme = editor.sourceChoices.find(choice => choice.kind === "theme")
            compare(theme.id, "/themes/default/config.ini")
            verify(theme.path.length > 0)
        }
        function test_customCopiesPreviewAndRequiresAnExplicitName() {
            const editor = loadedEditor("wallpaper")
            const colors = JSON.stringify(editor.colors)
            choose(editor, "custom")
            compare(editor.sourceId, "custom")
            compare(editor.source, "file")
            compare(JSON.stringify(editor.colors), colors)
            verify(control(editor, "themeName").visible)
            verify(control(editor, "themePaletteMode").visible)
            compare(control(editor, "themeSave").enabled, false)
            editor.save()
            compare(editor.profileModel.savedDraft, null)
            editor.profileId = "my-theme"
            editor.customName = "my-theme"
            verify(control(editor, "themeSave").enabled)
            choose(editor, "wallpaper")
            verify(!control(editor, "themeName").visible)
            verify(!control(editor, "themePaletteMode").visible)
            verify(control(editor, "themeSourceChoice").activeFocus)
            choose(editor, "custom")
            compare(editor.profileId, "my-theme")
        }
        function test_editAndSaveRetainUntouchedPaletteTokensAndGradient() {
            const editor = loadedEditor("wallpaper")
            choose(editor, "custom")
            editor.edit("accent", "#fedcba")
            compare(editor.colors.colors.bright_background, "#123456")
            compare(editor.colors.colors.custom_token, "#abcdef")
            compare(editor.colors.hyprland.active_border, "rgba(112233ff) rgba(aabbccff) 45deg")
            editor.profileId = "lossless-theme"
            editor.customName = "lossless-theme"
            editor.save()
            compare(editor.profileModel.savedDraft.colors.schema, 2)
            compare(editor.profileModel.savedDraft.colors.colors.custom_token, "#abcdef")
            compare(editor.profileModel.savedDraft.colors.hyprland.active_border,
                "rgba(112233ff) rgba(aabbccff) 45deg")
            compare(editor.profileModel.savedDraft.colors.accent, "#fedcba")
        }
        function test_wallpaperAndSavedThemeColorsAreReadOnly() {
            const editor = loadedEditor("wallpaper")
            editor.edit("accent", "#fedcba")
            compare(editor.colors.accent, "#2468ac")
            const chosen = choose(editor, "theme")
            compare(editor.profileModel.loadedPalette, chosen.path)
            compare(editor.profileModel.loadedProfile, "")
            editor.profileModel.paletteReady(Object.assign({}, editor.colors, { accent: "#13579b" }))
            compare(editor.sourceId, chosen.id)
            compare(editor.source, "file")
            compare(editor.colors.accent, "#13579b")
            verify(!control(editor, "themeName").visible)
            editor.edit("accent", "#fedcba")
            compare(editor.colors.accent, "#13579b")
            choose(editor, "custom")
            editor.edit("accent", "#fedcba")
            compare(editor.colors.accent, "#fedcba")
        }
        function test_restartRestoresExactThemeForTargetWithoutReadingPalette() {
            const editor = loadedEditor("wallpaper")
            const saved = editor.profileModel.snapshot.palettes.find(theme => theme.id === "default")
            editor.profileModel.snapshot.source = "file"
            editor.profileModel.snapshot.definition = ""
            editor.profileModel.snapshot.definitionOverrides = { [root.outputName]: saved.path }
            editor.resetDraft()
            editor.profileModel.ready()
            compare(editor.sourceId, saved.path)
            compare(editor.definitionPath, saved.path)
            compare(control(editor, "themeSourceChoice").currentText, saved.label)
            compare(editor.profileModel.loadedPalette, "")
            compare(editor.colors.accent, "#2468ac")
            compare(editor.custom, false)
        }
        function test_wallpaperColorsAreRequestedOnlyWhenWallpaperIsChosen() {
            const editor = loadedEditor("file")
            editor.profileModel.snapshot.draftWallpaper.colors = null
            choose(editor, "wallpaper")
            compare(editor.profileModel.requestedWallpaperColors, true)
            compare(editor.profileModel.reads, 2)
            compare(editor.profileModel.snapshotReady, false)
            publish(editor, selection("wallhaven-02.png"), "file", "#13579b")
            compare(editor.sourceId, "wallpaper")
            compare(editor.colors.accent, "#13579b")
        }
        function test_backKeepsCustomDraftWhenReopened() {
            const editor = loadedEditor("wallpaper")
            choose(editor, "custom")
            editor.edit("accent", "#fedcba")
            editor.profileId = "custom-draft"
            editor.customName = "custom-draft"
            backSpy.target = editor
            backSpy.clear()
            control(editor, "themeDraftBack").forceActiveFocus()
            keyPress(Qt.Key_Return)
            keyRelease(Qt.Key_Return)
            tryCompare(backSpy, "count", 1)
            editor.begin(selection("wallhaven-02.png"))
            compare(editor.profileModel.reads, 1)
            compare(editor.profileId, "custom-draft")
            compare(editor.source, "file")
            compare(editor.colors.accent, "#fedcba")
        }
        function test_changedImageKeepsAuthoredColors() {
            const editor = loadedEditor("wallpaper")
            choose(editor, "custom")
            editor.edit("accent", "#fedcba")
            const next = selection("wallhaven-01.jpg")
            editor.begin(next)
            publish(editor, next, "wallpaper", "#13579b")
            compare(editor.profileModel.reads, 2)
            compare(editor.wallpaper.name, next.name)
            compare(editor.source, "file")
            compare(editor.colors.accent, "#fedcba")
        }
        function test_changedImageReplacesDerivedColors() {
            const editor = loadedEditor("wallpaper")
            const next = selection("wallhaven-01.jpg")
            editor.begin(next)
            publish(editor, next, "wallpaper", "#13579b")
            compare(editor.source, "wallpaper")
            compare(editor.colors.accent, "#13579b")
        }
        function test_failedReadRequiresRetryBeforeSave() {
            const editor = loadedEditor("file")
            editor.profileModel.snapshotReady = false
            compare(control(editor, "themeSave").enabled, false)
            compare(control(editor, "themeDraftBack").enabled, true)
            editor.begin(selection("wallhaven-02.png"))
            compare(editor.profileModel.reads, 2)
        }
        function test_failedThemeReadRestoresSourceNameAndColors() {
            const editor = loadedEditor("file")
            const prior = JSON.stringify(editor.colors)
            const priorName = editor.profileId
            choose(editor, "theme")
            editor.profileModel.snapshotReady = true
            editor.profileModel.failed({ operation: "palette" })
            compare(editor.source, "file")
            compare(editor.sourceId, "custom")
            compare(editor.profileId, priorName)
            verify(control(editor, "themeName").visible)
            compare(JSON.stringify(editor.colors), prior)
        }
        function test_failedThemeReadKeepsComboOnTheCandidateAndBlocksSave() {
            const editor = loadedEditor("file")
            const combo = control(editor, "themeSourceChoice")
            const theme = choose(editor, "theme")
            editor.profileModel.snapshotReady = true
            editor.profileModel.failed({ operation: "palette" })
            // The draft is the last valid one; the combo stays where the user moved it.
            compare(editor.sourceId, "custom")
            compare(editor.failedCandidateId, theme.id)
            verify(editor.sourceUnavailable)
            compare(combo.currentIndex, editor.sourceChoices.findIndex(entry => entry.id === theme.id))
            compare(control(editor, "themeSave").enabled, false)
            editor.save()
            compare(editor.profileModel.savedDraft, null)
            // Moving on to a source that loads clears the failure and re-enables Save.
            choose(editor, "wallpaper")
            verify(!editor.sourceUnavailable)
            compare(control(editor, "themeSave").enabled, true)
        }
        function test_keyboardCanStepPastAFailedCandidate() {
            const editor = loadedEditor("file")
            const combo = control(editor, "themeSourceChoice")
            const themeIndex = editor.sourceChoices.findIndex(entry => entry.kind === "theme")
            combo.forceActiveFocus()
            // Step up until the combo reaches the saved theme.
            for (let guard = 0; combo.currentIndex > themeIndex && guard < 8; guard++) {
                keyClick(Qt.Key_Up)
                editor.profileModel.snapshotReady = true
            }
            compare(combo.currentIndex, themeIndex)
            editor.profileModel.failed({ operation: "palette" })
            compare(combo.currentIndex, themeIndex)
            // The next key press moves on from the failed entry instead of snapping back.
            keyClick(Qt.Key_Down)
            verify(combo.currentIndex > themeIndex)
            verify(!editor.sourceUnavailable)
        }
        function test_enterSubmitsOneCombinedDraft() {
            const editor = loadedEditor("file")
            editor.profileId = "combined-draft"
            editor.edit("accent", "#fedcba")
            const save = control(editor, "themeSave")
            save.forceActiveFocus()
            keyPress(Qt.Key_Return)
            compare(editor.profileModel.savedDraft, null)
            keyRelease(Qt.Key_Return)
            tryVerify(() => editor.profileModel.savedDraft !== null)
            const saved = editor.profileModel.savedDraft
            compare(saved.id, "combined-draft")
            compare(saved.output, root.outputName)
            compare(saved.source, "file")
            compare(saved.writeDefinition, true)
            compare(saved.wallpaper.name, "wallhaven-02.png")
            compare(saved.colors.accent, "#fedcba")
            compare(saved.colors.schema, 2)
            compare(saved.colors.colors.custom_token, "#abcdef")
            compare(saved.colors.hyprland.active_border, "rgba(112233ff) rgba(aabbccff) 45deg")
        }
        function test_focusedControlsExplainTheirMeaning() {
            const editor = loadedEditor("file")
            for (const entry of [
                { name: "themeSourceChoice", title: qsTr("Source") },
                { name: "themeName", title: qsTr("Theme name") },
                { name: "themePaletteMode", title: qsTr("Palette mode") },
                { name: "themeDraftBack", title: qsTr("Back") },
                { name: "themeSave", title: qsTr("Save and apply") }
            ]) {
                control(editor, entry.name).forceActiveFocus()
                compare(editor.focusedInfo().title, entry.title)
                verify(editor.focusedInfo().description.length > 0)
            }
        }
    }
}

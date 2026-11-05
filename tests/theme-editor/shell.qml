//@ pragma ShellId ui-shell-theme-editor-test
pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "modules/wallpaper" as Wallpaper
import "components" as Controls
import "config" as Config
import "theme" as Theme

ShellRoot {
    id: root
    readonly property string requestedOutput: Quickshell.env("UI_SHELL_TEST_OUTPUT") || ""
    readonly property string requestedWallpaper: Quickshell.env("UI_SHELL_TEST_WALLPAPER") || ""
    readonly property var output: Quickshell.screens.find(screen => screen.name === requestedOutput)
    readonly property var panel: surface.panel
    readonly property var popup: panel ? panel.themeEditor : null
    readonly property var editor: popup ? popup.editor : null
    property string phase: "open"
    property double deadline: Date.now() + 60000
    property bool ticking: false
    property string originalProfile: ""
    property string originalColors: ""
    property string originalWallpaper: ""
    property string selectedWallpaper: ""
    property string chosenAccent: ""
    property string saveCommand: ""
    property string readCommand: ""
    property string failureDraft: ""
    property string diagnostic: ""
    property string readDiagnostic: ""
    property string capturePath: ""
    property string captureNext: ""
    readonly property int captureSettleMilliseconds: Number(Quickshell.env("UI_SHELL_TEST_FRAME_SETTLE_MS"))
    property Item interruptedFocus: null
    property Item readInterruptedFocus: null
    property string priorLiveColors: ""
    property string loadedProfilePath: ""
    property string liveBeforeFailure: ""
    property string committedWallpaper: ""
    property string committedColors: ""
    property string committedThemeId: ""

    Component.onCompleted: {
        Quickshell.watchFiles = Config.Config.watchSourceFiles
        if (Quickshell.env("HOME") !== "/home/test" || Quickshell.env("XDG_RUNTIME_DIR") !== "/run/test"
            || !requestedOutput || !requestedWallpaper || !Quickshell.env("UI_SHELL_TEST_FRAME_SETTLE_MS")
            || !Number.isInteger(captureSettleMilliseconds) || captureSettleMilliseconds < 0) {
            console.error("THEME_EDITOR_FAIL private HOME/runtime/output/wallpaper required")
            Qt.exit(1)
        }
    }
    Controls.InputState { id: input; pointerActive: false }
    Wallpaper.PickerSurface {
        id: surface
        modelData: root.output
        inputState: input
        TestCase { id: native; when: false }
        TextEdit { id: clipboard; visible: false; textFormat: TextEdit.PlainText }
    }
    function check(condition, message) { if (!condition) throw new Error(message) }
    function paletteSignature(palette) {
        return JSON.stringify({ mode: palette.mode,
            roles: Config.ThemeEditor.roles.map(role => ({ key: role.key, value: String(palette[role.key]) })) })
    }
    function draftSignature() {
        return JSON.stringify({ wallpaper: editor.wallpaper ? editor.wallpaper.path : "",
            colors: editor.colors, profileId: editor.profileId, sourceId: editor.sourceId,
            revision: popup.profileModel.snapshot.baseRevision })
    }
    function next(name) { phase = name; deadline = Date.now() + 60000 }
    function control(name) {
        const item = native.findChild(editor, name)
        check(!!item, "missing editor control: " + name)
        return item
    }
    function findHexForRole(item, roleKey) {
        if (item.objectName === "paletteHex" && item.parent && item.parent.role
            && item.parent.role.key === roleKey) return item
        for (const child of item.children || []) {
            const found = findHexForRole(child, roleKey)
            if (found) return found
        }
        return null
    }
    function chooseSource(id) {
        const choice = control("themeSourceChoice")
        const wanted = choice.model.findIndex(entry => entry.id === id)
        check(wanted >= 0, "missing named source: " + id)
        choice.forceActiveFocus()
        native.keyClick(Qt.Key_Space)
        check(choice.popup.visible, "Source menu did not open with Space")
        let steps = 0
        while (choice.highlightedIndex !== wanted && steps < choice.count) {
            native.keyClick(choice.highlightedIndex < wanted ? Qt.Key_Down : Qt.Key_Up)
            steps += 1
        }
        check(choice.highlightedIndex === wanted, "Source menu did not reach named choice: " + id)
        native.keyClick(Qt.Key_Return)
        check(editor.sourceId === id, "Source menu did not activate named choice: " + id)
    }
    function paste(field, value) {
        clipboard.text = value
        clipboard.selectAll()
        clipboard.copy()
        field.forceActiveFocus()
        field.selectAll()
        field.paste()
    }
    function checkEditorFits() {
        check(editor.implicitHeight <= popup.contentItem.height,
            "editor content needs scrolling: " + JSON.stringify({
                editorHeight: editor.implicitHeight, contentHeight: popup.contentItem.height,
                popupHeight: popup.height, popupImplicitHeight: popup.implicitHeight,
                editorWidth: editor.width, editorHeightActual: editor.height }))
        check(Math.abs(popup.contentItem.height - editor.implicitHeight) <= 1,
            "editor was stretched beyond its natural content height")
        const lastAction = control("themeSave")
        const lastPosition = lastAction.mapToItem(popup.contentItem, 0, 0)
        check(Math.abs(popup.contentItem.height - lastPosition.y - lastAction.height) <= 1,
            "editor leaves an empty gap below its primary action: " + JSON.stringify({
                contentHeight: popup.contentItem.height, actionY: lastPosition.y, actionHeight: lastAction.height }))
        for (const item of [control("themeSourceChoice"), control("themePalettePreview"),
            control("themeName"), control("themePaletteMode"), control("themeDraftBack"), control("themeSave")]) {
            if (!item.visible) continue
            const position = item.mapToItem(popup.contentItem, 0, 0)
            check(position.y >= 0 && position.y + item.height <= popup.contentItem.height,
                "editor control is clipped: " + item.objectName)
        }
        for (const role of Config.ThemeEditor.roles) {
            const field = findHexForRole(editor, role.key)
            check(field, "missing color role: " + role.key)
            const position = field.mapToItem(popup.contentItem, 0, 0)
            check(position.y >= 0 && position.y + field.height <= popup.contentItem.height,
                "color role is clipped: " + role.key)
        }
    }
    function openPicker() {
        Wallpaper.PickerState.targetOutput = output.name
        Wallpaper.PickerState.screenName = output.name
        Wallpaper.PickerState.open = true
        next("picker")
    }
    function captureFrame(path, nextPhase) {
        capturePath = path
        captureNext = nextPhase
        next("capture")
        frameSettle.start()
    }
    function advance() {
        check(Date.now() < deadline, "deadline exceeded: " + phase
            + ", operation=" + (popup ? popup.profileModel.operation : "no popup")
            + ", error=" + (popup && popup.errorPopup.visible ? popup.errorPopup.diagnostic : ""))
        if (!output) return
        if (phase === "capture") return
        if (phase === "open") { openPicker(); return }
        if (!panel || !panel.componentSettings.ready || !panel.wallpaperView) return
        if (phase === "picker") {
            const index = panel.filteredWallpapers.findIndex(item => item.path === requestedWallpaper)
            check(index >= 0, "requested wallpaper is missing from the private catalog")
            panel.choose(index)
            panel.moveSelection(0)
            selectedWallpaper = panel.selectedWallpaper.path
            check(selectedWallpaper === requestedWallpaper, "selected wallpaper did not match request")
            const chooseTheme = native.findChild(panel, "chooseTheme")
            check(chooseTheme, "picker theme advance control missing")
            chooseTheme.forceActiveFocus()
            native.keyClick(Qt.Key_Return)
            next("draft")
            return
        }
        if (phase === "draft") {
            if (!popup || !popup.opened || !editor.editable) return
            const snapshot = popup.profileModel.snapshot
            originalProfile = snapshot.profileId
            originalColors = paletteSignature(Theme.ActivePalettes.forOutput(output.name))
            originalWallpaper = Wallpaper.PickerState.savedPath(output.name)
            check(editor.wallpaper.path === selectedWallpaper && snapshot.draftWallpaper.path === selectedWallpaper,
                "draft did not retain selected wallpaper")
            check(snapshot.baseRevision !== undefined && snapshot.baseRevision !== "",
                "draft omitted its base revision")
            check(control("themeSourceChoice").activeFocus, "Source did not own opening focus")
            check(editor.targetOutput === output.name, "draft lost the picker's output target")
            check(!control("themeName").visible && !control("themePaletteMode").visible,
                "custom controls are visible for Wallpaper")
            for (const removed of ["themeProfileChoice", "themeProfileScope", "themePaletteBase", "themeEditColors"])
                check(!native.findChild(editor, removed), "removed editor control returned: " + removed)
            const choices = editor.sourceChoices
            check(choices.length === snapshot.palettes.length + Config.ThemeEditor.sources.length
                && choices.every(choice => ["theme", "wallpaper", "custom"].includes(choice.kind))
                && choices.some(choice => choice.id === "wallpaper") && choices.some(choice => choice.id === "custom"),
                "Source must contain saved themes, Wallpaper and Custom only")
            checkEditorFits()
            chooseSource("wallpaper")
            next("derived")
            return
        }
        if (phase === "derived") {
            // Choosing Wallpaper starts an asynchronous color read that disables
            // the Source control until the refreshed draft is ready.
            if (!editor.editable || !control("themeSourceChoice").enabled) return
            check(editor.sourceId === "wallpaper" && editor.source === "wallpaper",
                "wallpaper palette base was not selected")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === originalColors,
                "palette selection changed live colors")
            chooseSource("custom")
            next("editing")
            return
        }
        if (phase === "editing") {
            if (!editor.editable || !editor.custom) return
            check(control("themeName").visible && control("themePaletteMode").visible,
                "Custom did not reveal its name and mode controls")
            check(!control("themeSave").enabled, "unnamed Custom theme can be saved")
            checkEditorFits()
            check(editor.mode === "dark" || editor.mode === "light",
                "palette mode metadata missing")
            const role = Config.ThemeEditor.roles.find(entry => entry.key === "accent")
            check(role, "accent semantic role missing")
            const before = String(editor.colors.accent)
            const changed = before.toLowerCase() === "#fedcba" ? "#123456" : "#fedcba"
            const hex = findHexForRole(editor, "accent")
            check(hex, "accent hex editor missing")
            paste(hex, changed)
            chosenAccent = String(editor.colors.accent)
            check(chosenAccent.toLowerCase() === changed, "editable color grid rejected authored hex")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === originalColors,
                "authored hex edit changed live colors")
            paste(control("themeName"), "theme-editor-test")
            check(editor.profileId === "theme-editor-test" && editor.customName === editor.profileId,
                "Theme name input did not update the custom draft")
            captureFrame("/artifacts/frame-theme-editor.png", "editing-captured")
            return
        }
        if (phase === "editing-captured") {
            const back = control("themeDraftBack")
            back.forceActiveFocus()
            native.keyClick(Qt.Key_Return)
            next("back")
            return
        }
        if (phase === "back") {
            if (popup.visible) return
            check(Wallpaper.PickerState.open && editor.wallpaper.path === selectedWallpaper
                && String(editor.colors.accent) === chosenAccent,
                "Back discarded wallpaper or authored color draft")
            check(Wallpaper.PickerState.currentPath(output.name) !== selectedWallpaper
                && Wallpaper.PickerState.savedPath(output.name) === originalWallpaper,
                "Back changed native or persisted wallpaper")
            native.keyClick(Qt.Key_Escape)
            next("picker-cancel")
            return
        }
        if (phase === "picker-cancel") {
            if (Wallpaper.PickerState.open) return
            check(editor.profileId === "" && editor.wallpaper === null && popup.profileModel.wallpaperSelection === null,
                "picker cancel did not discard draft")
            check(Wallpaper.PickerState.currentPath(output.name) !== selectedWallpaper
                && Wallpaper.PickerState.savedPath(output.name) === originalWallpaper,
                "picker cancel changed native or persisted wallpaper")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === originalColors,
                "picker cancel changed live colors")
            openPicker()
            next("saved-profile-picker")
            return
        }
        if (phase === "saved-profile-picker") {
            const index = panel.filteredWallpapers.findIndex(item => item.path === requestedWallpaper)
            check(index >= 0, "requested wallpaper disappeared from picker")
            panel.choose(index)
            panel.moveSelection(0)
            native.findChild(panel, "chooseTheme").forceActiveFocus()
            native.keyClick(Qt.Key_Return)
            next("profile-draft")
            return
        }
        if (phase === "profile-draft") {
            if (!popup.opened || !editor.editable) return
            const snapshot = popup.profileModel.snapshot
            const profile = snapshot.palettes.find(item => item.id === "default")
            check(profile, "Theme dropdown has no explicit default definition")
            priorLiveColors = paletteSignature(Theme.ActivePalettes.forOutput(output.name))
            loadedProfilePath = profile.path
            chooseSource(profile.path)
            next("profile-loaded")
            return
        }
        if (phase === "profile-loaded") {
            if (popup.profileModel.busy) return
            check(popup.profileModel.snapshot.profileId === originalProfile,
                "Theme selection unexpectedly changed the draft's wallpaper profile")
            check(editor.definitionPath === loadedProfilePath,
                "Theme dropdown did not load the chosen definition")
            check(editor.sourceId === loadedProfilePath && !control("themeName").visible,
                "saved theme did not own Source or hid its name incorrectly")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === priorLiveColors,
                "loading saved profile activated live colors")
            readCommand = Config.GeneratedRuntime.commands.readThemePalette
            Config.GeneratedRuntime.commands.readThemePalette = "/usr/bin/false"
            failureDraft = draftSignature()
            readInterruptedFocus = control("themeSourceChoice")
            readInterruptedFocus.forceActiveFocus()
            chooseSource(loadedProfilePath)
            next("read-error")
            return
        }
        if (phase === "read-error") {
            if (!popup.errorPopup.opened) return
            Config.GeneratedRuntime.commands.readThemePalette = readCommand
            check(draftSignature() === failureDraft, "failed profile read discarded the wallpaper/color candidate")
            readDiagnostic = popup.errorPopup.diagnostic
            check(readDiagnostic.length > 0, "profile read failure diagnostic missing")
            copyFailure("read-copied")
            return
        }
        if (phase === "read-copied") {
            if (clipboard.text !== readDiagnostic) return
            check(popup.errorPopup.copied, "Enter did not copy scoped profile read failure")
            dismissFailure("read-dismissed")
            return
        }
        if (phase === "read-dismissed") {
            if (popup.errorPopup.visible) return
            check(readInterruptedFocus.activeFocus && draftSignature() === failureDraft,
                "profile read failure did not restore focus and draft")
            chooseSource("custom")
            paste(control("themeName"), "save-failure-test")
            editor.edit("accent", chosenAccent)
            const save = control("themeSave")
            saveCommand = Config.GeneratedRuntime.commands.saveThemeProfile
            Config.GeneratedRuntime.commands.saveThemeProfile = "/usr/bin/false"
            failureDraft = draftSignature()
            interruptedFocus = save
            save.forceActiveFocus()
            native.keyClick(Qt.Key_Return)
            next("save-error")
            return
        }
        if (phase === "save-error") {
            if (!popup.errorPopup.opened) return
            Config.GeneratedRuntime.commands.saveThemeProfile = saveCommand
            liveBeforeFailure = paletteSignature(Theme.ActivePalettes.forOutput(output.name))
            check(popup.visible && editor.profileId === "save-failure-test",
                "failed save closed editor or lost candidate name")
            check(draftSignature() === failureDraft, "failed save discarded draft or base revision")
            diagnostic = popup.errorPopup.diagnostic
            check(diagnostic.length > 0, "save failure diagnostic missing")
            captureFrame("/artifacts/frame-theme-error.png", "save-error-captured")
            return
        }
        if (phase === "save-error-captured") {
            copyFailure("copied")
            return
        }
        if (phase === "copied") {
            if (clipboard.text !== diagnostic) return
            check(popup.errorPopup.copied, "Enter did not copy scoped save diagnostic")
            dismissFailure("dismissed")
            return
        }
        if (phase === "dismissed") {
            if (popup.errorPopup.visible) return
            check(interruptedFocus.activeFocus && popup.visible,
                "save failure dismissal did not restore editor focus")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === liveBeforeFailure,
                "failed save changed live colors")
            committedWallpaper = editor.wallpaper.path
            committedColors = paletteSignature(editor.colors)
            committedThemeId = editor.profileId
            control("themeName").forceActiveFocus()
            native.keyClick(Config.Keyboard.applyKey, Config.Keyboard.popupActionModifiers)
            next("committed")
            return
        }
        if (phase === "committed") {
            if (popup.profileModel.busy || popup.visible || Wallpaper.PickerState.open) return
            check(Wallpaper.PickerState.currentPath(output.name) === committedWallpaper
                && Wallpaper.PickerState.savedPath(output.name) === committedWallpaper,
                "final save did not activate the selected saved-profile wallpaper")
            check(paletteSignature(Theme.ActivePalettes.forOutput(output.name)) === committedColors,
                "final save did not activate the selected saved-profile colors")
            console.log("THEME_EDITOR_PASS " + JSON.stringify({ output: output.name, selectedWallpaper,
                originalProfile, themeId: committedThemeId,
                accent: chosenAccent, readDiagnostic, diagnostic }))
            poll.stop()
            Qt.quit()
        }
    }
    function copyFailure(nextPhase) {
        const copy = native.findChild(popup.errorPopup.contentItem, "errorCopy")
        check(copy, "error Copy control missing")
        copy.forceActiveFocus()
        native.keyClick(Qt.Key_Return)
        clipboard.text = ""
        clipboard.paste()
        next(nextPhase)
    }
    function dismissFailure(nextPhase) {
        const dismiss = native.findChild(popup.errorPopup.contentItem, "errorDismiss")
        check(dismiss, "error Dismiss control missing")
        dismiss.forceActiveFocus()
        native.keyClick(Qt.Key_Return)
        next(nextPhase)
    }
    Process {
        id: capture
        command: ["grim", "-o", root.requestedOutput, root.capturePath]
        onExited: function(code) {
            if (code !== 0) { console.error("THEME_EDITOR_FAIL frame capture"); Qt.exit(1); return }
            root.next(root.captureNext)
        }
    }
    Timer {
        id: frameSettle
        interval: root.captureSettleMilliseconds
        onTriggered: capture.running = true
    }
    Timer {
        id: poll
        interval: 25
        repeat: true
        running: true
        onTriggered: {
            if (root.ticking) return
            root.ticking = true
            try { root.advance() }
            catch (error) { console.error("THEME_EDITOR_FAIL " + String(error)); poll.stop(); Qt.exit(1) }
            finally { root.ticking = false }
        }
    }
}

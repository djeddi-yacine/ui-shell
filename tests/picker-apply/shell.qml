//@ pragma ShellId ui-shell-picker-apply-test
//@ pragma AppId org.ui.shell.picker-apply-test
pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
// run-session copies this entrypoint into the private shell root before launch.
import "modules/wallpaper" as Wallpaper
import "config" as ShellConfig
import "components" as Controls
import "theme" as Theme

ShellRoot {
    id: root

    Controls.InputState {
        id: testInput
        pointerActive: false
    }

    property var selectedScreen: null
    readonly property string requestedOutput: Quickshell.env("UI_SHELL_TEST_OUTPUT") || ""
    readonly property string requestedWallpaper: Quickshell.env("UI_SHELL_TEST_WALLPAPER") || ""
    property string outputName: ""
    property bool ready: false
    property bool finished: false
    property string phase: "setup"
    property int closeCount: 0
    property double deadline: 0
    property var chosen: null
    property string fitMode: ""
    property string startupSnapshot: ""
    property string otherSavedSnapshot: ""
    property string otherCurrentSnapshot: ""
    property string initialCurrentPath: ""
    property string initialSavedPath: ""
    property string initialPalette: ""
    property string draftPalette: ""
    property string draftBeforeReadFailure: ""
    property string readDiagnostic: ""
    property string readCommand: ""
    property Item readInterruptedFocus: null
    property int contextIndex: -1
    property string capturePath: ""
    property string captureNextPhase: ""
    readonly property Wallpaper.PickerPanel panel: panelLoader.status === Loader.Ready
        ? panelLoader.item as Wallpaper.PickerPanel : null

    function check(condition, message) {
        if (!condition)
            throw new Error(message)
    }

    function configuredWallpaper(path) {
        return ShellConfig.GeneratedRuntime.wallpaperFolders.some(folder => path.startsWith(folder.path + "/"))
    }

    function finish(success, detail) {
        if (finished)
            return
        finished = true
        poll.stop()
        if (success) {
            console.log("PICKER_APPLY_PASS " + JSON.stringify(detail))
            Qt.quit()
        } else {
            console.error("PICKER_APPLY_FAIL " + detail)
            Qt.exit(1)
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = ShellConfig.Config.watchSourceFiles
        try {
            root.check(Quickshell.env("UI_SHELL_ROOT") === "/project", "private /project required")
            root.check(Quickshell.shellDir === ShellConfig.GeneratedRuntime.paths.quickshell, "prepared installed shell root required")
            const privatePaths = {
                HOME: "/home/test", XDG_CONFIG_HOME: "/home/test/.config",
                XDG_CACHE_HOME: "/home/test/.cache", XDG_DATA_HOME: "/home/test/.local/share",
                XDG_STATE_HOME: "/home/test/.local/state", XDG_RUNTIME_DIR: "/run/test"
            }
            for (const name in privatePaths)
                root.check(Quickshell.env(name) === privatePaths[name], "private " + name + " required")
            root.check(String(Quickshell.env("UI_SHELL_TEST_RUN") || "").startsWith("/tmp/ui-shell-test."), "sandbox run tag required")
            root.check(!!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"), "explicit private Hyprland session required")
            root.check(!!Quickshell.env("WAYLAND_DISPLAY"), "private Wayland display required")
            root.check(root.requestedOutput.length > 0, "UI_SHELL_TEST_OUTPUT must name an exact connected output")
            root.check(root.configuredWallpaper(root.requestedWallpaper), "UI_SHELL_TEST_WALLPAPER must name a configured wallpaper asset")
            root.check(!Quickshell.env("UI_SHELL_STATE_DIR"), "unexpected state directory override")
            root.check(ShellConfig.GeneratedWallpapers.items.length > 1, "prepared wallpaper catalog required")
            root.check(ShellConfig.GeneratedWallpapers.items.every(item => ShellConfig.GeneratedRuntime.wallpaperFolders.some(folder =>
                item.folderId === folder.id && item.folderPath === folder.path && item.path === folder.path + "/" + item.name)), "catalog must use configured wallpaper folders")
            root.check(ShellConfig.GeneratedRuntime.wallpaperTargets.items.length > 0
                && ShellConfig.GeneratedRuntime.wallpaperTargets.items.every(item => root.configuredWallpaper(item.path)), "prepared configured target registry required")
            root.deadline = Date.now() + 25000
            namespaceCheck.running = true
        } catch (error) {
            root.finish(false, String(error))
        }
    }

    function advance() {
        check(Date.now() < deadline, "deadline exceeded in " + phase + "; status: " + (root.panel ? root.panel.statusText : "panel not loaded"))
        if (phase === "setup") {
            if (Quickshell.screens.length === 0)
                return
            const target = Quickshell.screens.find(screen => screen.name === root.requestedOutput)
            check(!!target && target.name.length > 0, "configured exact output is unavailable")
            outputName = target.name
            Wallpaper.PickerState.targetOutput = outputName
            Wallpaper.PickerState.screenName = outputName
            Wallpaper.PickerState.open = true
            fitMode = Wallpaper.PickerState.fitMode(outputName)
            check(["contain", "cover", "tile", "fill"].includes(fitMode), "saved fit mode is invalid")
            startupSnapshot = JSON.stringify(Wallpaper.PickerState.startupTargets)
            otherSavedSnapshot = JSON.stringify(Wallpaper.PickerState.savedTargets.filter(item => item.id !== outputName))
            otherCurrentSnapshot = JSON.stringify(Wallpaper.PickerState.currentTargets.filter(item => item.id !== outputName))
            selectedScreen = target
            phase = "start"
            ready = true
            return
        }
        check(panelLoader.status !== Loader.Error, "real PickerPanel could not load")
        if (panelLoader.status !== Loader.Ready || !panelLoader.item)
            return
        const panel = root.panel
        check(panel !== null, "loaded item is not the real PickerPanel")
        if (phase === "start") {
            if (panel.width <= 0 || panel.height <= 0 || !panel.componentSettings.ready || panel.componentSettings.loading)
                return
            check(panel.targetAvailable, "exact output is missing from panel targets")
            initialCurrentPath = Wallpaper.PickerState.currentPath(outputName)
            initialSavedPath = Wallpaper.PickerState.savedPath(outputName)
            initialPalette = paletteSignature(Theme.ActivePalettes.forOutput(outputName))
            const currentPath = initialCurrentPath
            const savedPath = initialSavedPath
            check(requestedWallpaper !== currentPath, "requested wallpaper must differ from initial current selection")
            check(panel.currentPath === currentPath && panel.savedPath === savedPath, "panel initial paths disagree with singleton")
            check(panel.query === "" && panel.selectedWallpaper !== null
                && panel.selectedWallpaper.path === savedPath, "picker did not open on its saved tile")
            const grid = panel.wallpaperView
            const search = find(panel, "wallpaperSearchInput")
            const targetControl = find(panel, "wallpaperTarget")
            const action = find(panel, "chooseTheme")
            check(search && targetControl && action && grid.activeFocus,
                "picker did not open with the grid as its exclusive focus owner")
            const candidateBeforeTab = panel.selectedIndex
            const queryBeforeTab = panel.query
            for (let cycle = 0; cycle < 3; cycle++) {
                const order = [action, search, targetControl, grid]
                for (const focused of order) {
                    testInput.pointerUsed()
                    nativeKeys.keyClick(Qt.Key_Tab)
                    check(focused.activeFocus && order.filter(control => control.activeFocus).length === 1,
                        "native picker Tab retained another control's focus")
                    check(!testInput.pointerActive, "picker Tab retained stale pointer hover")
                    check(panel.selectedIndex === candidateBeforeTab && panel.query === queryBeforeTab,
                        "picker Tab changed saved candidate or query")
                    const cell = grid.itemAtIndex(panel.selectedIndex)
                    check(cell && cell.children.every(tile => !tile.activeFocus && !tile.activeFocusOnTab
                        && tile.keyboardCandidate === grid.activeFocus),
                        "wallpaper tile retained focus or failed to follow its grid owner")
                }
                const reverse = [targetControl, search, action, grid]
                for (const focused of reverse) {
                    nativeKeys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
                    check(focused.activeFocus && reverse.filter(control => control.activeFocus).length === 1
                        && panel.selectedIndex === candidateBeforeTab && panel.query === queryBeforeTab,
                        "native picker Shift+Tab mismatch: " + JSON.stringify({ expected: focused.objectName,
                            actual: panel.Window.window.activeFocusItem ? panel.Window.window.activeFocusItem.objectName : "none",
                            index: panel.selectedIndex, before: candidateBeforeTab, query: panel.query }))
                }
            }
            // Clicking another tile must select it without making it a focus owner.
            const otherIndex = panel.filteredWallpapers.findIndex((item, index) => index !== candidateBeforeTab)
            check(otherIndex >= 0, "picker requires a second catalog wallpaper for focus coverage")
            grid.positionViewAtIndex(otherIndex, GridView.Contain)
            grid.forceLayout()
            const otherCell = grid.itemAtIndex(otherIndex)
            check(otherCell !== null, "pointer candidate was not instantiated")
            nativeKeys.mouseClick(otherCell, otherCell.width / 2, otherCell.height / 2)
            check(panel.selectedIndex === otherIndex && grid.activeFocus,
                "pointer selection did not return focus to the wallpaper grid")
            nativeKeys.keyClick(Qt.Key_Tab)
            check(action.activeFocus && !grid.activeFocus && panel.selectedIndex === otherIndex,
                "Tab from a pointer-chosen wallpaper retained its grid focus")
            nativeKeys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
            check(grid.activeFocus && panel.selectedIndex === otherIndex,
                "returning to the grid reselected the previous focused wallpaper")
            panel.selectSaved()
            contextIndex = panel.selectedIndex
            key(ShellConfig.Keyboard.infoKey, ShellConfig.Keyboard.contextModifiers)
            phase = "info"
            return
        }
        if (phase === "info") {
            if (!panel.contextPopup.opened) return
            check(panel.contextOpen && panel.contextPopup.kind === "info"
                && panel.contextPopup.infoTitle === panel.selectedWallpaper.name, "wallpaper information is not scoped to its candidate")
            key(ShellConfig.Keyboard.applyKey, Qt.NoModifier)
            key(ShellConfig.Keyboard.nextKey, Qt.NoModifier)
            check(!panel.applying && panel.selectedIndex === contextIndex && closeCount === 0,
                "popup keys applied a wallpaper, moved the candidate or closed the parent")
            capturePath = "/artifacts/frame-picker-info.png"
            captureNextPhase = "info-captured"
            capture.running = true
            phase = "capturing"
            return
        }
        if (phase === "capturing") return
        if (phase === "info-captured") {
            key(ShellConfig.Keyboard.cancelKey, Qt.NoModifier)
            phase = "info-closed"
            return
        }
        if (phase === "info-closed") {
            if (panel.contextOpen) return
            check(panel.selectedIndex === contextIndex && closeCount === 0, "info dismissal changed the candidate or closed the picker")
            key(ShellConfig.Keyboard.helpKey, ShellConfig.Keyboard.contextModifiers)
            check(panel.contextPopup.kind === "help" && panel.contextPopup.bindings.some(binding => binding.key === ShellConfig.Keyboard.searchKey),
                "picker usage did not disclose configured search key")
            key(ShellConfig.Keyboard.cancelKey, Qt.NoModifier)
            phase = "help-closed"
            return
        }
        if (phase === "help-closed") {
            if (panel.contextOpen) return
            key(ShellConfig.Keyboard.settingsKey, ShellConfig.Keyboard.contextModifiers)
            phase = "settings"
            return
        }
        if (phase === "settings") {
            const edit = panel.contextPopup.editor
            if (!edit || !edit.editable || edit.awaitingScope || !panel.contextPopup.opened) return
            check(edit.settings.screenName === outputName && edit.scope === "output", "picker settings guessed a monitor")
            check(edit.file.path.startsWith(ShellConfig.GeneratedRuntime.paths.components + "/wallpaper/outputs/"),
                "picker settings did not stay in private per-output QML")
            edit.setDraftAt(0, 3)
            edit.setDraftAt(1, 2)
            check(panel.componentSettings.wideColumns === ShellConfig.WallpaperPicker.wideColumns
                && panel.componentSettings.maximumVisibleRows === ShellConfig.WallpaperPicker.maximumVisibleRows,
                "picker draft changed the live grid")
            phase = "settings-settled"
            return
        }
        if (phase === "settings-settled") {
            capturePath = "/artifacts/frame-picker-settings.png"
            captureNextPhase = "settings-captured"
            capture.running = true
            phase = "capturing"
            return
        }
        if (phase === "settings-captured") {
            find(panel.contextPopup.editor, "settingsChoice-maximumVisibleRows").forceActiveFocus()
            nativeKeys.keyClick(ShellConfig.Keyboard.applyKey, ShellConfig.Keyboard.popupActionModifiers)
            phase = "settings-saved"
            return
        }
        if (phase === "settings-saved") {
            if (panel.componentSettings.busy || panel.contextOpen) return
            check(!panel.componentSettings.loadError && !panel.componentSettings.saveError
                && panel.componentSettings.wideColumns === 3 && panel.componentSettings.maximumVisibleRows === 2,
                "saved picker grid options did not apply live")
            check(panel.savedPath === Wallpaper.PickerState.savedPath(outputName)
                && panel.currentPath === Wallpaper.PickerState.currentPath(outputName) && panel.selectedIndex === contextIndex,
                "changing grid density changed wallpaper state")
            key(ShellConfig.Keyboard.settingsKey, ShellConfig.Keyboard.contextModifiers)
            phase = "settings-reopened"
            return
        }
        if (phase === "settings-reopened") {
            const edit = panel.contextPopup.editor
            if (!edit || !edit.editable || edit.awaitingScope) return
            check(edit.draftAt(0) === 3 && edit.draftAt(1) === 2, "picker did not reload saved QML grid choices")
            edit.setDraftAt(0, undefined)
            edit.setDraftAt(1, undefined)
            edit.save()
            phase = "settings-reset"
            return
        }
        if (phase === "settings-reset") {
            if (panel.componentSettings.busy || panel.contextOpen) return
            check(panel.componentSettings.wideColumns === ShellConfig.WallpaperPicker.wideColumns
                && panel.componentSettings.maximumVisibleRows === ShellConfig.WallpaperPicker.maximumVisibleRows,
                "picker Default options did not restore configured density")
            const index = panel.filteredWallpapers.findIndex(item => item.path === root.requestedWallpaper)
            check(index >= 0, "requested wallpaper is missing from private catalog")
            chosen = panel.filteredWallpapers[index]
            check(ShellConfig.GeneratedRuntime.wallpaperFolders.some(folder => folder.id === chosen.folderId
                && folder.path === chosen.folderPath), "chosen wallpaper has no configured folder ID")
            panel.choose(index)
            panel.moveSelection(0)
            check(panel.selectedWallpaper.path === chosen.path, "public choose did not select candidate")
            check(panel.currentPath === initialCurrentPath && panel.savedPath === initialSavedPath, "browsing changed the live or saved selection")
            find(panel, "chooseTheme").forceActiveFocus()
            nativeKeys.keyClick(Qt.Key_Return)
            phase = "draft-check"
            return
        }
        if (phase === "draft-check") {
            if (!panel.themeEditor.opened || !panel.themeEditor.editor.editable) return
            check(panel.themeEditor.editor.wallpaper.path === chosen.path,
                "theme draft did not use selected image")
            precommitCheck.running = true
            phase = "draft-verified"
            return
        }
        if (phase === "draft-verified") return
        if (phase === "draft") {
            const popup = panel.themeEditor
            if (!popup.opened || !popup.editor.editable) return
            check(popup.editor.wallpaper.path === chosen.path, "theme draft did not use selected image")
            check(popup.profileModel.snapshot.draftWallpaper.path === chosen.path
                && popup.profileModel.snapshot.baseRevision, "draft snapshot lost wallpaper or base revision")
            check(Wallpaper.PickerState.currentPath(outputName) === initialCurrentPath
                && Wallpaper.PickerState.savedPath(outputName) === initialSavedPath,
                "advancing to theme draft changed native or saved wallpaper")
            check(paletteSignature(Theme.ActivePalettes.forOutput(outputName)) === initialPalette,
                "advancing to theme draft changed live colors")
            draftPalette = paletteSignature(panel.themeEditor.editor.colors)
            check(panel.selectedIndex >= 0 && panel.themeEditor.visible,
                "picker candidate or editor popup was lost")
            draftBeforeReadFailure = JSON.stringify({ wallpaper: popup.editor.wallpaper.path,
                colors: popup.editor.colors, profileId: popup.editor.profileId,
                revision: popup.profileModel.snapshot.baseRevision })
            readCommand = ShellConfig.GeneratedRuntime.commands.readThemeEditor
            ShellConfig.GeneratedRuntime.commands.readThemeEditor = "/missing-test-palette-generator"
            readInterruptedFocus = find(popup.editor, "themeSave")
            readInterruptedFocus.forceActiveFocus()
            popup.profileModel.loadProfile(popup.profileModel.snapshot.profilePath)
            phase = "read-error"
            return
        }
        if (phase === "read-error") {
            const popup = panel.themeEditor
            if (!popup.errorPopup.opened) return
            ShellConfig.GeneratedRuntime.commands.readThemeEditor = readCommand
            readDiagnostic = popup.errorPopup.diagnostic
            check(readDiagnostic.length > 0 && JSON.stringify({ wallpaper: popup.editor.wallpaper.path,
                colors: popup.editor.colors, profileId: popup.editor.profileId,
                revision: popup.profileModel.snapshot.baseRevision }) === draftBeforeReadFailure,
                "failed profile read discarded the candidate or base revision")
            capturePath = "/artifacts/frame-picker-error.png"
            captureNextPhase = "read-error-captured"
            capture.running = true
            phase = "capturing"
            return
        }
        if (phase === "read-error-captured") {
            const popup = panel.themeEditor
            const copy = find(popup.errorPopup.contentItem, "errorCopy")
            check(copy, "theme read error Copy control missing")
            copy.forceActiveFocus()
            nativeKeys.keyClick(Qt.Key_Return)
            clipboardProbe.text = ""
            clipboardProbe.paste()
            phase = "read-copied"
            return
        }
        if (phase === "read-copied") {
            const popup = panel.themeEditor
            if (clipboardProbe.text !== readDiagnostic) return
            check(popup.errorPopup.copied, "native Enter did not copy scoped read failure")
            const dismiss = find(popup.errorPopup.contentItem, "errorDismiss")
            check(dismiss, "theme read error Dismiss control missing")
            dismiss.forceActiveFocus()
            nativeKeys.keyClick(Qt.Key_Return)
            phase = "read-dismissed"
            return
        }
        if (phase === "read-dismissed") {
            const popup = panel.themeEditor
            if (popup.errorPopup.visible) return
            check(readInterruptedFocus.activeFocus && JSON.stringify({ wallpaper: popup.editor.wallpaper.path,
                colors: popup.editor.colors, profileId: popup.editor.profileId,
                revision: popup.profileModel.snapshot.baseRevision }) === draftBeforeReadFailure,
                "profile read failure did not restore editor focus and draft")
            phase = "save"
            return
        }
        if (phase === "save") {
            if (!panel.themeEditor.opened) return
            const save = find(panel.themeEditor.editor, "themeSave")
            check(save, "final Save and apply control missing")
            save.forceActiveFocus()
            nativeKeys.keyClick(Qt.Key_Return)
            phase = "committed"
            return
        }
        if (phase === "committed") {
            if (panel.themeEditor.profileModel.busy || panel.themeEditor.visible) return
            check(!panel.themeEditor.errorPopup.opened, "final bundle save failed")
            check(Wallpaper.PickerState.currentPath(outputName) === chosen.path && panel.currentPath === chosen.path,
                "final save did not apply the selected wallpaper")
            check(Wallpaper.PickerState.savedPath(outputName) === chosen.path && panel.savedPath === chosen.path,
                "final save did not persist the selected wallpaper")
            check(paletteSignature(Theme.ActivePalettes.forOutput(outputName)) === draftPalette,
                "final save did not apply the exact draft colors")
            check(Wallpaper.PickerState.fitMode(outputName) === fitMode, "save changed fit mode")
            const saved = Wallpaper.PickerState.savedTargets.filter(item => item.id === outputName)
            const current = Wallpaper.PickerState.currentTargets.filter(item => item.id === outputName)
            check(saved.length === 1 && current.length === 1, "duplicate or missing exact output selection")
            const savedSelection = saved.find(item => item.id === outputName)
            const currentSelection = current.find(item => item.id === outputName)
            check(savedSelection.fitMode === fitMode && currentSelection.fitMode === fitMode, "live/saved fit mode mismatch")
            check(savedSelection.paletteKey && savedSelection.paletteKey === currentSelection.paletteKey,
                "saved and current palette identities differ")
            check(Object.prototype.hasOwnProperty.call(Theme.ActivePalettes.byOutput, outputName),
                "final save lost the exact output palette")
            check(JSON.stringify(Wallpaper.PickerState.startupTargets) === startupSnapshot, "startup snapshot changed")
            check(JSON.stringify(Wallpaper.PickerState.savedTargets.filter(item => item.id !== outputName)) === otherSavedSnapshot,
                "another saved output changed")
            check(JSON.stringify(Wallpaper.PickerState.currentTargets.filter(item => item.id !== outputName)) === otherCurrentSnapshot,
                "another live output changed")
            if (closeCount === 0) return
            check(closeCount === 1, "panel closed more than once")
        finish(true, { output: outputName, folderId: chosen.folderId, path: chosen.path,
            fitMode: fitMode, paletteKey: savedSelection.paletteKey, readDiagnostic })
        }
    }

    function key(code, modifiers) {
        const event = { key: code, modifiers: modifiers, accepted: false }
        panel.handleKey(event)
        check(event.accepted, "picker did not consume configured key")
    }
    function paletteSignature(palette) {
        return JSON.stringify(ShellConfig.ThemeEditor.roles.map(role => ({ key: role.key, value: String(palette[role.key]) })))
    }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) {
            const found = find(child, name)
            if (found) return found
        }
        return null
    }
    Process {
        id: precommitCheck
        command: ["/usr/bin/bash", "-c",
            'set -euo pipefail; [[ $(sha256sum -- "$1" | cut -d " " -f1) == "$2" ]]; [[ $(sha256sum -- "$3" | cut -d " " -f1) == "$4" ]]; [[ $(sha256sum -- "$6" | cut -d " " -f1) == "$7" ]]; hyprctl hyprpaper listactive | rg -Fqx -- "$5"',
            "precommit", ShellConfig.GeneratedRuntime.bundle.wallpaperRegistry,
            Quickshell.env("UI_SHELL_TEST_REGISTRY_SHA"), Quickshell.env("UI_SHELL_TEST_MANIFEST"),
            Quickshell.env("UI_SHELL_TEST_MANIFEST_SHA"), Quickshell.env("UI_SHELL_TEST_INITIAL_NATIVE"),
            Quickshell.env("UI_SHELL_TEST_PROFILE"), Quickshell.env("UI_SHELL_TEST_PROFILE_SHA")]
        onExited: function(exitCode) {
            if (exitCode !== 0) root.finish(false, "draft changed registry/manifest/native wallpaper before final save")
            else root.phase = "draft"
        }
    }
    Process {
        id: capture
        command: ["grim", "-o", root.outputName, root.capturePath]
        onExited: function(exitCode) {
            if (exitCode !== 0) root.finish(false, "Could not capture contextual picker frame")
            else root.phase = root.captureNextPhase
        }
    }

    Timer {
        id: poll
        interval: 50
        repeat: true
        onTriggered: {
            try {
                root.advance()
            } catch (error) {
                root.finish(false, String(error))
            }
        }
    }

    Process {
        id: namespaceCheck
        command: ["/usr/bin/bash", "-c", 'set -euo pipefail; [[ -n "$UI_SHELL_HOST_PID_NS" && "$(readlink /proc/self/ns/pid)" != "$UI_SHELL_HOST_PID_NS" && -n "$UI_SHELL_HOST_PROJECT" && ! -e "$UI_SHELL_HOST_PROJECT" && ! -w /source/hypr && -w /project/hypr ]]; jq -er \'.wallpaperFolders[] | select(.id == "default") | .path\' "$UI_SHELL_RUNTIME" | while IFS= read -r folder; do [[ -d "$folder" ]] || exit 1; done; jq -er \'.wallpaperFolders[] | select(.id != "default") | .path\' "$UI_SHELL_RUNTIME" | while IFS= read -r folder; do [[ -d "$folder" && ! -w "$folder" ]] || exit 1; done']
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.finish(false, "private PID namespace, absent host project and sandbox mounts required")
            else
                poll.start()
        }
    }

    PanelWindow {
        screen: root.selectedScreen
        visible: root.ready
        exclusionMode: ExclusionMode.Ignore
        color: "#00000000"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "ui-shell-picker-apply-test"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        TestCase { id: nativeKeys; when: false }
        TextEdit { id: clipboardProbe; visible: false; textFormat: TextEdit.PlainText }

        Loader {
            id: panelLoader
            anchors.fill: parent
            active: root.ready
            sourceComponent: Wallpaper.PickerPanel {
                screenName: root.outputName
                inputState: testInput
                onClosed: root.closeCount += 1
            }
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import "../../config" as ShellConfig
import "../../theme" as Theme

QtObject {
    property bool open: false
    property string screenName: ""
    property string targetOutput: ""
    property string colorMode: ShellConfig.GeneratedRuntime.wallpaperTargets.colorMode
    property string cacheNamespace: ShellConfig.GeneratedRuntime.wallpaperTargets.cacheNamespace
    property Connections profileChanges: Connections {
        target: Theme.ActivePalettes
        function onProfileApplied(snapshot, restoresWallpapers) {
            PickerState.savedTargets = snapshot.wallpapers.map(entry => ({ id: entry.id, label: entry.label,
                path: entry.path, paletteKey: entry.paletteKey, fitMode: entry.fitMode }))
            if (restoresWallpapers)
                PickerState.currentTargets = PickerState.savedTargets.map(entry => Object.assign({}, entry))
            PickerState.colorMode = snapshot.colorMode
            PickerState.cacheNamespace = snapshot.cacheNamespace
        }
    }

    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_PICKER") !== "1")
            return
        const target = ShellConfig.Outputs.pickerScreen(Quickshell.screens)
        if (!target)
            return
        screenName = target.name
        targetOutput = target.name
        open = true
    }

    // The saved preference chooses the opening candidate; current tracks this shell's
    // last known applied wallpaper. They can diverge if persistence fails after apply.
    // Generated targets seed both from the startup assignments.
    readonly property var startupTargets: ShellConfig.GeneratedRuntime.wallpaperTargets.items.map(target => Object.assign({}, target))
    property var savedTargets: startupTargets.map(target => Object.assign({}, target))
    property var currentTargets: startupTargets.map(target => Object.assign({}, target))

    function selectionFor(targets, output) {
        // A display uses its override or the required user-set default.
        const defaultSelection = targets.find(target => target.id === "")
        if (!defaultSelection)
            throw new Error("PickerState: the configured default wallpaper is missing")
        const exact = targets.find(target => target.id === output)
        if (exact)
            return exact
        return defaultSelection
    }

    function savedPath(output) {
        return selectionFor(savedTargets, output).path
    }

    function startupPath(output) {
        return selectionFor(startupTargets, output).path
    }

    function currentPath(output) {
        return selectionFor(currentTargets, output).path
    }

    function fitMode(output) {
        return selectionFor(savedTargets, output).fitMode
    }

    function appliedSelection(output, path, fitMode) {
        currentTargets = currentTargets.filter(target => target.id !== output)
            .concat([{ id: output, path: path, fitMode: fitMode }])
    }

    function saveSelection(output, path, paletteKey, fitMode) {
        // Replace the array so all picker bindings observe the successful save.
        const updated = savedTargets.filter(target => target.id !== output)
        updated.push({ id: output, label: output === "" ? qsTr("Default") : output, path: path, paletteKey: paletteKey, fitMode: fitMode })
        savedTargets = updated
    }
}

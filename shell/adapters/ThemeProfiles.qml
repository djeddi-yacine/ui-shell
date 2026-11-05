pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Config
import "../theme" as Theme

Item {
    id: root
    required property string screenName
    property var snapshot: null
    property bool snapshotReady: false
    property string operation: ""
    property string loadOperation: ""
    property string dataPath: ""
    property string baseProfilePath: ""
    property var wallpaperSelection: null
    property bool pending: false
    // The theme definition a palette read was asked for, so a failure can name it.
    property string paletteSource: ""
    property int failureSequence: 0
    readonly property bool busy: operation !== "" || loadOperation !== ""
    readonly property var outputs: Quickshell.screens.map(screen => screen.name)
    signal ready()
    signal paletteReady(var palette)
    signal committed()
    signal failed(var failure)

    function fail(message) {
        const action = operation || loadOperation
        if (action === "read" && snapshot) {
            // A failed replacement leaves the last successfully read draft intact.
            baseProfilePath = snapshot.profilePath
            wallpaperSelection = Object.assign({}, snapshot.draftWallpaper)
            snapshotReady = true
        }
        operation = ""
        loadOperation = ""
        pending = false
        failureSequence += 1
        failed({ source: "theme-profiles", sequence: failureSequence,
            title: qsTr("Theme operation failed"), message: qsTr("Your draft is still open."),
            operation: action,
            target: wallpaperSelection ? wallpaperSelection.id || qsTr("Shared default") : screenName,
            details: action === "palette" && paletteSource
                ? qsTr("Theme definition: %1").arg(paletteSource) + "\n\n" + message : message })
    }
    function start(action, command) {
        if (busy) return
        operation = action
        pending = true
        process.command = command
        process.running = true
    }
    function refresh(wallpaperColors = false) {
        if (!wallpaperSelection || busy) return
        snapshotReady = false
        start("read", [Config.GeneratedRuntime.commands.readThemeEditor, wallpaperSelection.id,
            baseProfilePath, wallpaperSelection.folderId, wallpaperSelection.name, wallpaperSelection.fitMode,
            wallpaperColors ? "wallpaper" : "policy"])
    }
    function loadProfile(path) {
        if (busy) return
        baseProfilePath = path
        refresh()
    }
    function reset() {
        if (busy) return
        snapshot = null
        snapshotReady = false
        wallpaperSelection = null
        baseProfilePath = ""
    }
    function readPalette(path) { paletteSource = path; start("palette", [Config.GeneratedRuntime.commands.readThemePalette, path]) }
    function save(id, target, source, mode, colorData, writeDefinition, definitionPath) {
        if (!snapshot || busy) return
        start("save", [Config.GeneratedRuntime.commands.saveThemeProfile, id, snapshot.revision,
            snapshot.baseRevision, target, source, mode, snapshot.profilePath,
            wallpaperSelection.folderId, wallpaperSelection.name, wallpaperSelection.fitMode,
            writeDefinition ? "save" : "retain", definitionPath, JSON.stringify(colorData)])
    }
    function copyPalette(item) {
        const data = item.colorData === undefined ? item : item.colorData
        const result = Object.assign({}, data)
        result.colors = Object.assign({}, data.colors)
        result.hyprland = Object.assign({}, data.hyprland)
        return result
    }
    function accept(item) {
        const action = loadOperation
        if (action === "palette") {
            const colors = copyPalette(item)
            loadOperation = ""
            paletteReady(colors)
            return
        }
        const byOutput = Object.create(null)
        for (const name of Object.keys(item.byOutput))
            byOutput[name] = copyPalette(item.byOutput[name])
        snapshot = { profileId: item.profileId, profilePath: item.profilePath, revision: item.revision,
            baseRevision: item.baseRevision, draftWallpaper: item.draftWallpaper,
            source: item.source, definition: item.definition, definitionOverrides: item.definitionOverrides,
            mode: item.mode, defaultPalette: copyPalette(item.defaultPalette),
            globalPalette: copyPalette(item.globalPalette),
            byOutput: byOutput,
            wallpapers: item.wallpapers,
            profiles: item.profiles, palettes: item.palettes,
            colorMode: item.colorMode, cacheNamespace: item.cacheNamespace }
        snapshotReady = true
        loadOperation = ""
        if (action === "save") {
            Theme.ActivePalettes.apply(snapshot, true)
            committed()
        }
        else ready()
    }
    Process {
        id: process
        stdout: StdioCollector { id: response }
        stderr: StdioCollector { id: diagnostic }
        onExited: function(code, status) {
            root.pending = false
            if (code !== 0 || status !== 0) { root.fail(diagnostic.text.trim() || qsTr("The configured theme helper failed.")); return }
            const lines = response.text.trim().split("\n")
            const [path, revision] = lines
            if (lines.length !== 2 || !path.startsWith("/") || !/^[a-f0-9]{64}$/.test(revision)) {
                root.fail(qsTr("Invalid theme helper response.")); return
            }
            root.loadOperation = root.operation
            root.operation = ""
            root.dataPath = path
            data.source = ""
            // The helper's content-addressed filename already qualifies the
            // revision. A URL query is unnecessary and triggers Qt file warnings.
            data.source = "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F")
        }
        onRunningChanged: if (!running && root.pending) root.fail(qsTr("Could not start the configured theme helper."))
    }
    Loader {
        id: data
        asynchronous: true
        onLoaded: root.accept(item)
        onStatusChanged: if (status === Loader.Error)
            root.fail(qsTr("Could not load the generated native theme data: %1").arg(root.dataPath))
    }
}

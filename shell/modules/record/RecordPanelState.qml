pragma Singleton
import QtQuick
import Quickshell
import "../../adapters" as Adapters
import "../../config" as Config

Singleton {
    id: stateRoot
    property bool open: false
    property string screenName: ""
    // The devices the user picked (desktop audio, microphone, camera), kept for the session so a pick
    // is still there the next time the panel opens. Ctrl+E only gives the starting point.
    property var picks: ({})
    // The saved recording announced the last time the panel was open, and the one before that: a save is
    // announced once, the first time the panel shows it, and never again (the file may be gone by then).
    property string displayedResult: ""
    property string acknowledgedResult: ""
    function pick(key, value) { const next = Object.assign({}, picks); next[key] = value; picks = next }
    // A failure that happened while no panel was open (the recorder died later). The panel
    // shows it as soon as it opens, so a recording never fails silently.
    property var pendingFailure: null
    // Previews: UI_SHELL_RECORD_CONTEXT (help, info, settings) opens that popup at start.
    // Preview: UI_SHELL_RECORD_KIND (monitor, window, region) opens that target kind.
    readonly property string initialKind: Quickshell.env("UI_SHELL_RECORD_KIND") || "monitor"
    // Preview: UI_SHELL_RECORD_ACTION=pick starts the pointer region selection when the panel opens.
    readonly property string initialAction: Quickshell.env("UI_SHELL_RECORD_ACTION") || ""
    readonly property string initialContext: Quickshell.env("UI_SHELL_RECORD_CONTEXT") || ""
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_RECORD") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    Connections {
        target: Adapters.RecordState
        function onFailed(failure) {
            if (stateRoot.open) return   // the open panel presents it itself
            stateRoot.pendingFailure = failure
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) stateRoot.show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
}

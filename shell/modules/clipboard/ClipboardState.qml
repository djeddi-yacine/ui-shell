pragma Singleton
import QtQuick
import Quickshell
import "../../config" as Config
import "../../adapters" as Adapters

// The panel's open state and the screen it is on. UI_SHELL_OPEN_CLIPBOARD=1 opens it at start-up
// for a look; there is no other start-up behaviour.
QtObject {
    property bool open: false
    property string screenName: ""
    // A failed copy that finished after the panel closed; the panel reopens and shows it.
    property var lateFailure: null
    property Connections lateFailures: Connections {
        target: Adapters.ClipboardRunner
        function onFailed(failure) {
            if (open) return
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (!output) return
            lateFailure = failure
            show(output.name)
        }
    }
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_CLIPBOARD") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
    function toggle(output) {
        if (open) open = false
        else show(output)
    }
}

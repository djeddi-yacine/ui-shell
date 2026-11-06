pragma Singleton
import QtQuick
import Quickshell
import "../../config" as Config

QtObject {
    property bool open: false
    property string screenName: ""
    // True from pressing Capture until the picture is taken: the panel's window is hidden so it is
    // not in the picture, while the panel keeps its choices.
    property bool capturing: false
    // A picture is announced once, the first time the panel shows it, and never again.
    property string displayedResult: ""
    property string acknowledgedResult: ""
    // Previews: UI_SHELL_OPEN_SHOT opens the panel at start; UI_SHELL_SHOT_CONTEXT opens a popup.
    readonly property string initialContext: Quickshell.env("UI_SHELL_SHOT_CONTEXT") || ""
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_SHOT") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
}

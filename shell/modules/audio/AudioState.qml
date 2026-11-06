pragma Singleton
import QtQuick
import Quickshell
import "../../config" as Config

QtObject {
    property bool open: false
    property string screenName: ""
    // Previews: UI_SHELL_AUDIO_CONTEXT (help, info, settings) opens that popup at start.
    readonly property string initialContext: Quickshell.env("UI_SHELL_AUDIO_CONTEXT") || ""
    // Opening tab; UI_SHELL_AUDIO_TAB (output, input, playback, recording, cards, patchbay) picks one for previews.
    readonly property string initialTab: Quickshell.env("UI_SHELL_AUDIO_TAB") || "output"
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_AUDIO") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
}

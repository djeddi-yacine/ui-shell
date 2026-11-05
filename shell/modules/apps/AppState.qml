pragma Singleton
import QtQuick
import Quickshell
import "../../config" as Config

QtObject {
    property bool open: false
    property string screenName: ""
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_APPS") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
}

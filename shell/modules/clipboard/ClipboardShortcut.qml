import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.Clipboard.shortcutAppId
    name: Config.Clipboard.shortcutName
    description: qsTr("Toggle the clipboard history")
    onPressed: {
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) ClipboardState.toggle(target.name)
    }
}

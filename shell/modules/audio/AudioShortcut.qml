import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.Audio.shortcutAppId
    name: Config.Audio.shortcutName
    description: qsTr("Open audio control")
    onPressed: {
        if (AudioState.open) { AudioState.open = false; return }
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) AudioState.show(target.name)
    }
}

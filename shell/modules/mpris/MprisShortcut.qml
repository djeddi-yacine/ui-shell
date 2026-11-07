import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.Mpris.shortcutAppId
    name: Config.Mpris.shortcutName
    description: qsTr("Open media control")
    onPressed: {
        if (MprisState.open) { MprisState.open = false; return }
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) MprisState.show(target.name)
    }
}

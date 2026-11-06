import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.Shot.shortcutAppId
    name: Config.Shot.shortcutName
    description: qsTr("Open screenshot")
    onPressed: {
        if (ShotPanelState.open) { ShotPanelState.open = false; return }
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) ShotPanelState.show(target.name)
    }
}

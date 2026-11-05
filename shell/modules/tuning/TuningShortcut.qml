import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.Tuning.shortcutAppId
    name: Config.Tuning.shortcutName
    description: qsTr("Tune control colors")
    onPressed: {
        if (TuningState.open) { TuningState.open = false; return }
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) TuningState.show(target.name)
    }
}

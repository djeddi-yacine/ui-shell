import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

GlobalShortcut {
    appid: Config.AppLauncher.shortcutAppId
    name: Config.AppLauncher.shortcutName
    description: qsTr("Open application launcher")
    readonly property var preparedCatalog: Config.AppLauncher.warmCatalog ? AppCatalog.index : []
    onPressed: {
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) AppState.show(target.name)
    }
}

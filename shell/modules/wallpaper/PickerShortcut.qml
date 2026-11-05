import Quickshell
import Quickshell.Hyprland
import "../../config" as ShellConfig

GlobalShortcut {
    appid: ShellConfig.WallpaperPicker.shortcutAppId
    name: ShellConfig.WallpaperPicker.shortcutName
    description: qsTr("Open wallpaper picker")

    onPressed: {
        const target = ShellConfig.Outputs.pickerScreen(Quickshell.screens)
        if (!target)
            return
        PickerState.screenName = target.name
        PickerState.targetOutput = target.name
        PickerState.open = true
    }
}

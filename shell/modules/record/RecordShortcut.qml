import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

// One key, one meaning: it toggles the recording panel. While a recording runs the panel shows
// its state with Stop focused, so stopping by keyboard takes two deliberate keys and a stray
// press can never end a recording.
GlobalShortcut {
    appid: Config.Record.shortcutAppId
    name: Config.Record.shortcutName
    description: qsTr("Open screen recording")
    onPressed: {
        if (RecordPanelState.open) { RecordPanelState.open = false; return }
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) RecordPanelState.show(target.name)
    }
}

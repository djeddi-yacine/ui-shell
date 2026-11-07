import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../config" as Config

// The keyboard media keys, handled by the shell. Each is a shortcut that Hyprland's media binds
// (hypr/binds/hardware.lua) send here, and each acts on the same player the panel shows, so the
// keys and the panel can never disagree. If the shell is down the keys do nothing.
Scope {
    GlobalShortcut {
        appid: Config.Mpris.shortcutAppId
        name: Config.Mpris.keyShortcuts.playPause.name
        description: Config.Mpris.keyShortcuts.playPause.description
        onPressed: MprisState.selection.playPause()
    }
    GlobalShortcut {
        appid: Config.Mpris.shortcutAppId
        name: Config.Mpris.keyShortcuts.pause.name
        description: Config.Mpris.keyShortcuts.pause.description
        onPressed: MprisState.selection.pause()
    }
    GlobalShortcut {
        appid: Config.Mpris.shortcutAppId
        name: Config.Mpris.keyShortcuts.next.name
        description: Config.Mpris.keyShortcuts.next.description
        onPressed: MprisState.selection.next()
    }
    GlobalShortcut {
        appid: Config.Mpris.shortcutAppId
        name: Config.Mpris.keyShortcuts.previous.name
        description: Config.Mpris.keyShortcuts.previous.description
        onPressed: MprisState.selection.previous()
    }
}

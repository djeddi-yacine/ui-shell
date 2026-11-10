import QtQuick
import Quickshell.Hyprland
import "../../config" as Config

// Global shortcuts. The popup never takes focus, so dismissing it is a shortcut, not a key press.
Item {
    GlobalShortcut {
        appid: "ui-shell"
        name: Config.Notifications.shortcutDrawer
        description: qsTr("Open the notification drawer")
        onPressed: {
            const monitor = Hyprland.focusedMonitor
            if (monitor) NotifState.toggle(monitor.name)
        }
    }
    GlobalShortcut {
        appid: "ui-shell"
        name: Config.Notifications.shortcutDnd
        description: qsTr("Toggle do not disturb")
        onPressed: NotifCenter.setDnd(!NotifCenter.dnd)
    }
    GlobalShortcut {
        appid: "ui-shell"
        name: Config.Notifications.shortcutDismiss
        description: qsTr("Dismiss the notification popup")
        onPressed: NotifCenter.dismissPopup()
    }
}

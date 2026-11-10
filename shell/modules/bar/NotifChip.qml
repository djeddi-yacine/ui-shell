import QtQuick
import Quickshell.Hyprland
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "../notifications" as Notif

// Bar entry: the unread count, and a different label while do-not-disturb is on. Click opens the drawer.
Controls.ShellButton {
    emphasis: Theme.Interaction.barEntryEmphasis
    visible: Config.Config.notificationsEnabled
    text: Notif.NotifCenter.dnd ? qsTr("DND") : qsTr("Notifications") + (Notif.NotifCenter.unread > 0 ? " " + Notif.NotifCenter.unread : "")
    Accessible.name: qsTr("Open the notification drawer")
    onClicked: {
        const monitor = Hyprland.focusedMonitor
        if (monitor) Notif.NotifState.toggle(monitor.name)
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "../mpris" as Mpris

// The media control's bar entry: one icon, the same whatever the player is doing, so the bar
// stays quiet and does not change width. The panel shows the state, and the pin. Clicking opens
// the panel.
Controls.ShellButton {
    id: root
    required property string screenName
    readonly property var selection: Mpris.MprisState.selection
    readonly property var player: selection.current
    readonly property string visibility: Config.Mpris.iconVisibility
    visible: Config.Config.mprisEnabled && (visibility === "always" || (visibility === "whenPlayer" && selection.playerCount > 0))
    emphasis: Theme.Interaction.barEntryEmphasis
    selected: Mpris.MprisState.open && Mpris.MprisState.screenName === screenName
    implicitWidth: Config.Mpris.barIconSize + leftPadding + rightPadding
    Accessible.name: player ? qsTr("Media control, %1").arg(player.trackTitle || player.identity) : qsTr("Media control, nothing playing")
    contentItem: Item {
        Mpris.SvgIcon {
            anchors.centerIn: parent
            name: "audio-player"
            size: Config.Mpris.barIconSize
            color: root.style.text
        }
    }
    onClicked: {
        if (Mpris.MprisState.open && Mpris.MprisState.screenName === screenName) Mpris.MprisState.open = false
        else Mpris.MprisState.show(screenName)
    }
}

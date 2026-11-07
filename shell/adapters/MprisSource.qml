pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The only file that imports Quickshell's MPRIS module. It lists the players on the session bus
// without the playerctld proxy (it would duplicate every real player). The list is a binding on
// the module's model, so it is rebuilt when a player appears or leaves.
Singleton {
    readonly property var players: Mpris.players.values.filter(player => !(player.dbusName ?? "").startsWith("org.mpris.MediaPlayer2.playerctld"))
}

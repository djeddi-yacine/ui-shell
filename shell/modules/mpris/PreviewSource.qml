import QtQuick

// Fake players for UI_SHELL_MPRIS_SOURCE=preview: enough to judge the look and the keys where no
// player runs. Play and pause toggle, the position advances while playing, seek moves it, next
// and previous change the title; one player cannot seek and one reports no length.
QtObject {
    id: root
    // A picture drawn for the preview; the art script reads it as a local file.
    readonly property string cover: Qt.resolvedUrl("preview-cover.png")
    component FakePlayer: QtObject {
        id: player
        property string dbusName: "org.mpris.MediaPlayer2.preview"
        property string identity: ""
        property string desktopEntry: ""
        property var titles: ["First track", "Second track", "Third track"]
        property int index: 0
        readonly property string trackTitle: titles[index]
        property string trackArtist: ""
        property string trackArtUrl: ""
        property bool isPlaying: false
        readonly property bool canTogglePlaying: true
        readonly property bool canPause: true
        readonly property bool canGoNext: true
        readonly property bool canGoPrevious: true
        property bool canSeek: true
        readonly property bool positionSupported: true
        property bool lengthSupported: true
        property real position: 0
        property real length: lengthSupported ? 215 : 0
        function togglePlaying() { isPlaying = !isPlaying }
        function pause() { isPlaying = false }
        function next() { index = (index + 1) % titles.length; position = 0 }
        function previous() { index = (index + titles.length - 1) % titles.length; position = 0 }
        function seek(offset) { position = Math.max(0, Math.min(length, position + offset)) }
        property Timer clock: Timer {
            interval: 1000
            repeat: true
            running: player.isPlaying
            onTriggered: player.position = player.length > 0 ? (player.position + 1) % player.length : player.position + 1
        }
    }
    readonly property var players: [music, browser, fixed, unknown]
    property FakePlayer music: FakePlayer { identity: "Music Player Daemon"; desktopEntry: "mpd"; trackArtist: "An artist"; trackArtUrl: root.cover; isPlaying: true }
    property FakePlayer browser: FakePlayer { identity: "Firefox"; desktopEntry: "firefox"; trackArtist: "A channel"; trackArtUrl: root.cover; titles: ["A video"]; position: 40 }
    property FakePlayer fixed: FakePlayer { identity: "Stream"; desktopEntry: "stream"; trackArtist: "A radio"; titles: ["A live stream"]; canSeek: false }
    property FakePlayer unknown: FakePlayer { identity: "Unknown length"; desktopEntry: "unknown"; titles: ["Length not reported"]; lengthSupported: false }
}

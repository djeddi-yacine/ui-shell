import QtQuick

// Stands in for Quickshell's MprisPlayer: the same members, plus counters for what was called.
QtObject {
    property string dbusName: "org.mpris.MediaPlayer2.fake"
    property string identity: "Fake"
    property string desktopEntry: ""
    property string trackTitle: "A title"
    property string trackArtist: "An artist"
    property string trackArtUrl: ""
    property bool isPlaying: false
    property bool canTogglePlaying: true
    property bool canPause: true
    property bool canGoNext: true
    property bool canGoPrevious: true
    property bool canSeek: true
    property bool positionSupported: true
    property bool lengthSupported: true
    property real position: 30
    property real length: 200
    property int toggleCalls: 0
    property int pauseCalls: 0
    property int nextCalls: 0
    property int previousCalls: 0
    property var seeks: []
    // A player that has quit: Quickshell deletes it, and a call on it fails.
    property bool broken: false
    function check() { if (broken) throw new Error("the player is gone") }
    function togglePlaying() { check(); toggleCalls++; isPlaying = !isPlaying }
    function pause() { check(); pauseCalls++; isPlaying = false }
    function next() { check(); nextCalls++ }
    function previous() { check(); previousCalls++ }
    function seek(offset) { check(); seeks = seeks.concat([offset]) }
}

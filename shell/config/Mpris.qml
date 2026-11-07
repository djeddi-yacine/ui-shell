pragma Singleton
import QtQuick

// The media control: a bar icon, a panel and the media keys. Every value the module uses is
// here; components hold no literals.
QtObject {
    readonly property string namespace: "ui-shell-mpris"
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "media-panel"
    readonly property bool asynchronousPanelLoad: true
    // The bar icon: always, whenPlayer (at least one player exists) or never.
    readonly property string iconVisibility: "whenPlayer"

    // Panel
    // The panel is a square: its width and height are both this many pixels (less on a narrow screen).
    readonly property int panelSize: 460
    readonly property int outerMargin: 24
    // Transport buttons and the icons drawn on them, in pixels.
    readonly property int transportWidth: 72
    readonly property int playWidth: 112
    // The media pictures have empty space around the shape, so they are drawn larger than the shape.
    // Even sizes, so they centre on whole pixels in the (even-sized) buttons.
    readonly property int transportIconSize: 26
    readonly property int playIconSize: 32
    readonly property int arrowIconSize: 16
    readonly property int barIconSize: 18
    // The three-way gap between the title block and the controls.
    readonly property int titleGap: 6
    // The title and artist scroll when they do not fit: speed in pixels a second, and the pause
    // at each end.
    readonly property int marqueeSpeed: 40
    readonly property int marqueePauseMs: 1500
    readonly property int headerIconSize: 18
    readonly property int pinIconSize: 18
    readonly property int selectorDotSize: 6
    // The live bar of a stream: how much of the track the moving segment covers, and how long
    // one sweep takes.
    readonly property real liveSegmentFraction: 0.25
    readonly property int liveSweepMs: 1600
    // Seek and position
    readonly property int seekStepSeconds: 10
    readonly property int positionTickMs: 1000

    // Keys inside the panel. Where the shell already has a key, that key is reused.
    readonly property var panelKeys: ({
        playPause: Keyboard.selectKey,
        next: Qt.Key_N,
        previous: Qt.Key_P,
        seekBack: Keyboard.previousKey,
        seekForward: Keyboard.nextKey,
        pin: Qt.Key_K,
        playerPrevious: Keyboard.rowUpKey,
        playerNext: Keyboard.rowDownKey,
        close: Keyboard.cancelKey
    })
    // The four media keys the shell handles (phase 2). One line per action: tests read them.
    readonly property var keyShortcuts: ({
        playPause: { name: "media-play-pause", description: qsTr("Play or pause") },
        pause: { name: "media-pause", description: qsTr("Pause") },
        next: { name: "media-next", description: qsTr("Next track") },
        previous: { name: "media-previous", description: qsTr("Previous track") }
    })

    // Art (phase 3). A provider is an ordered list of steps; a player's mode picks one.
    // The art setting (Ctrl+E): auto uses the table below for each player; cover, blurhash or off
    // applies to every player. `artDefaultMode` is what auto uses for a player with no entry.
    readonly property string artMode: "auto"
    readonly property string artDefaultMode: "cover"
    readonly property var artModes: ({
        "mpd": "cover", "music player daemon": "cover",
        "firefox": "blurhash", "chromium": "blurhash", "brave-browser": "blurhash",
        "google-chrome": "blurhash", "zen": "blurhash"
    })
    readonly property var providers: ({
        cover: ["fetch"],
        blurhash: ["fetch", "shrink", "blurhash"],
        off: []
    })
    // The dim layer over the art, so the picture never competes with the controls or flashes bright
    // colours at them; and how strongly secondary text is lifted over art.
    readonly property real artScrimOpacity: 0.62
    readonly property real artMutedOpacity: 0.78
    // Longest edge, in pixels, the image control decodes a picture to.
    readonly property int artSourceSize: 640
    readonly property int artShrinkSize: 256
    readonly property string blurhashComponents: "4,3"
    readonly property int blurhashDecodeSize: 32
    readonly property int artDebounceMs: 250
    readonly property int downloadMaxBytes: 20971520
    readonly property int stepTimeoutSeconds: 10
    readonly property int cacheMaxBytes: 67108864
    readonly property int cacheMaxEntries: 40
    readonly property int failureMemorySeconds: 60
    // Art already made for this many recent (player, mode, address) requests is kept in memory and
    // shown again at once, with no step run, when the same state comes back.
    readonly property int hotCacheEntries: 8
    // A change of art fades over this long (the old picture stays opaque until the new one is in;
    // not at all when motion is off).
    readonly property int artFadeMs: 360
    // Set at start by the art adapter from the tool check: false hides the blurhash mode from the
    // settings, and a player set to it uses the cover instead.
    property bool blurhashAvailable: true
    // Shrinking uses the first of these that is installed (vips shrinks a huge picture while loading
    // it; ffmpeg is the fallback). Fetching always uses curl.
    readonly property var shrinkTools: ["vips", "ffmpeg"]
    readonly property string blurhashEncoder: "blurhash_encoder"
    readonly property string blurhashDecoder: "blurhash_decoder"
}

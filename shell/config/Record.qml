pragma Singleton
import QtQuick

// The screen-recording module: its own surface, like the launcher, picker and audio panel.
QtObject {
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "screen-record"
    // Popups are created with the panel; loading it after the first frame keeps the window layout stable.
    readonly property bool asynchronousPanelLoad: true
    readonly property int maximumWidth: 560
    readonly property int maximumHeight: 520
    readonly property int outerMargin: 24
    readonly property int padding: 26
    readonly property int sectionSpacing: 18
    // Countdown before recording starts, in seconds; Ctrl+E offers 0, 3, 5 or 10.
    readonly property int countdownSeconds: 0
    // Record desktop audio; Ctrl+E can turn it off.
    readonly property bool desktopAudio: true
    // Record the microphone as its own audio track; off until Ctrl+E (or the panel) turns it on.
    readonly property bool microphone: false
    // Video settings, all in Ctrl+E. These are the recorder's own knobs, measured on gsr 6.1:
    // frame rate, quality preset, codec ("auto" lets the recorder pick), container, cursor.
    readonly property int fps: 60
    readonly property string quality: "high"
    readonly property string codec: "auto"
    // The audio codec of every track. Opus is the recorder's default for mkv and mp4.
    readonly property string audioCodec: "opus"
    readonly property string container: "mkv"
    // "auto" takes the size from the quality preset; a number is a fixed bitrate in kbps (constant
    // size, which overrides the preset).
    readonly property string bitrate: "auto"
    readonly property bool cursor: true
    // Show the webcam as a small floating window in the corner of the recording (only offered when a
    // camera is connected).
    readonly property bool webcam: false
    // A recording is also re-read this often while it runs (seconds), in case a file event is missed.
    readonly property int safetyRefreshSeconds: 10
    // The clock in the bar and the panel advances this often (milliseconds).
    readonly property int clockTickMilliseconds: 1000
    // The wrapping width of the warning lines in the bar popup.
    readonly property int popupTextMaximumWidth: 320
}

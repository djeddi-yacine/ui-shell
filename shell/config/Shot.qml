pragma Singleton
import QtQuick

// The screenshot module: its own surface, like the recording panel.
QtObject {
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "screen-shot"
    readonly property bool asynchronousPanelLoad: true
    readonly property int maximumWidth: 560
    readonly property int outerMargin: 24
    readonly property int padding: 26
    readonly property int sectionSpacing: 18
    // The panel hides, then the capture waits this long so the compositor has really removed it
    // and it is not in the picture (milliseconds).
    readonly property int closeDelayMilliseconds: 300
    // Where the picture goes; Ctrl+E changes both.
    readonly property bool copyToClipboard: true
    readonly property bool saveToFile: true
}

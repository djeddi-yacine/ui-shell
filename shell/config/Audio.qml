pragma Singleton
import QtQuick

// The audio control module: its own surface, like the launcher, picker and tuning panel.
QtObject {
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "audio-control"
    // Popups are created with the panel; loading it after the first frame keeps the window layout stable.
    readonly property bool asynchronousPanelLoad: true
    readonly property int maximumWidth: 760
    readonly property int maximumHeight: 680
    readonly property int outerMargin: 24
    // Volume sliders go above 100% like pavucontrol; 150 is PipeWire's practical ceiling.
    // Ctrl+E offers 100, 125 or 150.
    readonly property int maximumVolumePercent: 150
    readonly property int refreshDelay: 120
    // Arrow-key step of a volume slider in percent; Ctrl+E offers 1, 2, 5 or 10.
    readonly property int volumeStepPercent: 1
    readonly property int padding: 26
    readonly property int sectionSpacing: 22
    readonly property int rowSpacing: 16
    readonly property int chooserWidth: 200
}

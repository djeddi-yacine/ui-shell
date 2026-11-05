pragma Singleton
import QtQuick

QtObject {
    readonly property int openKey: Qt.Key_T
    readonly property int openModifiers: Qt.ControlModifier
    readonly property int maximumWidth: 720
    readonly property int maximumHeight: 720
    readonly property int verticalMargin: 12
    readonly property int colorColumnsThreshold: 540
    readonly property int roleLabelWidth: 100
    readonly property int hexFieldWidth: 96
    readonly property int modeFieldWidth: 100
    readonly property int swatchSize: 28
    readonly property int swatchPadding: 4
    readonly property int previewHeight: 76
    readonly property int colorPickerWidth: 360
    readonly property int channelMaximum: 255
    readonly property int channelTrackHeight: 4
    readonly property int channelHandleSize: 16
    readonly property string initialSourceId: "wallpaper"
    readonly property string initialCustomName: ""
    readonly property var sources: [
        { id: "wallpaper", label: qsTr("Wallpaper"), kind: "wallpaper" },
        { id: "custom", label: qsTr("Custom"), kind: "custom" }
    ]
    readonly property string initialColorChannel: "red"
    readonly property var colorChannels: [
        { key: "red", label: qsTr("Red") },
        { key: "green", label: qsTr("Green") },
        { key: "blue", label: qsTr("Blue") }
    ]
    readonly property var roles: [
        { key: "background", label: qsTr("Background"), description: qsTr("Main background.") },
        { key: "surface", label: qsTr("Surface"), description: qsTr("Panel and control surface.") },
        { key: "surfaceVariant", label: qsTr("Variant"), description: qsTr("Alternate surface.") },
        { key: "elevated", label: qsTr("Elevated"), description: qsTr("Raised popup surface.") },
        { key: "text", label: qsTr("Text"), description: qsTr("Main foreground.") },
        { key: "textMuted", label: qsTr("Muted text"), description: qsTr("Secondary foreground.") },
        { key: "accent", label: qsTr("Accent"), description: qsTr("Primary selection color.") },
        { key: "positive", label: qsTr("Positive"), description: qsTr("Positive status and current-choice color.") },
        { key: "warning", label: qsTr("Warning"), description: qsTr("Warning status color.") },
        { key: "negative", label: qsTr("Negative"), description: qsTr("Error status color.") },
        { key: "outline", label: qsTr("Outline"), description: qsTr("Neutral control boundary.") },
        { key: "focus", label: qsTr("Focus"), description: qsTr("Keyboard focus color.") },
        { key: "scrim", label: qsTr("Scrim"), description: qsTr("Overlay dimming color.") }
    ]
}

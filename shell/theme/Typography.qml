pragma Singleton

import QtQuick

QtObject {
    readonly property string uiFamily: "Sans Serif"
    readonly property string monoFamily: "Monospace"
    readonly property real basePointSize: 12
    readonly property real scaleRatio: 1.2
    readonly property real bodyPointSize: basePointSize
    readonly property real captionPointSize: basePointSize / scaleRatio
    readonly property real titlePointSize: basePointSize * scaleRatio * scaleRatio
    readonly property int bodyWeight: Font.Normal
    readonly property int emphasisWeight: Font.Medium
}

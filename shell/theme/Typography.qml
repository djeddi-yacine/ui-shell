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
    // Small text inside a chip, and a big readout (a clock).
    readonly property real microPointSize: captionPointSize / scaleRatio
    readonly property real displayPointSize: basePointSize * scaleRatio * scaleRatio * scaleRatio
    // Spaced capitals for section labels and chips.
    readonly property real labelLetterSpacing: 1.2
    readonly property real chipLetterSpacing: 0.6
    readonly property int bodyWeight: Font.Normal
    readonly property int emphasisWeight: Font.Medium
}

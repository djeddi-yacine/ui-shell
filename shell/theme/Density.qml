pragma Singleton

import QtQuick

QtObject {
    readonly property string preset: "comfortable"

    readonly property int spacing: 12
    readonly property int controlHeight: 36
    readonly property int controlPaddingX: 12
    readonly property int controlPaddingY: 6
    readonly property int menuMaximumHeight: 288
    readonly property int menuViewportMargin: 12
    readonly property int barHeight: 32
}

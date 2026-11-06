pragma Singleton
import QtQuick

QtObject {
    readonly property int maximumWidth: 520
    readonly property int outerMargin: 36
    readonly property int padding: 20
    readonly property int spacing: 12
    readonly property real scrimOpacity: 0.24
    // The settings popup scrolls its option list above this height; the label column is fixed.
    readonly property int maximumOptionsHeight: 320
    readonly property int optionLabelWidth: 150
    readonly property string initialSettingsScope: "output"
}

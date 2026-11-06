pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../config" as Config

ColumnLayout {
    id: root
    required property var style
    required property var bindings
    spacing: Config.ContextPanels.spacing
    Text {
        Layout.fillWidth: true
        text: qsTr("Keys")
        color: root.style.text
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
        font.weight: root.style.emphasisWeight
    }
    Repeater {
        model: root.bindings
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: Config.ContextPanels.spacing
            Shortcut { id: sequence; sequence: Config.Keyboard.shortcut(row.modelData.key, row.modelData.modifiers); enabled: false }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                text: row.modelData.action
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.style.textMuted
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
            Text {
                Layout.alignment: Qt.AlignTop
                text: sequence.nativeText
                color: root.style.text
                font.family: root.style.monoFamily
                font.pointSize: root.style.bodyPointSize
            }
        }
    }
}

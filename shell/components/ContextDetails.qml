pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../config" as Config

ColumnLayout {
    id: root
    required property var style
    required property string title
    required property string description
    required property var details
    spacing: Config.ContextPanels.spacing
    Text {
        Layout.fillWidth: true
        text: root.title
        textFormat: Text.PlainText
        wrapMode: Text.WrapAnywhere
        color: root.style.text
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
        font.weight: root.style.emphasisWeight
    }
    Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.description
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: root.style.textMuted
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
    }
    Repeater {
        model: root.details
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Config.ContextPanels.spacing
            Text {
                text: parent.modelData.label
                color: root.style.textMuted
                font.family: root.style.uiFamily
                font.pointSize: root.style.captionPointSize
            }
            Text {
                Layout.fillWidth: true
                text: parent.modelData.value
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                color: root.style.text
                font.family: root.style.monoFamily
                font.pointSize: root.style.captionPointSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

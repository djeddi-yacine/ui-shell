import QtQuick
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

RowLayout {
    id: root
    required property var role
    required property var style
    required property InputState inputState
    required property string value
    signal edited(string color)
    signal pickRequested()
    readonly property bool editorFocused: hex.activeFocus || swatch.activeFocus
    spacing: Config.ContextPanels.spacing
    Text {
        Layout.preferredWidth: Config.ThemeEditor.roleLabelWidth
        text: root.role.label
        elide: Text.ElideRight
        color: root.style.text
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
    }
    ShellButton {
        id: swatch
        objectName: "paletteSwatch"
        Layout.preferredWidth: Config.ThemeEditor.swatchSize
        Layout.preferredHeight: Config.ThemeEditor.swatchSize
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.buttonEmphasis
        padding: Config.ThemeEditor.swatchPadding
        leftPadding: Config.ThemeEditor.swatchPadding
        rightPadding: Config.ThemeEditor.swatchPadding
        Accessible.name: qsTr("Pick %1 color").arg(root.role.label)
        onClicked: root.pickRequested()
        contentItem: Rectangle { color: root.value; Accessible.ignored: true }
    }
    ShellTextField {
        id: hex
        objectName: "paletteHex"
        Layout.fillWidth: true
        Layout.minimumWidth: Config.ThemeEditor.hexFieldWidth
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.inputEmphasis
        text: root.value
        font.family: root.style.monoFamily
        maximumLength: 7
        validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
        Accessible.name: qsTr("%1 hexadecimal color").arg(root.role.label)
        onTextEdited: if (acceptableInput) root.edited(text.toLowerCase())
        onEditingFinished: text = Qt.binding(() => root.value)
    }
}

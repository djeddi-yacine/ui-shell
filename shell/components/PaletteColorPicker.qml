pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

ContextPopup {
    id: root
    objectName: "paletteColorPicker"
    property var role
    property color seedColor: root.style.accent
    property var channels: ({ red: Math.round(seedColor.r * Config.ThemeEditor.channelMaximum),
        green: Math.round(seedColor.g * Config.ThemeEditor.channelMaximum),
        blue: Math.round(seedColor.b * Config.ThemeEditor.channelMaximum) })
    readonly property color value: Qt.rgba(channels.red / Config.ThemeEditor.channelMaximum,
        channels.green / Config.ThemeEditor.channelMaximum, channels.blue / Config.ThemeEditor.channelMaximum, 1)
    primaryAction: chooseButton
    signal chosen(string color)
    // A colour you changed and did not use is unsaved work: leaving asks first.
    readonly property bool dirty: !Qt.colorEqual(value, seedColor)
    closePolicy: dirty ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    function requestClose() { exitDialog.request(dirty, root.owner.Window.window ? root.owner.Window.window.activeFocusItem : null) }
    ExitDialog {
        id: exitDialog
        owner: root.owner
        style: root.style
        inputState: root.inputState
        z: 3
        message: qsTr("This color is not used yet.")
        onConfirmed: root.close()
    }
    shortcutsEnabled: false
    width: Math.min(owner.width - Config.ContextPanels.outerMargin * 2, Config.ThemeEditor.colorPickerWidth)
    // The slider of the channel named by initialColorChannel, set by that channel's row.
    property Slider initialControl: null
    onOpened: {
        if (!initialControl) throw new Error("Configure a named initial RGB channel")
        initialControl.forceActiveFocus()
    }

    function begin(nextRole, color, previousFocus) {
        role = nextRole
        seedColor = color
        channels = { red: Math.round(seedColor.r * Config.ThemeEditor.channelMaximum),
            green: Math.round(seedColor.g * Config.ThemeEditor.channelMaximum),
            blue: Math.round(seedColor.b * Config.ThemeEditor.channelMaximum) }
        show("color", previousFocus)
    }
    function channel(key, next) {
        channels = Object.assign({}, channels, { [key]: Math.round(next) })
    }
    contentItem: ColumnLayout {
        spacing: Config.ContextPanels.spacing
        Keys.onPressed: event => {
            if (event.key === Config.Keyboard.cancelKey) { root.requestClose(); event.accepted = true }
        }
        Text {
            Layout.fillWidth: true
            text: root.role ? root.role.label : ""
            color: root.style.text
            font.family: root.style.uiFamily
            font.pointSize: root.style.bodyPointSize
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Config.ThemeEditor.swatchSize
            color: root.value
            border.width: Theme.Shape.borderWidth
            border.color: root.style.outline
            Accessible.ignored: true
        }
        Repeater {
            id: channelRows
            model: Config.ThemeEditor.colorChannels
            RowLayout {
                id: row
                required property var modelData
                readonly property Slider control: channel
                Binding {
                    target: root
                    property: "initialControl"
                    value: row.control
                    when: row.modelData.key === Config.ThemeEditor.initialColorChannel
                }
                Layout.fillWidth: true
                spacing: Config.ContextPanels.spacing
                Text {
                    Layout.preferredWidth: Config.ThemeEditor.roleLabelWidth
                    text: row.modelData.label
                    color: root.style.text
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.bodyPointSize
                }
                ShellSlider {
                    id: channel
                    objectName: "paletteChannel-" + row.modelData.key
                    style: root.style
                    inputState: root.inputState
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.style.controlHeight
                    from: 0
                    to: Config.ThemeEditor.channelMaximum
                    stepSize: 1
                    value: root.channels[row.modelData.key]
                    Accessible.name: row.modelData.label
                    onMoved: root.channel(row.modelData.key, value)
                }
                Text {
                    Layout.preferredWidth: Config.ThemeEditor.swatchSize
                    text: String(root.channels[row.modelData.key])
                    color: root.style.textMuted
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.bodyPointSize
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: String(root.value)
                color: root.style.text
                font.family: root.style.monoFamily
                font.pointSize: root.style.bodyPointSize
            }
            ShellButton {
                id: chooseButton
                objectName: "paletteColorChoose"
                text: qsTr("Use color")
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.primaryActionEmphasis
                onClicked: { root.chosen(String(root.value)); root.close() }
            }
        }
    }
}

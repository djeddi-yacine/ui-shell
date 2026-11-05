pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme
import "../../config" as Config
import "../../components" as Controls

RowLayout {
    id: root
    required property var style
    required property string statusText
    required property bool busy
    required property bool canContinue
    required property Controls.InputState inputState
    required property Item nextFocus
    required property Item previousFocus
    readonly property alias actionControl: apply
    signal themeRequested()
    spacing: root.style.spacing
    Text {
        Layout.fillWidth: true
        text: root.statusText
        textFormat: Text.PlainText
        color: root.style.textMuted
        font.family: root.style.uiFamily
        font.pointSize: root.style.captionPointSize
        wrapMode: Text.Wrap
    }
    Controls.ShellButton {
        id: apply
        objectName: "chooseTheme"
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.primaryActionEmphasis
        Layout.preferredWidth: Config.WallpaperPicker.actionWidth
        text: qsTr("Choose theme")
        enabled: root.canContinue && !root.busy
        onClicked: root.themeRequested()
        KeyNavigation.priority: KeyNavigation.AfterItem
        KeyNavigation.tab: root.nextFocus
        KeyNavigation.backtab: root.previousFocus
    }
}

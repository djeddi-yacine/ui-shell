pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme
import "../../config" as Config
import "../../components" as Controls

GridLayout {
    id: root
    required property var style
    required property var targets
    required property int targetIndex
    required property bool busy
    required property string query
    required property Controls.InputState inputState
    required property Item nextFocus
    required property Item previousFocus
    readonly property bool targetFocused: displaySelect.activeFocus
    readonly property alias searchField: search
    readonly property alias targetControl: displaySelect
    signal targetChosen(int index)
    signal queryEdited(string query)
    signal searchKeyPressed(var event)
    readonly property bool inlineLayout: width >= Config.WallpaperPicker.headerInlineThreshold
    columns: inlineLayout ? 2 : 1
    columnSpacing: root.style.spacing
    rowSpacing: root.style.spacing
    Controls.ShellTextField {
        id: search
        objectName: "wallpaperSearchInput"
        Layout.fillWidth: true
        Layout.row: 0
        Layout.column: 0
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.inputEmphasis
        Accessible.name: qsTr("Search local wallpapers")
        placeholderText: qsTr("Filter by filename…")
        text: root.query
        enabled: !root.busy
        onTextChanged: root.queryEdited(text)
        Keys.onPressed: event => root.searchKeyPressed(event)
        KeyNavigation.priority: KeyNavigation.AfterItem
        KeyNavigation.tab: displaySelect
        KeyNavigation.backtab: root.previousFocus
    }
    Controls.ShellComboBox {
        id: displaySelect
        objectName: "wallpaperTarget"
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.selectorEmphasis
        optionEmphasis: Theme.Interaction.selectorOptionEmphasis
        Layout.row: root.inlineLayout ? 0 : 1
        Layout.column: root.inlineLayout ? 1 : 0
        Layout.alignment: Qt.AlignRight
        Layout.preferredWidth: Config.WallpaperPicker.targetWidth
        model: root.targets
        textRole: "label"
        Accessible.name: qsTr("Default wallpaper or display override")
        enabled: !root.busy
        Binding { target: displaySelect; property: "currentIndex"; value: root.targetIndex }
        onActivated: index => root.targetChosen(index)
        KeyNavigation.priority: KeyNavigation.AfterItem
        KeyNavigation.tab: root.nextFocus
        KeyNavigation.backtab: search
    }
}

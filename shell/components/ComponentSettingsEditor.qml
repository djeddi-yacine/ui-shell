pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../adapters" as Adapters
import "../theme" as Theme
import "../config" as Config

ColumnLayout {
    id: root
    required property Adapters.ComponentSettings settings
    required property var style
    required property InputState inputState
    property string scope: Config.ContextPanels.initialSettingsScope
    property string revision: ""
    property bool awaitingScope: false
    property bool committing: false
    property var firstValue: undefined
    property var secondValue: undefined
    readonly property bool launcher: settings.component === "launcher"
    readonly property var file: settings.fileForScope(scope)
    readonly property var firstChoices: [{ label: defaultLabel(firstKey, firstDefault), value: undefined }].concat(launcher
        ? [{ label: qsTr("On"), value: true }, { label: qsTr("Off"), value: false }]
        : integers(1, 6))
    readonly property var secondChoices: [{ label: defaultLabel(secondKey, secondDefault), value: undefined }].concat(integers(1, launcher ? 24 : 4))
    readonly property string firstKey: launcher ? "showIcons" : "wideColumns"
    readonly property string secondKey: launcher ? "visibleRows" : "maximumVisibleRows"
    readonly property var firstDefault: launcher ? Config.AppLauncher.showIcons : Config.WallpaperPicker.wideColumns
    readonly property int secondDefault: launcher ? Config.AppLauncher.visibleRows : Config.WallpaperPicker.maximumVisibleRows
    readonly property string error: settings.saveError || file.error
    readonly property bool editable: file.ready && !awaitingScope && !settings.busy && !file.error
    readonly property ShellButton primaryAction: saveButton
    signal saved()
    spacing: Config.ContextPanels.spacing

    function integers(first, last) {
        const values = []
        for (let value = first; value <= last; value++) values.push({ label: String(value), value: value })
        return values
    }
    function defaultLabel(key, configuredDefault) {
        const value = scope === "default" ? configuredDefault : settings.sharedValue(key, configuredDefault)
        return qsTr("Default (%1)").arg(typeof value === "boolean" ? (value ? qsTr("On") : qsTr("Off")) : String(value))
    }
    function indexFor(choices, value) { return choices.findIndex(choice => choice.value === value) }
    function begin() { loadScope(Config.ContextPanels.initialSettingsScope); scopeControl.forceActiveFocus() }
    function loadScope(nextScope) {
        scope = nextScope
        awaitingScope = true
        settings.saveError = ""
        settings.fileForScope(scope).refresh()
    }
    function readDraft() {
        revision = file.revision
        firstValue = file.values[firstKey]
        secondValue = file.values[secondKey]
        awaitingScope = false
    }
    function save() {
        if (!editable) return
        committing = true
        settings.save(scope, revision, firstValue, secondValue)
    }
    Connections {
        target: root.settings
        function onScopeReady(scope) { if (root.awaitingScope && scope === root.scope) root.readDraft() }
        function onCommitted(scope) {
            if (root.committing && scope === root.scope) { root.committing = false; root.saved() }
        }
        function onFailed() { root.committing = false }
    }
    Text {
        Layout.fillWidth: true
        text: qsTr("Settings")
        color: root.style.text
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
        font.weight: root.style.emphasisWeight
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Config.ContextPanels.spacing
        rowSpacing: Config.ContextPanels.spacing
        Text { text: qsTr("Scope"); color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
        ShellComboBox {
            id: scopeControl
            objectName: "settingsScope"
            Layout.fillWidth: true
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            model: [{ label: qsTr("Default"), value: "default" }, { label: root.settings.screenName, value: "output" }]
            textRole: "label"
            currentIndex: root.scope === "default" ? 0 : 1
            enabled: !root.settings.busy
            Accessible.name: qsTr("Settings scope")
            onActivated: index => root.loadScope(model[index].value)
        }
        Text { text: root.launcher ? qsTr("Icons") : qsTr("Columns"); color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
        ShellComboBox {
            objectName: "settingsFirstChoice"
            Layout.fillWidth: true
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            model: root.firstChoices
            textRole: "label"
            currentIndex: root.indexFor(root.firstChoices, root.firstValue)
            enabled: root.editable
            Accessible.name: root.launcher ? qsTr("Application icons") : qsTr("Wide wallpaper grid columns")
            onActivated: index => root.firstValue = root.firstChoices[index].value
        }
        Text { text: qsTr("Rows"); color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
        ShellComboBox {
            objectName: "settingsRowsChoice"
            Layout.fillWidth: true
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            model: root.secondChoices
            textRole: "label"
            currentIndex: root.indexFor(root.secondChoices, root.secondValue)
            enabled: root.editable
            Accessible.name: qsTr("Visible rows")
            onActivated: index => root.secondValue = root.secondChoices[index].value
        }
    }
    Text {
        Layout.fillWidth: true
        text: root.file.path
        textFormat: Text.PlainText
        wrapMode: Text.WrapAnywhere
        color: root.style.textMuted
        font.family: root.style.monoFamily
        font.pointSize: root.style.captionPointSize
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.ContextPanels.spacing
        ShellButton {
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            text: qsTr("Reload")
            enabled: !root.settings.busy
            onClicked: root.loadScope(root.scope)
        }
        Item { Layout.fillWidth: true }
        ShellButton {
            id: saveButton
            objectName: "settingsSave"
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.primaryActionEmphasis
            text: root.settings.busy ? qsTr("Saving…") : qsTr("Save")
            enabled: root.editable
            onClicked: root.save()
        }
    }
}

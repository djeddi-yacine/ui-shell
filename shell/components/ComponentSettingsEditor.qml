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
    readonly property var file: settings.fileForScope(scope)
    // The component's two options come from Config.ComponentSpec.
    readonly property var first: Config.ComponentSpec.components[settings.component][0]
    readonly property var second: Config.ComponentSpec.components[settings.component][1]
    readonly property string firstKey: first.key
    readonly property string secondKey: second.key
    readonly property var firstChoices: choicesFor(first)
    readonly property var secondChoices: choicesFor(second)
    readonly property string error: settings.saveError || file.error
    readonly property bool editable: file.ready && !awaitingScope && !settings.busy && !file.error
    readonly property ShellButton primaryAction: saveButton
    // Unsaved: the draft differs from the file it was read from.
    readonly property bool dirty: file.ready && !awaitingScope
        && (firstValue !== file.values[firstKey] || secondValue !== file.values[secondKey])
    signal saved()
    spacing: Config.ContextPanels.spacing

    function integers(first, last) {
        const values = []
        for (let value = first; value <= last; value++) values.push({ label: String(value), value: value })
        return values
    }
    function choicesFor(option) {
        const inherited = { label: defaultLabel(option.key, option.fallback), value: undefined }
        if (option.kind === "boolean") return [inherited, { label: qsTr("On"), value: true }, { label: qsTr("Off"), value: false }]
        if (option.kind === "choices") return [inherited].concat(option.choices.map(value => ({ label: String(value), value: value })))
        return [inherited].concat(integers(option.min, option.max))
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
        Text { text: root.first.label; color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
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
            Accessible.name: root.first.name
            onActivated: index => root.firstValue = root.firstChoices[index].value
        }
        Text { text: root.second.label; color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
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
            Accessible.name: root.second.name
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

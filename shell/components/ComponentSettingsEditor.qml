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
    // The draft: option key -> chosen value (undefined = use the default).
    property var drafts: ({})
    readonly property var file: settings.fileForScope(scope)
    // The component's options come from Config.ComponentSpec; there can be any number of them.
    readonly property var options: Config.ComponentSpec.components[settings.component]
    readonly property string error: settings.saveError || file.error
    readonly property bool editable: file.ready && !awaitingScope && !settings.busy && !file.error
    readonly property ShellButton primaryAction: saveButton
    // Unsaved: the draft differs from the file it was read from.
    readonly property bool dirty: file.ready && !awaitingScope
        && options.some(option => drafts[option.key] !== file.values[option.key])
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
        if (option.kind === "choices") return [inherited].concat(option.choices.filter(value => option.available ? option.available(value) : true).map(value => ({ label: option.labels?.[value] ?? String(value), value: value })))
        return [inherited].concat(integers(option.min, option.max))
    }
    function defaultLabel(key, configuredDefault) {
        const value = scope === "default" ? configuredDefault : settings.sharedValue(key, configuredDefault)
        return qsTr("Default (%1)").arg(typeof value === "boolean" ? (value ? qsTr("On") : qsTr("Off")) : (labelOf(key, value)))
    }
    function labelOf(key, value) {
        const option = options.find(item => item.key === key)
        return option?.labels?.[value] ?? String(value)
    }
    function setDraft(key, value) { const next = Object.assign({}, drafts); next[key] = value; drafts = next }
    // By position in the option list (the settings GUI tests address options this way).
    function draftAt(index) { return drafts[options[index].key] }
    function setDraftAt(index, value) { setDraft(options[index].key, value) }
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
        const next = {}
        for (const option of options) next[option.key] = file.values[option.key]
        drafts = next
        awaitingScope = false
    }
    function save() {
        if (!editable) return
        committing = true
        settings.save(scope, revision, options.map(option => drafts[option.key]))
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
        Text { Layout.preferredWidth: Config.ContextPanels.optionLabelWidth; text: qsTr("Scope"); color: root.style.textMuted; font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
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
    }
    // The options scroll when they do not fit; the scope and the buttons stay in place.
    Flickable {
        id: optionsFlick
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(optionList.implicitHeight, Config.ContextPanels.maximumOptionsHeight)
        contentWidth: width
        contentHeight: optionList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        function reveal(item) {
            if (!item) return
            const y = item.mapToItem(optionsFlick.contentItem, 0, 0).y
            if (y < contentY) contentY = y
            else if (y + item.height > contentY + height) contentY = y + item.height - height
        }
        ColumnLayout {
            id: optionList
            width: optionsFlick.width
            spacing: Config.ContextPanels.spacing
            Repeater {
                model: root.options
                RowLayout {
                    id: optionRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Config.ContextPanels.spacing
                    readonly property var choices: root.choicesFor(modelData)
                    Text {
                        Layout.preferredWidth: Config.ContextPanels.optionLabelWidth
                        text: optionRow.modelData.label
                        color: root.style.textMuted
                        font.family: root.style.uiFamily
                        font.pointSize: root.style.bodyPointSize
                    }
                    ShellComboBox {
                        id: choiceBox
                        objectName: "settingsChoice-" + optionRow.modelData.key
                        Layout.fillWidth: true
                        style: root.style
                        inputState: root.inputState
                        emphasis: Theme.Interaction.selectorEmphasis
                        optionEmphasis: Theme.Interaction.selectorOptionEmphasis
                        model: optionRow.choices
                        textRole: "label"
                        currentIndex: root.indexFor(optionRow.choices, root.drafts[optionRow.modelData.key])
                        enabled: root.editable
                        Accessible.name: optionRow.modelData.name
                        onActiveFocusChanged: if (activeFocus) optionsFlick.reveal(optionRow)
                        onActivated: index => root.setDraft(optionRow.modelData.key, optionRow.choices[index].value)
                    }
                }
            }
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

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

// Schema-driven editor for the control-colour model. Rows come from
// Theme.ControlTuning.schema (rendered by scripts/render-control-tuning), so a
// new knob appears here with no change to this file. Moving a slider previews
// live on every control through Theme.ControlTuning.draft; Save writes the file,
// Reset returns to the generated defaults, closing without Save drops the draft.
ColumnLayout {
    id: root
    required property var style
    required property InputState inputState
    // Persistence (Adapters.ControlTuningStore): ready, busy, error, save(values), saved().
    required property var store
    // Working values for every knob; starts at the saved/default values.
    property var draft: ({})
    property string draftMode: Theme.ControlTuning.mode
    property bool committing: false
    readonly property var schema: Theme.ControlTuning.schema
    readonly property var groups: {
        const names = []
        for (const knob of schema)
            if (!names.includes(knob.group)) names.push(knob.group)
        return names.map(name => ({ name: name, knobs: schema.filter(knob => knob.group === name) }))
    }
    readonly property var modeEntry: Theme.ControlTuning.modes.find(entry => entry.key === draftMode) ?? null
    // One line saying what the mode makes controls do, from its behaviour flags.
    readonly property string behaviorSummary: {
        const flags = modeEntry ? modeEntry.behavior.flags : null
        if (!flags) return ""
        return [flags.hover === "none" ? qsTr("Hover: ignored") : qsTr("Hover: feedback"),
            flags.focusVisible === "always" ? qsTr("Focus: always shown") : qsTr("Focus: keyboard only"),
            flags.restingBorder === "none" ? qsTr("Borders: none at rest") : qsTr("Borders: outline at rest"),
            flags.currentMarker ? qsTr("Applied marker: on") : qsTr("Applied marker: off"),
            flags.animate ? qsTr("Animated") : qsTr("Instant")].join(" · ")
    }
    readonly property var preset: Theme.ControlTuning.presetValues(draftMode)
    readonly property bool modified: schema.some(knob => draft[knob.key] !== undefined && draft[knob.key] !== preset[knob.key])
    readonly property ShellButton primaryAction: saveButton
    signal saved()
    signal dismissed()
    spacing: Config.ContextPanels.spacing

    function begin() {
        draftMode = Theme.ControlTuning.mode
        Theme.ControlTuning.draftMode = ""
        draft = Object.assign({}, Theme.ControlTuning.defaults, Theme.ControlTuning.overrides)
        Theme.ControlTuning.draft = ({})
        firstSlider.forceActiveFocus()
    }
    function setValue(knob, value) {
        const rounded = Math.round(value / knob.step) * knob.step
        const next = Object.assign({}, draft)
        next[knob.key] = Number(rounded.toFixed(4))
        draft = next
        Theme.ControlTuning.draft = next
    }
    // Switching mode replaces every knob with that mode's preset, previewed live.
    function applyMode(key) {
        draftMode = key
        Theme.ControlTuning.draftMode = key
        draft = Theme.ControlTuning.presetValues(key)
        Theme.ControlTuning.draft = draft
    }
    function reset() { applyMode(draftMode) }
    function discard() {
        Theme.ControlTuning.draft = ({})
        Theme.ControlTuning.draftMode = ""
    }
    function save() {
        committing = true
        store.save(draftMode, draft)
    }
    Component.onDestruction: discard()
    Connections {
        target: root.store
        function onSaved() {
            if (!root.committing) return
            root.committing = false
            root.discard()
            root.saved()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.ContextPanels.spacing
        Repeater {
            model: Theme.ControlTuning.modes
            ShellButton {
                id: modeButton
                required property var modelData
                objectName: "tuningMode-" + modelData.key
                text: modelData.label
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                selected: root.draftMode === modelData.key
                Accessible.description: modelData.description
                onClicked: root.applyMode(modelData.key)
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: root.modeEntry ? root.modeEntry.description + (root.modified ? "  " + qsTr("(modified)") : "")
            + "\n" + root.behaviorSummary : ""
        color: root.style.textMuted
        wrapMode: Text.Wrap
        font.family: root.style.uiFamily
        font.pointSize: root.style.captionPointSize
    }
    // Two independent columns (groups alternate) so a short group never leaves a gap.
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.ContextPanels.spacing * 2
        Repeater {
            model: [0, 1]
            ColumnLayout {
                id: column
                required property int modelData
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Config.ContextPanels.spacing
        Repeater {
            model: root.groups.filter((entry, position) => position % 2 === column.modelData)
            ColumnLayout {
                id: group
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2
                Text {
                    text: group.modelData.name
                    color: root.style.controls.muted
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.captionPointSize
                    font.weight: root.style.emphasisWeight
                }
                Repeater {
                    model: group.modelData.knobs
                    RowLayout {
                        id: row
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: Config.ContextPanels.spacing
                        Text {
                            Layout.preferredWidth: 170
                            text: row.modelData.label
                            color: root.style.text
                            elide: Text.ElideRight
                            font.family: root.style.uiFamily
                            font.pointSize: root.style.bodyPointSize
                        }
                        ShellSlider {
                            id: slider
                            objectName: "tuning-" + row.modelData.key
                            style: root.style
                            inputState: root.inputState
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.style.controlHeight
                            from: row.modelData.min
                            to: row.modelData.max
                            stepSize: row.modelData.step
                            value: root.draft[row.modelData.key] ?? row.modelData.default
                            Accessible.name: row.modelData.label
                            Accessible.description: row.modelData.description
                            onMoved: root.setValue(row.modelData, value)
                            Component.onCompleted: if (column.modelData === 0 && group.index === 0 && row.index === 0) firstSlider.target = slider
                        }
                        Text {
                            Layout.preferredWidth: 44
                            text: String(root.draft[row.modelData.key] ?? row.modelData.default)
                            color: root.draft[row.modelData.key] !== row.modelData.default ? root.style.controls.primary : root.style.controls.muted
                            font.family: root.style.monoFamily
                            font.pointSize: root.style.captionPointSize
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: root.store.error.length > 0
        text: root.store.error
        color: root.style.negative
        wrapMode: Text.Wrap
        font.family: root.style.uiFamily
        font.pointSize: root.style.captionPointSize
    }
    RowLayout {
        Layout.fillWidth: true
        ShellButton {
            id: resetButton
            objectName: "tuningReset"
            text: qsTr("Reset mode")
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            onClicked: root.reset()
        }
        Item { Layout.fillWidth: true }
        ShellButton {
            id: saveButton
            objectName: "tuningSave"
            text: qsTr("Save")
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.primaryActionEmphasis
            enabled: !root.store.busy && root.store.ready
            onClicked: root.save()
        }
    }
    // The first slider takes initial focus; set once its row exists.
    QtObject {
        id: firstSlider
        property Item target: null
        function forceActiveFocus() { if (target) target.forceActiveFocus() }
    }
}

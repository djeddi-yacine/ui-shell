pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Config
import "../theme" as Theme

// Persistence for the control-colour model. The saved file is QML rendered by
// scripts/render-control-tuning (which owns the schema and defaults); this reads
// it into Theme.ControlTuning.overrides and writes it back through the same
// locked, revision-checked path the other component settings use.
Singleton {
    id: root
    readonly property bool ready: file.ready
    readonly property bool busy: writer.running
    readonly property string error: saveError || file.error
    readonly property string revision: file.revision
    property string saveError: ""
    signal saved()

    // Only knobs the current schema knows: an old file must not smuggle keys in.
    function known(values) {
        const result = {}
        for (const knob of Theme.ControlTuning.schema)
            if (typeof values[knob.key] === "number") result[knob.key] = values[knob.key]
        return result
    }
    function reload() { file.refresh() }
    // Saves a mode and `values` ({ key: number }); only knobs that differ from the
    // mode's preset are stored as overrides.
    function save(mode, values) {
        if (busy) return
        saveError = ""
        const preset = Theme.ControlTuning.presetValues(mode)
        const entries = ["mode=" + mode].concat(Theme.ControlTuning.schema
            .filter(knob => values[knob.key] !== undefined && values[knob.key] !== preset[knob.key])
            .map(knob => knob.key + "=" + values[knob.key]))
        writer.command = [Config.GeneratedRuntime.commands.saveComponentSettings, "controls", "default", "",
            file.revision].concat(entries)
        writer.running = true
    }

    Binding { target: Theme.ControlTuning; property: "overrides"; value: root.known(file.values) }
    Binding { target: Theme.ControlTuning; property: "mode"; value: file.mode || Theme.GeneratedControlTuning.mode }
    QmlSettingsFile {
        id: file
        component: "controls"
        scope: "default"
        outputName: ""
        onSettled: if (root.waiting) { root.waiting = false; if (!file.error) root.saved() }
    }
    property bool waiting: false
    Process {
        id: writer
        stderr: StdioCollector { id: writerError }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.saveError = writerError.text.trim() || qsTr("Could not save control tuning.")
                return
            }
            root.waiting = true
            file.refresh()
        }
    }
}

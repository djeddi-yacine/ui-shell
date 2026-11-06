import QtQuick
import Quickshell.Io
import "../config" as Config

// The live PipeWire graph for the audio module. `scripts/audio-graph snapshot` is
// the single source of truth; while `active`, `pw-dump --monitor` (PipeWire itself)
// only says when to take a new one. Actions run one at a time, and a keyed action (a slider drag)
// replaces its own waiting predecessor so only the newest value is sent.
Item {
    id: root
    property bool active: false
    property var graph: ({ defaults: {}, sinks: [], sources: [], streams: [], cards: [], ports: [], links: [] })
    property bool ready: false
    property string error: ""
    readonly property string command: Config.GeneratedRuntime.commands.audioGraph ?? ""

    property var queue: []

    function refresh() { debounce.restart() }
    // `key` coalesces: a waiting action with the same key is replaced.
    function run(args, key) {
        if (!command) { error = qsTr("The audio helper is not installed."); return }
        const entry = { args: args, key: key ?? "" }
        const at = key ? queue.findIndex(waiting => waiting.key === key) : -1
        if (at >= 0) queue[at] = entry
        else queue.push(entry)
        next()
    }
    function next() {
        if (actor.running || queue.length === 0) return
        const entry = queue.shift()
        actor.command = [command].concat(entry.args.map(String))
        actor.running = true
    }
    onActiveChanged: if (active) refresh()

    Timer {
        id: debounce
        interval: Config.Audio.refreshDelay
        onTriggered: { if (root.active && !reader.running && root.command) reader.running = true }
    }
    Process {
        id: reader
        command: [root.command, "snapshot"]
        stdout: StdioCollector { id: snapshot }
        stderr: StdioCollector { id: readerError }
        onExited: function(code) {
            if (code !== 0) { root.error = readerError.text.trim() || qsTr("Could not read the PipeWire graph."); return }
            try { root.graph = JSON.parse(snapshot.text); root.ready = true; root.error = "" }
            catch (failure) { root.error = qsTr("The audio helper returned unreadable data.") }
        }
    }
    Process {
        id: actor
        stderr: StdioCollector { id: actorError }
        onExited: function(code) {
            root.error = code === 0 ? "" : actorError.text.trim() || qsTr("An audio action failed.")
            root.refresh()
            root.next()
        }
    }
    Process {
        id: watcher
        running: root.active
        // Compact output: one change is a few lines, and every line only nudges the debounce.
        command: ["pw-dump", "--monitor", "--no-colors", "--indent", "0"]
        stdout: SplitParser { onRead: root.refresh() }
    }
}

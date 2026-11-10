pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Config

// Reads and changes the clipboard history through scripts/clipboard. The history itself belongs to
// cliphist; this singleton holds nothing but the last answer. Clipboard content never appears in an
// argument or in a failure: an entry travels to the script on standard input as its list line, and
// failures carry fixed texts only.
Singleton {
    id: root
    readonly property string command: Config.GeneratedRuntime.commands.clipboard ?? ""
    // "unknown" until the first answer; otherwise a state the script reports (ok, no-cliphist,
    // no-wl-clipboard, no-tool, store-outside-runtime, watcher-off) or "failed" when the script itself failed.
    property string state: "unknown"
    // The tool the state names, when it names one (state "no-tool").
    property string tool: ""
    // Newest first; each item is { line, id, kind, text, type, size, width, height }.
    property var items: []
    readonly property bool loading: lister.running
    readonly property bool busy: actor.running
    property int sequence: 0
    signal copied()
    signal removed()
    signal wiped()
    // A preview picture arrived: line is the entry it belongs to.
    signal imageLoaded(string line, string mime, string data)
    signal imageFailed(string line, int code)
    signal failed(var failure)

    function refresh() {
        if (!command || lister.running) return
        lister.command = [command, "list"]
        lister.running = true
    }
    function copy(line) { act("copy", line, qsTr("Copy an entry"), qsTr("The entry could not be copied.")) }
    // Copies the file a "file" entry names as its text or picture instead of its address.
    function copyContent(line) { act("copy-content", line, qsTr("Copy a file's content"), qsTr("The file could not be copied.")) }
    function remove(line) { act("delete", line, qsTr("Delete an entry"), qsTr("The entry could not be deleted.")) }
    function wipe() { act("wipe", "", qsTr("Clear the history"), qsTr("The history could not be cleared.")) }
    // Asks for the picture of one entry. A preview already being read is stopped and replaced.
    function loadImage(line) {
        if (!command) return
        if (imager.running) {
            imager.next = line
            imager.signal(15)
            return
        }
        imager.line = line
        imager.running = true
    }
    function cancelImage() {
        if (!imager.running) return
        imager.next = ""
        imager.cancelled = true
        imager.signal(15)
    }
    // Drops everything read, so clipboard content does not stay in the shell's memory after the panel closes.
    function forget() {
        cancelImage()
        items = []
        state = "unknown"
        tool = ""
    }

    function act(verb, line, operation, fallback) {
        if (!command || actor.running) return
        actor.verb = verb
        actor.line = line
        actor.operation = operation
        actor.fallback = fallback
        actor.command = [command, verb]
        actor.running = true
    }
    // The text shown for each exit code of the script; none of them can hold clipboard content.
    function reason(code, fallback, verb) {
        switch (code) {
        case 3: return qsTr("The entry changed. The list was refreshed.")
        case 5: return qsTr("A clipboard command timed out.")
        case 6: return verb === "copy-content" ? qsTr("The file is too large to copy as its content.") : qsTr("The picture is too large to preview.")
        case 7: return qsTr("Only a single text or picture file in your home folder can be copied as its content.")
        default: return fallback
        }
    }
    function fail(operation, message) {
        sequence += 1
        failed({ source: "clipboard", sequence: sequence, title: qsTr("Clipboard failed"), message: message,
            operation: operation, target: qsTr("Clipboard history"), details: message })
    }

    Process {
        id: lister
        stdout: StdioCollector { id: listOutput }
        onExited: function(code) {
            let answer = null
            if (code === 0) try { answer = JSON.parse(listOutput.text) } catch (failure) { }
            if (!answer || typeof answer.state !== "string") {
                root.state = "failed"
                root.tool = ""
                root.items = []
                return
            }
            root.state = answer.state
            root.tool = answer.tool ?? ""
            root.items = answer.state === "ok" ? answer.items : []
        }
    }
    Process {
        id: imager
        property string line: ""
        // The next preview to read once the running one has stopped, or "".
        property string next: ""
        property bool cancelled: false
        command: [root.command, "image"]
        stdinEnabled: true
        stdout: StdioCollector { id: imageOutput }
        // The script reads exactly one line, so the pipe can stay open until it exits.
        onStarted: write(line + "\n")
        onExited: function(code) {
            const wasCancelled = cancelled
            cancelled = false
            if (next !== "") {
                line = next
                next = ""
                running = true
                return
            }
            if (wasCancelled) return
            if (code === 0) try {
                const answer = JSON.parse(imageOutput.text)
                root.imageLoaded(line, answer.mime, answer.data)
                return
            } catch (failure) { }
            root.imageFailed(line, code)
        }
    }
    Process {
        id: actor
        property string verb: ""
        property string line: ""
        property string operation: ""
        property string fallback: ""
        stdinEnabled: line !== ""
        onStarted: if (line !== "") write(line + "\n")
        onExited: function(code) {
            if (code === 0) {
                if (verb === "copy" || verb === "copy-content") root.copied()
                else if (verb === "delete") root.removed()
                else root.wiped()
                return
            }
            root.fail(operation, root.reason(code, fallback, verb))
            // A changed entry means the list on screen is stale.
            if (code === 3) root.refresh()
        }
    }
}

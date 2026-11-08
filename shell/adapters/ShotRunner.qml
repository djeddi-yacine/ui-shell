pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Config

// Takes one screenshot through scripts/screen-shot. Nothing runs between screenshots, and the
// script prints its result when it is done, so there is no state file and no watcher.
Singleton {
    id: root
    readonly property string command: Config.GeneratedRuntime.commands.screenShot ?? ""
    property var capabilities: ({ available: false, clipboard: false, targets: [] })
    // The last picture: { file (or null), size, copied }, until the next capture starts.
    property var lastResult: null
    // A region already taken and waiting to be saved: { target, size }, or null.
    property var buffer: null
    readonly property bool busy: shooter.running
    property int sequence: 0
    signal captured(var result)
    signal buffered(var result)
    signal failed(var failure)

    // The last picture only counts while its file is still there: ask, and forget it if it is not.
    function verifyLast() {
        if (lastResult && lastResult.file && !verifier.running) { verifier.file = lastResult.file; verifier.running = true }
    }
    function loadCapabilities() { if (command && !probe.running) probe.running = true }
    // target "monitor:NAME" etc.; settings { copy, save, delay }, or { buffer: true, delay } to take
    // the picture now and keep it until commit().
    function capture(target, settings) {
        if (!command || shooter.running) return
        lastResult = null
        buffer = null
        shooter.target = target
        shooter.command = settings.buffer
            ? [command, "capture", target, "--buffer", "yes", "--delay", String(settings.delay)]
            : [command, "capture", target, "--copy", settings.copy ? "yes" : "no",
                "--save", settings.save ? "yes" : "no", "--delay", String(settings.delay)]
        shooter.running = true
    }
    // Deliver the buffered picture; settings { copy, save }.
    function commit(settings) {
        if (!command || shooter.running || !buffer) return
        lastResult = null
        shooter.target = buffer.target
        shooter.command = [command, "commit", "--copy", settings.copy ? "yes" : "no", "--save", settings.save ? "yes" : "no"]
        shooter.running = true
    }
    function discardBuffer() {
        buffer = null
        if (command && !dropper.running) dropper.running = true
    }
    Process { id: dropper; command: [root.command, "discard"] }
    Process {
        id: probe
        command: [root.command, "capabilities"]
        stdout: StdioCollector { id: probeOutput }
        onExited: function(code) { if (code === 0) try { root.capabilities = JSON.parse(probeOutput.text) } catch (failure) { } }
    }
    Process {
        id: verifier
        property string file: ""
        command: ["test", "-e", file]
        onExited: function(code) { if (code !== 0 && root.lastResult && root.lastResult.file === file) root.lastResult = null }
    }
    Process {
        id: shooter
        property string target: ""
        stdout: StdioCollector { id: shotOutput }
        stderr: StdioCollector { id: shotError }
        onExited: function(code) {
            if (code === 0) {
                try {
                    const result = JSON.parse(shotOutput.text)
                    if (result.buffer) {
                        root.buffer = { target: target, size: result.size }
                        root.buffered(root.buffer)
                        return
                    }
                    root.buffer = null
                    root.sequence += 1
                    result.id = "shot-" + root.sequence
                    root.lastResult = result
                    root.captured(result)
                    return
                } catch (failure) { }
            }
            root.sequence += 1
            const message = shotError.text.trim() || qsTr("The screenshot could not be taken.")
            root.failed({ source: "shot", sequence: root.sequence, title: qsTr("Screenshot failed"), message: message,
                operation: qsTr("Take a screenshot"), target: target || qsTr("Screen"), details: message })
        }
    }
}

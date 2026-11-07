pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "../config" as Config

// Runs one step of scripts/media-art at a time. Every run is its own process object, so a late
// exit of a killed run can never be mistaken for the current one: only the current run's result
// is reported. This is the only place that starts the script.
QtObject {
    id: root
    readonly property string command: Config.GeneratedRuntime.commands.mediaArt ?? ""
    // The current run, or null.
    property var active: null
    signal finished(string runKey, var result)

    property Component processComponent: Component {
        Process {
            property string runKey: ""
            stdout: StdioCollector {}
        }
    }

    function run(step, flags, input, runKey) {
        kill()
        if (command.length === 0) {
            finished(runKey, { ok: false, error: "tool-failed", detail: "the art command is not configured" })
            return
        }
        const argv = [command, step].concat(flags)
        if (input.length > 0) argv.push(input)
        const process = processComponent.createObject(root, { command: argv, runKey: runKey })
        process.exited.connect(code => root.exited(process, code))
        active = process
        process.running = true
    }
    function kill() {
        const process = active
        active = null
        if (process) process.running = false
    }
    function exited(process, code) {
        const current = process === active
        if (current) active = null
        const text = process.stdout.text
        const key = process.runKey
        process.destroy()
        // A run that was killed or replaced reports nothing.
        if (!current) return
        let result
        try { result = JSON.parse(text.trim().split("\n").pop()) } catch (failure) { result = undefined }
        if (code !== 0 || result === undefined || typeof result !== "object" || result === null)
            result = { ok: false, error: "tool-failed", detail: code !== 0 ? "exit code " + code : "no answer from the art script" }
        finished(key, result)
    }
}

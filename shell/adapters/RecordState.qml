pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Config

// The one source of truth for "is the screen recording?". scripts/screen-record keeps the
// state in a file; this is woken by the kernel (inotify, through FileView) when it changes,
// then asks the script for the checked state, so a recorder that vanished is never reported
// as recording. Nothing polls while idle.
Singleton {
    id: root
    // The recorder's state file (scripts/screen-record). UI_SHELL_RECORD_DIR is the test override
    // the script honours too.
    readonly property string stateFile: (Quickshell.env("UI_SHELL_RECORD_DIR")
        || ((Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ui-shell/record")) + "/state.json"
    readonly property string command: Config.GeneratedRuntime.commands.screenRecord ?? ""
    property var recorded: ({ state: "idle" })
    property var capabilities: ({ available: false, targets: [], audio: [], webcam: false })
    property var monitors: []
    property var windows: []
    property var cameras: []
    // What the pickers offer: { desktop: [{ id, label }], mic: [{ id, label }] }.
    property var audioSources: ({ desktop: [], mic: [] })
    property string lastRegion: ""
    // True while the pointer selection (slurp) runs; the panel hides itself meanwhile.
    readonly property bool picking: picker.running
    readonly property string state: recorded.state ?? "idle"
    readonly property bool active: state === "starting" || state === "recording"
    // Seconds since the recording began. It ticks once a second while a recording is starting or
    // running (the bar shows the clock all that time) and not at all otherwise.
    property real now: Date.now() / 1000
    readonly property int elapsed: state === "recording" && recorded.started ? Math.max(0, Math.floor(now - recorded.started)) : 0
    // Whole seconds left of the countdown while starting; 0 once it is over (the recorder is settling).
    readonly property int remaining: state === "starting" && (recorded.countdown ?? 0) > 0 && recorded.started
        ? Math.max(0, Math.ceil(recorded.countdown - (now - recorded.started))) : 0
    // The last saved recording, kept in the state file until the next one starts.
    // `id` tells one saved recording from the next, so each is announced once.
    readonly property var lastResult: state === "finished" && recorded.size ? { id: recorded.started + ":" + recorded.output, output: recorded.output, size: recorded.size } : null
    function clock(seconds) {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor(seconds % 3600 / 60)
        const rest = seconds % 60
        const two = value => (value < 10 ? "0" : "") + value
        return (hours > 0 ? hours + ":" : "") + two(minutes) + ":" + two(rest)
    }
    function size(bytes) { return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(bytes / 1024)) + " KB" }
    property int sequence: 0
    property var shownFailure: ""
    // Raised once per failed recording: the shared ErrorPopup presents it.
    signal failed(var failure)
    // The user finished selecting a region ("WxH+X+Y"); a cancelled selection emits nothing.
    signal regionPicked(string region)
    signal regionCancelled()

    function refresh() { if (command && !reader.running) reader.running = true }
    function loadCapabilities() { if (command && !probe.running) probe.running = true }
    function loadMonitors() { if (command && !lister.running) lister.running = true }
    function loadAudioSources() { if (command && !audioLister.running) audioLister.running = true }
    function loadCameras() { if (command && !cameraLister.running) cameraLister.running = true }
    function loadWindows() { if (command && !windowLister.running) windowLister.running = true }
    function loadLastRegion() { if (command && !regionReader.running) regionReader.running = true }
    function pickRegion() { if (command && !picker.running) picker.running = true }
    // target "window:ADDRESS" etc.; `settings` carries the panel's choices and the saved options:
    // { desktopAudio ("no", "default", "device:ID" or "app:NAME"), microphone ("no", "default" or "device:ID"), countdown, fps, quality, codec, audioCodec, bitrate, container, cursor, webcam }
    // where webcam is a camera path or "".
    function start(target, settings) {
        run(["start", target, "--desktop-audio", settings.desktopAudio, "--microphone", settings.microphone, "--countdown", String(settings.countdown),
            "--fps", String(settings.fps), "--quality", settings.quality, "--codec", settings.codec, "--audio-codec", settings.audioCodec, "--bitrate", settings.bitrate,
            "--container", settings.container, "--cursor", settings.cursor ? "yes" : "no"].concat(settings.webcam ? ["--webcam", settings.webcam] : []), qsTr("Start recording"), target)
    }
    function stop() { run(["stop"], qsTr("Stop recording"), recorded.target ?? "") }
    function run(args, operation, target) {
        if (!command || actor.running) return
        actor.operation = operation
        actor.target = target
        actor.command = [command].concat(args)
        actor.running = true
    }
    function present(title, message, operation, target, details) {
        sequence += 1
        failed({ source: "record", sequence: sequence, title: title, message: message,
            operation: operation, target: target || qsTr("Screen"), details: details })
    }
    Component.onCompleted: { refresh(); loadCapabilities() }
    // The file appears with the first status call; its absence is not an error.
    FileView { path: root.stateFile; watchChanges: true; printErrors: false; onFileChanged: root.refresh() }
    Timer {
        running: root.active
        interval: Config.Record.clockTickMilliseconds
        repeat: true
        onTriggered: root.now = Date.now() / 1000
    }
    // A missed file event must not leave a dead recording on screen: while one runs, re-read slowly.
    Timer {
        running: root.active
        interval: Config.Record.safetyRefreshSeconds * 1000
        repeat: true
        onTriggered: root.refresh()
    }
    Process {
        id: reader
        command: [root.command, "status"]
        stdout: StdioCollector { id: statusOutput }
        onExited: function(code) {
            if (code !== 0) return
            try {
                const next = JSON.parse(statusOutput.text)
                const failure = next.state === "failed" && next.started !== root.shownFailure
                root.recorded = next
                root.now = Date.now() / 1000
                if (failure) {
                    root.shownFailure = next.started
                    root.present(qsTr("Recording failed"), qsTr("The recording stopped unexpectedly."),
                        qsTr("Record the screen"), next.target, next.message ?? "")
                }
            } catch (failure) { /* a half-written file is re-read on the next event */ }
        }
    }
    Process {
        id: probe
        command: [root.command, "capabilities"]
        stdout: StdioCollector { id: probeOutput }
        onExited: function(code) { if (code === 0) try { root.capabilities = JSON.parse(probeOutput.text) } catch (failure) { } }
    }
    Process {
        id: lister
        command: [root.command, "monitors"]
        stdout: StdioCollector { id: listOutput }
        onExited: function(code) { if (code === 0) try { root.monitors = JSON.parse(listOutput.text) } catch (failure) { } }
    }
    Process {
        id: audioLister
        command: [root.command, "audio-sources"]
        stdout: StdioCollector { id: audioOutput }
        onExited: function(code) { if (code === 0) try { root.audioSources = JSON.parse(audioOutput.text) } catch (failure) { } }
    }
    Process {
        id: cameraLister
        command: [root.command, "cameras"]
        stdout: StdioCollector { id: cameraOutput }
        onExited: function(code) { if (code === 0) try { root.cameras = JSON.parse(cameraOutput.text) } catch (failure) { } }
    }
    Process {
        id: windowLister
        command: [root.command, "windows"]
        stdout: StdioCollector { id: windowOutput }
        onExited: function(code) { if (code === 0) try { root.windows = JSON.parse(windowOutput.text) } catch (failure) { } }
    }
    Process {
        id: regionReader
        command: [root.command, "last-region"]
        stdout: StdioCollector { id: regionOutput }
        onExited: function(code) { if (code === 0) root.lastRegion = regionOutput.text.trim() }
    }
    // Exit 1 with no message is the user cancelling; a message is a real failure (no slurp).
    Process {
        id: picker
        command: [root.command, "pick-region"]
        stdout: StdioCollector { id: pickerOutput }
        stderr: StdioCollector { id: pickerError }
        onExited: function(code) {
            if (code === 0) { root.lastRegion = pickerOutput.text.trim(); root.regionPicked(root.lastRegion); return }
            root.regionCancelled()
            if (pickerError.text.trim().length > 0)
                root.present(qsTr("Could not select a region"), pickerError.text.trim(), qsTr("Select a region"), "", pickerError.text.trim())
        }
    }
    Process {
        id: actor
        property string operation: ""
        property string target: ""
        stderr: StdioCollector { id: actorError }
        onExited: function(code) {
            root.refresh()
            if (code !== 0) root.present(qsTr("Could not complete the action"),
                actorError.text.trim() || qsTr("The recorder script failed."), operation, target, actorError.text.trim())
        }
    }
}

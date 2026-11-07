import QtQuick

// The art for the shown player: which provider its mode names, the steps of that provider run in
// turn through the runner, and the result as `state`, `kind` and `path`. No imports beyond
// QtQuick: the runner and every setting arrive as properties, so tests give it a fake runner.
//
// Stale results never show. Each request has a key (player, mode and art address); a change of
// key kills the running step and drops its result, so a skipped track's art can never appear
// under the next track, and the previous track's art does not stay while the new one loads.
// Art is keyed on the address changing, not on the track changing, because players often update
// the art after the track. It runs only while `enabled` (the panel is open).
//
// Hot cache: the last few finished requests stay in memory by key. When the same state comes back
// (the panel is opened again, or a track that was already shown returns) its art is shown at once
// with no step run, and with no gap in between, so nothing fades out and in again.
//
// At start it asks the script once which tools exist (`capabilities`). Until the answer arrives
// nothing runs; if the blurhash tools are missing, a player set to blurhash uses the cover, and
// `blurhashAvailable` is false so the settings do not offer the mode.
QtObject {
    id: root
    required property var runner
    property var player: null
    // selection.keyOf: the same key the pin uses.
    property var keyOf: player => ""
    property bool enabled: false
    // auto: each player uses `modes` (and `defaultMode` when it has no entry); cover, blurhash or
    // off: that mode for every player.
    property string forcedMode: "auto"
    property string defaultMode: "cover"
    property var modes: ({})
    property var providers: ({})
    property string cacheDir: ""
    property int debounceMs: 250
    property int shrinkSize: 256
    property var shrinkTools: ["vips", "ffmpeg"]
    property string blurhashComponents: "4,3"
    property int blurhashDecodeSize: 32
    property int downloadMaxBytes: 20971520
    property int stepTimeoutSeconds: 10
    property string blurhashEncoder: "blurhash_encoder"
    property string blurhashDecoder: "blurhash_decoder"
    property int cacheMaxBytes: 67108864
    property int cacheMaxEntries: 40
    property int failureMemorySeconds: 60
    property int hotEntries: 8

    // none (nothing to show), loading, ready or failed.
    property string state: "none"
    // cover or blurhash (the mode that made `path`), or "" when there is no art.
    property string kind: ""
    property string path: ""
    // What the tool check found: known once answered; fetch (curl); shrink (the tool chosen, or "");
    // blurhash (encoder, decoder and a shrink tool).
    property var capabilities: ({ known: false, fetch: true, shrink: "", blurhash: false })
    // Optimistic until the check has answered, so the settings are not wrong for a moment.
    readonly property bool blurhashAvailable: !capabilities.known || capabilities.blurhash
    // For the shared ErrorPopup: only real faults, once per cause.
    signal faultReported(var failure)

    readonly property string playerKey: player ? keyOf(player) : ""
    readonly property string address: player && player.trackArtUrl ? String(player.trackArtUrl) : ""
    readonly property string chosenMode: forcedMode !== "auto" ? forcedMode : (modes[playerKey] ?? defaultMode)
    // A mode that needs tools this machine lacks falls back to the cover.
    readonly property string mode: chosenMode === "blurhash" && !blurhashAvailable ? "cover" : chosenMode
    readonly property var steps: providers[mode] ?? []
    // Empty when there is nothing to do: disabled, no player, no address, or the mode is off.
    readonly property string runKey: enabled && player && address.length > 0 && steps.length > 0 ? playerKey + "|" + mode + "|" + address : ""
    property int stepIndex: 0
    property bool stepRunning: false
    property var failures: ({})
    property var causes: ({})
    property int sequence: 0
    // Recent finished requests, newest first: { key, kind, path }.
    property var memo: []

    onRunKeyChanged: restart()
    // The provider changed under the same key (settings, or the tool check): start again.
    onStepsChanged: restart()
    Component.onCompleted: { probe(); restart() }

    property Timer debounce: Timer {
        interval: root.debounceMs
        onTriggered: root.begin()
    }
    property Connections link: Connections {
        target: root.runner
        function onFinished(key, result) { root.handle(key, result) }
    }

    function probe() {
        runner.run("capabilities", ["--encoder", blurhashEncoder, "--decoder", blurhashDecoder, "--shrink-tools", shrinkTools.join(",")], "", "capabilities")
    }
    function learn(result) {
        const ok = result && result.ok === true
        capabilities = { known: true, fetch: ok ? result.fetch === true : true, shrink: ok && typeof result.shrink === "string" ? result.shrink : "", blurhash: ok && result.blurhash === true }
        // Whatever was waiting for the answer (or ran with a guess) starts again.
        restart()
    }
    // The three members change together, in the order a reader needs: a result is complete before
    // `state` says ready, and `state` says it is gone before the rest is cleared.
    function setResult(nextState, nextKind, nextPath) {
        if (nextState === "ready") { kind = nextKind; path = nextPath; state = nextState }
        else { state = nextState; kind = nextKind; path = nextPath }
    }
    function remember(key, madeKind, madePath) {
        const next = memo.filter(entry => entry.key !== key)
        next.unshift({ key: key, kind: madeKind, path: madePath })
        memo = next.slice(0, Math.max(1, hotEntries))
    }
    // The picture file is gone (pruned, or deleted): forget it, and make it again if it is shown.
    function lost(lostPath) {
        memo = memo.filter(entry => entry.path !== lostPath)
        if (path === lostPath) restart()
    }

    function restart() {
        debounce.stop()
        if (stepRunning) { runner.kill(); stepRunning = false }
        stepIndex = 0
        if (runKey.length === 0) { setResult("none", "", ""); return }
        const hot = memo.find(entry => entry.key === runKey)
        if (hot) { remember(runKey, hot.kind, hot.path); setResult("ready", hot.kind, hot.path); return }
        setResult("none", "", "")
        const failedAt = failures[runKey]
        if (failedAt !== undefined && Date.now() - failedAt < failureMemorySeconds * 1000) { setResult("failed", "", ""); return }
        debounce.restart()
    }
    function begin() {
        if (runKey.length === 0 || !capabilities.known) return
        state = "loading"
        stepIndex = 0
        run(address)
    }
    function flagsFor(step) {
        const common = ["--dir", cacheDir, "--timeout", String(stepTimeoutSeconds)]
        if (step === "fetch") return common.concat(["--max-bytes", String(downloadMaxBytes)])
        if (step === "shrink") return common.concat(["--tool", capabilities.shrink || shrinkTools[0], "--size", String(shrinkSize)])
        if (step === "blurhash") return common.concat(["--encoder", blurhashEncoder, "--decoder", blurhashDecoder, "--components", blurhashComponents, "--size", String(blurhashDecodeSize)])
        return common
    }
    function run(input) {
        stepRunning = true
        runner.run(steps[stepIndex], flagsFor(steps[stepIndex]), input, runKey)
    }
    function handle(key, result) {
        if (key === "capabilities") { learn(result); return }
        if (key !== runKey || state !== "loading") return
        stepRunning = false
        if (result && result.ok === true && typeof result.path === "string" && result.path.length > 0) {
            if (stepIndex + 1 < steps.length) {
                stepIndex += 1
                run(result.path)
                return
            }
            remember(key, mode, result.path)
            setResult("ready", mode, result.path)
            runner.run("prune", ["--dir", cacheDir, "--max-bytes", String(cacheMaxBytes), "--max-entries", String(cacheMaxEntries), "--keep", result.path], "", key + "#prune")
            return
        }
        fail(result)
    }
    readonly property var loud: ({ "missing-tool": true, "timeout": true, "too-large": true, "tool-failed": true })
    readonly property var messages: ({
        "missing-tool": qsTr("A tool that the cover art needs was not found."),
        "timeout": qsTr("A cover art step took too long."),
        "too-large": qsTr("The cover art is larger than the allowed size."),
        "tool-failed": qsTr("A cover art step failed.")
    })
    function fail(result) {
        const error = result && result.error ? String(result.error) : "tool-failed"
        const detail = result && result.detail ? String(result.detail) : ""
        failures[runKey] = Date.now()
        setResult("failed", "", "")
        if (loud[error] !== true) return
        const step = steps[stepIndex]
        const cause = step + "|" + error + "|" + playerKey
        if (causes[cause] !== undefined) return
        sequence += 1
        causes[cause] = sequence
        faultReported({ source: "mpris", sequence: sequence, title: qsTr("Cover art failed"),
            message: messages[error], operation: qsTr("Art step: %1").arg(step), target: address,
            details: (detail.length > 0 ? detail : error) + "\n" + qsTr("Player: %1").arg(playerKey) })
    }
}

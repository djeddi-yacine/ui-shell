pragma ComponentBehavior: Bound
import QtQuick

// The polkit authentication logic, with no Quickshell import: it works on a `source` that
// supplies `flow` (the current AuthFlow, or null) and `agentActive`. The shell gives it
// PolkitSource; tests give it a fake. One request at a time; the module queues the rest.
//
// A wrong password ends the request. Polkit would prompt again on its own, so on the first
// failure this cancels the flow (one event-loop turn later, because the module creates its
// fresh session right after the failure signal) and shows "failed" until a key is pressed.
QtObject {
    id: root
    required property var source
    readonly property var flow: source.flow
    readonly property bool agentActive: source.agentActive === true

    // How long the "accepted" state stays before the dialog closes (milliseconds).
    property int successMs: 500
    // idle | prompt | checking | succeeded | failed | refused
    property string phase: "idle"
    readonly property bool active: phase !== "idle"
    // What the dialog shows, copied when the request starts so it cannot change under a
    // half-typed secret.
    property var displayed: ({ message: "", actionId: "", accounts: [], selectedIndex: 0, prompt: "", visibleEcho: false, info: "", infoIsError: false })
    // Only a prompt that polkit has asked for can be answered.
    readonly property bool canAnswer: phase === "prompt" && flow !== null && flow.isResponseRequired === true

    function accountList(f) {
        const list = []
        const identities = f.identities ?? []
        for (let i = 0; i < identities.length; i++)
            list.push({ id: identities[i].id, label: identities[i].displayName || identities[i].string || "" })
        return list
    }
    function indexOfSelected(f, accounts) {
        const selected = f.selectedIdentity
        if (!selected) return 0
        for (let i = 0; i < accounts.length; i++)
            if (accounts[i].id === selected.id) return i
        return 0
    }
    function snapshot(f) {
        const accounts = accountList(f)
        displayed = {
            message: f.message ?? "",
            actionId: f.actionId ?? "",
            accounts: accounts,
            selectedIndex: indexOfSelected(f, accounts),
            prompt: f.isResponseRequired ? (f.inputPrompt ?? "") : "",
            visibleEcho: f.isResponseRequired === true && f.responseVisible === true,
            info: f.supplementaryMessage ?? "",
            infoIsError: f.supplementaryIsError === true
        }
    }
    function begin() {
        const f = flow
        if (f === null || f.isCompleted === true) return
        snapshot(f)
        phase = displayed.accounts.length === 0 ? "refused" : "prompt"
    }
    function succeed() {
        if (phase !== "checking" && phase !== "prompt") return
        phase = "succeeded"
        successTimer.interval = successMs
        successTimer.restart()
    }
    property Timer successTimer: Timer { onTriggered: root.finish() }
    function finish() {
        phase = "idle"
        begin()
    }

    function submit(secret) {
        if (!canAnswer) return
        phase = "checking"
        flow.submit(secret)
    }
    function cancel() {
        const f = flow
        if (phase === "failed" || phase === "succeeded") { successTimer.stop(); finish(); return }
        phase = "idle"
        if (f !== null && f.isCompleted !== true) f.cancelAuthenticationRequest()
        begin()
    }
    function dismissFailure() {
        if (phase === "failed") finish()
        else if (phase === "refused") cancel()
    }
    function selectAccount(index) {
        if (phase !== "prompt" || flow === null) return
        const identities = flow.identities ?? []
        if (index < 0 || index >= identities.length) return
        flow.selectedIdentity = identities[index]
        const next = displayed
        next.selectedIndex = index
        displayed = next
    }

    onFlowChanged: if (phase === "idle") begin()
    Component.onCompleted: begin()

    property Connections events: Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onIsResponseRequiredChanged() {
            if (root.phase !== "prompt" && root.phase !== "checking") return
            if (root.flow.isResponseRequired) { root.snapshot(root.flow); root.phase = "prompt" }
        }
        function onSupplementaryMessageChanged() {
            if (root.phase === "prompt" || root.phase === "checking") root.snapshot(root.flow)
        }
        function onAuthenticationFailed() {
            if (root.phase !== "checking" && root.phase !== "prompt") return
            root.phase = "failed"
            const failedFlow = root.flow
            // Deferred: the module sets up a fresh session after this signal returns.
            Qt.callLater(() => { if (failedFlow.isCompleted !== true) failedFlow.cancelAuthenticationRequest() })
        }
        function onAuthenticationSucceeded() { root.succeed() }
        function onAuthenticationRequestCancelled() { if (root.phase === "prompt" || root.phase === "checking") root.finish() }
        function onIsCompletedChanged() {
            if (!root.flow.isCompleted) return
            if (root.flow.isSuccessful === true) root.succeed()
            else if (root.phase === "prompt" || root.phase === "checking") root.finish()
        }
    }
}

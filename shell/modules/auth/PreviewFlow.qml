import QtQuick

// A fake polkit request for UI_SHELL_OPEN_AUTH=1, where there is no polkit daemon. It answers
// like the real one: after a moment the password "0" succeeds and anything else fails;
// cancelling completes it.
QtObject {
    id: root
    property string message: "Preview: 0 is the right password, anything else fails"
    property string actionId: "ui.shell.preview"
    property var identities: [{ id: "unix-user:preview", displayName: "preview", string: "unix-user:preview" }]
    property var selectedIdentity: identities[0]
    property bool isResponseRequired: true
    property string inputPrompt: "Password:"
    property bool responseVisible: false
    property string supplementaryMessage: ""
    property bool supplementaryIsError: false
    property bool isCompleted: false
    property bool isSuccessful: false
    property string answer: ""
    signal authenticationSucceeded()
    signal authenticationFailed()
    signal authenticationRequestCancelled()
    property Timer verdict: Timer {
        interval: 700
        onTriggered: {
            if (root.answer === "0") {
                root.isSuccessful = true
                root.isCompleted = true
                root.authenticationSucceeded()
            } else {
                root.authenticationFailed()
                // Like the real module, a fresh session prompts again; the adapter cancels it.
                root.isResponseRequired = true
            }
        }
    }
    function submit(value) {
        answer = value
        isResponseRequired = false
        verdict.restart()
    }
    function cancelAuthenticationRequest() {
        verdict.stop()
        isCompleted = true
    }
}

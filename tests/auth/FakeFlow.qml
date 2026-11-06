import QtQuick

// Stands in for Quickshell's AuthFlow: the same property and signal names, none of the polkit.
QtObject {
    property string message: "Authentication is required"
    property string actionId: "test.action"
    property var identities: [{ id: "unix-user:root", displayName: "root", string: "unix-user:root" }]
    property var selectedIdentity: identities.length > 0 ? identities[0] : null
    property bool isResponseRequired: false
    property string inputPrompt: "Password:"
    property bool responseVisible: false
    property string supplementaryMessage: ""
    property bool supplementaryIsError: false
    property bool isCompleted: false
    property bool isSuccessful: false
    property var submitted: []
    property int cancels: 0
    signal authenticationSucceeded()
    signal authenticationFailed()
    signal authenticationRequestCancelled()
    function submit(value) {
        submitted = submitted.concat([value])
        isResponseRequired = false
    }
    function cancelAuthenticationRequest() {
        cancels++
        isCompleted = true
    }
}

import QtQuick
import "../../components" as Controls

// Connects the adapter to the generic dialog: the snapshot in, the three signals out.
Controls.SecretDialog {
    readonly property var auth: AuthState.auth
    message: auth.displayed.message
    accounts: auth.displayed.accounts
    selectedIndex: auth.displayed.selectedIndex
    prompt: auth.displayed.prompt
    visibleEcho: auth.displayed.visibleEcho
    info: auth.displayed.info
    error: auth.displayed.infoIsError ? auth.displayed.info : ""
    checking: auth.phase === "checking"
    failed: auth.phase === "failed"
    refused: auth.phase === "refused"
    succeeded: auth.phase === "succeeded"
    onSubmitted: secret => auth.submit(secret)
    onCancelled: auth.cancel()
    onAccountChosen: index => auth.selectAccount(index)
    onKeyAfterFailure: auth.dismissFailure()
}

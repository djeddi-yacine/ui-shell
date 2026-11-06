pragma Singleton
import QtQuick

// The authentication dialog (polkit): its own window, one at a time.
QtObject {
    readonly property string namespace: "ui-shell-auth"
    // Keys that arrive this soon after a prompt appears are dropped, so a stray keystroke from
    // whatever the user was typing is neither part of the password nor a submit (milliseconds).
    readonly property int inputGuardMs: 300
    // The bar entry that reports a missing agent waits this long after start-up, so it does not
    // flash while the agent is still registering (milliseconds).
    readonly property int startupGraceMs: 3000
    readonly property int cardWidth: 420
    readonly property int fieldHeight: 48
    // The lock icon in the field, in pixels.
    readonly property int iconSize: 22
    // The checked lock stays on screen this long after the password is accepted (milliseconds).
    readonly property int successMs: 500
    readonly property real scrimOpacity: 0.6
    readonly property string checkingText: qsTr("Checking…")
    readonly property string failedText: qsTr("Wrong password")
    readonly property string refusedText: qsTr("Cannot be answered here")
    readonly property string passwordLabel: qsTr("Password")
    readonly property string titleFallback: qsTr("Authentication required")
}

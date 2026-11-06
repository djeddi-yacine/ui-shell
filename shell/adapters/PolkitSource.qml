pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The only file that imports Quickshell's polkit module (version 0.1, its API will move).
// The path is set once and never bound: the module ignores later changes, and its own default
// differs between its header and its source.
Singleton {
    id: root
    readonly property var flow: agent.flow
    readonly property bool agentActive: agent.isRegistered
    PolkitAgent {
        id: agent
        path: "/org/quickshell/PolkitAgent"
    }
}

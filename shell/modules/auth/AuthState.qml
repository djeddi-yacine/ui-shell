pragma Singleton
import QtQuick
import Quickshell
import "../../adapters" as Adapters
import "../../config" as Config

// The one adapter instance. UI_SHELL_OPEN_AUTH=1 swaps the real polkit source for a fake
// request so the dialog can be shown and screenshotted where no polkit daemon exists.
QtObject {
    id: root
    readonly property bool preview: Quickshell.env("UI_SHELL_OPEN_AUTH") === "1" || loop
    // UI_SHELL_OPEN_AUTH=loop: a new fake request appears 1.5 s after each one ends.
    readonly property bool loop: Quickshell.env("UI_SHELL_OPEN_AUTH") === "loop"
    // The nested test session has no login session or polkit daemon, so registering an agent there
    // only logs a warning that the harness treats as fatal; it sets UI_SHELL_AUTH_AGENT=0.
    readonly property bool agentEnabled: Quickshell.env("UI_SHELL_AUTH_AGENT") !== "0"
    readonly property var source: preview ? previewSource : agentEnabled ? Adapters.PolkitSource : offSource
    readonly property Adapters.PolkitAuth auth: Adapters.PolkitAuth { source: root.source; successMs: Config.Auth.successMs }

    property QtObject offSource: QtObject {
        readonly property bool agentActive: true
        readonly property var flow: null
    }
    // One fake request at a time: when it completes it is removed, as the real module does.
    property QtObject previewSource: QtObject {
        id: fake
        readonly property bool agentActive: true
        property var flow: root.preview ? root.flowComponent.createObject(root) : null
        property Timer respawn: Timer {
            interval: 1500
            onTriggered: fake.flow = root.flowComponent.createObject(root)
        }
        property Connections completion: Connections {
            target: fake.flow
            ignoreUnknownSignals: true
            function onIsCompletedChanged() {
                if (fake.flow && fake.flow.isCompleted) {
                    fake.flow.destroy(2000)
                    fake.flow = null
                    if (root.loop) fake.respawn.restart()
                }
            }
        }
    }
    property Component flowComponent: Component { PreviewFlow {} }
}

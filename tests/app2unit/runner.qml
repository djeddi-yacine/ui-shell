//@ pragma ShellId ui-shell-test-app-runner
import QtQuick
import Quickshell
import "adapters" as Adapters
import "config" as Config

ShellRoot {
    id: root
    property bool accepted: false

    Adapters.AppRunner {
        id: runner
        executable: Config.AppLauncher.runnerExecutable
        launchArguments: Config.AppLauncher.runnerArguments
        onAccepted: {
            root.accepted = true
            Qt.callLater(() => runner.launch({ id: "org.ui-shell.test-missing", name: "Missing test entry" }))
        }
        onFailed: message => {
            if (!root.accepted || !message.length) {
                console.error("APP_LAUNCH_FAIL " + message)
            } else {
                console.log("APP_LAUNCH_PASS prompt handoff and nonzero/stderr failure")
            }
            Qt.quit()
        }
    }
    Component.onCompleted: runner.launch({ id: "org.ui-shell.test-sandbox", name: "Sandbox launch check" })
}

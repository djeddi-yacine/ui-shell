import QtQuick
import Quickshell.Io

Item {
    id: root

    required property string executable
    required property list<string> launchArguments

    readonly property bool busy: launchPending
    readonly property string error: currentError
    readonly property string status: currentStatus

    signal accepted()
    signal failed(string message)

    property bool launchPending: false
    property string currentError: ""
    property string currentStatus: ""
    property string stderrText: ""
    property string stdoutText: ""
    property string launchTarget: ""
    property int failureSequence: 0
    property var failure: null
    readonly property string output: stdoutText

    function launch(entry) {
        if (launchPending) {
            return
        }
        launchTarget = entry && entry.id ? entry.id + ".desktop" : qsTr("Selected application")
        if (!entry || !entry.id) {
            reportFailure(qsTr("The selected desktop entry has no ID"))
            return
        }
        if (!executable.trim()) {
            reportFailure(qsTr("The app2unit executable is not configured"))
            return
        }

        currentError = ""
        stderrText = ""
        stdoutText = ""
        currentStatus = qsTr("Starting %1…").arg(entry.name || entry.id)
        launchPending = true
        // Quickshell IDs strip exactly one filename suffix, even for names
        // like org.telegram.desktop.desktop. Always restore that suffix.
        runner.command = [root.executable].concat(root.launchArguments, ["--", entry.id + ".desktop"])
        runner.running = true
    }

    function reportFailure(message, details = "") {
        currentError = message
        currentStatus = message
        launchPending = false
        failureSequence += 1
        failure = { source: "app-runner", sequence: failureSequence,
            title: qsTr("Application launch failed"),
            message: qsTr("The application was not handed off to app2unit. Your selection has not changed."),
            operation: qsTr("Launch through app2unit"), target: launchTarget,
            details: [qsTr("Runner: %1").arg(executable), message, details].filter(value => value.length > 0).join("\n") }
        failed(message)
    }

    Process {
        id: runner
        stdout: StdioCollector { onStreamFinished: root.stdoutText = text.trim() }
        stderr: StdioCollector { onStreamFinished: root.stderrText = text.trim() }

        // app2unit honors Terminal=true entries through xdg-terminal-exec.
        onExited: function(exitCode, exitStatus) {
            if (!root.launchPending)
                return

            root.launchPending = false
            // QProcess::NormalExit is 0; Quickshell forwards that native enum.
            if (exitCode === 0 && exitStatus === 0) {
                root.currentError = ""
                root.currentStatus = qsTr("Launch handed off to app2unit")
                root.accepted()
                return
            }

            root.reportFailure(root.stderrText || qsTr("app2unit failed with exit code %1").arg(exitCode),
                qsTr("Exit code: %1\nExit status: %2").arg(exitCode).arg(exitStatus))
        }

        onRunningChanged: {
            if (root.launchPending && !running)
                root.reportFailure(qsTr("Could not start app2unit; check the configured executable"))
        }
    }
}

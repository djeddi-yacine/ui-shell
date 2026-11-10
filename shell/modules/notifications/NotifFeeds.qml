import QtQuick

// Posts the shell's own results (screenshot, recording) into the center. The sources are passed in
// by shell.qml so this module imports no adapters.
QtObject {
    id: root
    required property var center
    required property var shotRunner
    required property var recordState
    // Id of the last recording already reported; starts at whatever is there at load.
    property string lastRecordId: recordState.lastResult ? recordState.lastResult.id : ""

    property Connections shot: Connections {
        target: root.shotRunner
        function onCaptured(result) { root.center.post(qsTr("Screenshot saved"), result.file ?? "", "normal") }
        function onFailed(failure) { root.center.post(failure.title, failure.message, "critical") }
    }
    property Connections record: Connections {
        target: root.recordState
        function onFailed(failure) { root.center.post(failure.title, failure.message, "critical") }
        function onLastResultChanged() {
            const r = root.recordState.lastResult
            if (r === null || r.id === root.lastRecordId) return
            root.lastRecordId = r.id
            root.center.post(qsTr("Recording saved"), r.output, "normal")
        }
    }
}

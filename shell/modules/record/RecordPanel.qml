pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// Screen recording: pick what to record and start. The panel only chooses; the recorder
// runs on its own (scripts/screen-record), and the bar shows it and stops it. Start closes the panel.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    property bool open: false
    property var countdownChoice: undefined
    signal closed()
    // What each picker offers: Off first, then the recorder's own list. A device the user picked is
    // remembered for the session (RecordPanelState.picks); the saved Ctrl+E options only decide where
    // it starts. A pick that is no longer in the list falls back to the saved start, then to Off.
    readonly property var desktopChoices: [{ label: qsTr("Off"), value: "no" }].concat(
        (Adapters.RecordState.audioSources.desktop ?? []).map(entry => ({ label: entry.label, value: entry.id })))
    readonly property var micChoices: [{ label: qsTr("Off"), value: "no" }].concat(
        (Adapters.RecordState.audioSources.mic ?? []).map(entry => ({ label: entry.label, value: entry.id })))
    readonly property var cameraChoices: [{ label: qsTr("Off"), value: "" }].concat(
        Adapters.RecordState.cameras.map(entry => ({ label: entry.name, value: entry.path })))
    readonly property bool audioPossible: desktopChoices.length > 1
    readonly property bool micPossible: micChoices.length > 1
    // A webcam is offered only when the recorder script found a camera and a player for the overlay.
    readonly property bool webcamPossible: Adapters.RecordState.capabilities.webcam === true && Adapters.RecordState.cameras.length > 0
    readonly property string desktopSource: resolve("desktop", options.option("desktopAudio") ? "default" : "no", desktopChoices)
    readonly property string micSource: resolve("mic", options.option("microphone") ? "default" : "no", micChoices)
    readonly property string cameraPath: webcamPossible
        ? resolve("camera", options.option("webcam") ? Adapters.RecordState.cameras[0].path : "", cameraChoices) : ""
    function resolve(key, fallback, choices) {
        const picked = RecordPanelState.picks[key]
        const valid = value => choices.some(entry => entry.value === value)
        return picked !== undefined && valid(picked) ? picked : valid(fallback) ? fallback : choices[0].value
    }
    readonly property int countdown: countdownChoice === undefined ? options.option("countdown") : countdownChoice
    readonly property bool available: Adapters.RecordState.capabilities.available === true
    readonly property bool running: Adapters.RecordState.active
    readonly property bool canStart: available && picker.target.length > 0 && !Adapters.RecordState.active
    readonly property var countdownChoices: [0, 3, 5, 10].map(seconds =>
        ({ label: seconds === 0 ? qsTr("No countdown") : qsTr("%1 seconds").arg(seconds), value: seconds }))
    // The recording that was just saved, only while it is news: announced once, and gone as soon as
    // the panel has been opened again. The script already drops it when the file is deleted.
    readonly property var savedHint: {
        const result = Adapters.RecordState.lastResult
        return result && result.id !== RecordPanelState.acknowledgedResult ? result : null
    }
    onSavedHintChanged: if (savedHint) RecordPanelState.displayedResult = savedHint.id
    readonly property Controls.PanelContext contextPopup: context

    function activate() {
        // What was shown last time is old now.
        RecordPanelState.acknowledgedResult = RecordPanelState.displayedResult
        failures.close()
        context.close()
        options.refresh()
        Adapters.RecordState.loadAudioSources()
        Adapters.RecordState.loadCameras()
        countdownChoice = undefined
        Adapters.RecordState.loadCapabilities()
        Adapters.RecordState.loadMonitors()
        Adapters.RecordState.loadWindows()
        Adapters.RecordState.loadLastRegion()
        picker.kind = RecordPanelState.initialKind
        if (RecordPanelState.initialAction === "pick") Qt.callLater(() => picker.pickRegionRequested())
        picker.windowAddress = ""
        picker.region = ""
        motion.enter()
        Qt.callLater(focusFirst)
        if (RecordPanelState.pendingFailure) {
            const failure = RecordPanelState.pendingFailure
            RecordPanelState.pendingFailure = null
            Qt.callLater(() => failures.present(failure, root.Window.window ? root.Window.window.activeFocusItem : null))
        }
        if (RecordPanelState.initialContext) Qt.callLater(() => showContext(RecordPanelState.initialContext))
    }
    function focusFirst() { if (running) stopButton.forceActiveFocus(); else picker.focusFirst() }
    // One line: what is being recorded, and with which sound.
    function describe(recorded) {
        const target = recorded.target ?? ""
        const what = target.startsWith("monitor:") ? target.slice(8) : target.startsWith("window:") ? qsTr("a window") : qsTr("a region")
        const audio = recorded.audio ?? []
        return what + "  ·  " + (audio.includes("desktop") ? (recorded.desktopSource ?? qsTr("desktop audio")) : qsTr("no sound"))
            + (audio.includes("mic") ? "  ·  " + (recorded.micSource ?? qsTr("microphone")) : "")
    }
    function showContext(kind) {
        if (failures.visible) return
        if (kind === "info") {
            context.infoTitle = qsTr("Screen recording")
            context.infoDescription = qsTr("Choose a screen, a window or a region, then Start. The recording keeps running when this panel closes: the bar shows it and stops it, and so does the same key that opened this panel.")
            context.infoDetails = [
                { label: qsTr("Recorder"), value: Adapters.RecordState.capabilities.backend ?? qsTr("not found") },
                { label: qsTr("State"), value: Adapters.RecordState.state },
                { label: qsTr("Target"), value: picker.target },
                { label: qsTr("Camera"), value: webcamPossible ? (cameraChoices.find(entry => entry.value === cameraPath)?.label ?? "") : qsTr("none") }
            ]
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function requestClose() { motion.leave() }
    function startRecording() {
        if (!canStart) return
        Adapters.RecordState.start(picker.target, { desktopAudio: desktopSource, microphone: micSource, countdown: countdown,
            fps: options.option("fps"), quality: options.option("quality"), codec: options.option("codec"), audioCodec: options.option("audioCodec"), bitrate: options.option("bitrate"),
            container: options.option("container"), cursor: options.option("cursor"),
            webcam: cameraPath })
        // With a countdown the panel stays to show it, and Esc cancels; it leaves a second before
        // the recorder starts so it is not in the first frames. Without one it leaves now.
        if (countdown === 0) requestClose()
    }

    Keys.onPressed: event => {
        inputState.keyboardUsed()
        if (failures.visible) {
            if (event.key === Config.ErrorPanels.dismissKey) failures.close()
            event.accepted = true
            return
        }
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === Config.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        if (event.key === Config.Keyboard.cancelKey) {
            // During the countdown Esc cancels the recording as well as leaving.
            if (running && Adapters.RecordState.state === "starting" && Adapters.RecordState.remaining > 1) Adapters.RecordState.stop()
            requestClose()
            event.accepted = true
        }
    }
    Component.onCompleted: { if (open) activate() }
    onOpenChanged: if (open) activate()
    onRunningChanged: if (open) Qt.callLater(focusFirst)
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Adapters.ComponentSettings {
        id: options
        component: "record"
        screenName: root.screenName
        onFailed: failures.present(options.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Connections {
        target: Adapters.RecordState
        function onRemainingChanged() {
            if (root.open && Adapters.RecordState.state === "starting" && Adapters.RecordState.remaining <= 1) root.requestClose()
        }
        function onStateChanged() {
            if (root.open && Adapters.RecordState.state === "recording") root.requestClose()
        }
        function onRegionPicked(region) { if (!root.open) return; picker.note = ""; picker.region = region; picker.kind = "region"; Qt.callLater(root.focusFirst) }
        function onRegionCancelled() { if (!root.open) return; picker.note = qsTr("No region was selected (cancelled, or a click without a drag). Drag a rectangle, or type one below."); Qt.callLater(root.focusFirst) }
        function onFailed(failure) { failures.present(failure, root.Window.window ? root.Window.window.activeFocusItem : null) }
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: options
        shortcutsEnabled: !failures.visible
        bindings: [
            { key: Qt.Key_Left, modifiers: Qt.NoModifier, action: qsTr("Previous kind: screen, window or region") },
            { key: Qt.Key_Right, modifiers: Qt.NoModifier, action: qsTr("Next kind: screen, window or region") },
            { key: Qt.Key_Up, modifiers: Qt.NoModifier, action: qsTr("Previous entry in the list") },
            { key: Qt.Key_Down, modifiers: Qt.NoModifier, action: qsTr("Next entry in the list") },
            { key: Qt.Key_Return, modifiers: Qt.NoModifier, action: qsTr("Choose a target, toggle an option, or Start") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Recording information") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Config.Keyboard.settingsKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component settings") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then close panel") }
        ]
        onRequested: kind => root.showContext(kind)
    }
    Controls.ErrorPopup {
        id: failures
        owner: root
        style: styleTokens
        inputState: root.inputState
    }

    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(Config.ContextPanels.scrimOpacity)
        MouseArea { anchors.fill: parent; onClicked: root.requestClose() }
    }
    Rectangle {
        id: card
        width: Math.min(root.width - Config.Record.outerMargin * 2, Config.Record.maximumWidth)
        y: styleTokens.barHeight + Config.Record.outerMargin
        height: layout.implicitHeight + Config.Record.padding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        transform: Translate { y: motion.offset }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            x: Config.Record.padding
            y: Config.Record.padding
            width: parent.width - Config.Record.padding * 2
            spacing: Config.Record.sectionSpacing

            // ---- a recording is starting or running: its state, with Stop focused ----
            ColumnLayout {
                id: runningView
                visible: root.running
                Layout.fillWidth: true
                spacing: Config.Record.sectionSpacing
                Text {
                    text: Adapters.RecordState.state === "starting"
                        ? (Adapters.RecordState.remaining > 0 ? qsTr("Starting in %1 s").arg(Adapters.RecordState.remaining) : qsTr("Starting…"))
                        : qsTr("Recording  %1").arg(Adapters.RecordState.clock(Adapters.RecordState.elapsed))
                    color: styleTokens.text
                    font.family: styleTokens.monoFamily
                    font.pointSize: styleTokens.displayPointSize
                    font.weight: styleTokens.emphasisWeight
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: root.describe(Adapters.RecordState.recorded)
                    color: styleTokens.textMuted
                    font.family: styleTokens.monoFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Text {
                    Layout.fillWidth: true
                    visible: (Adapters.RecordState.recorded.warnings ?? []).length > 0
                    wrapMode: Text.Wrap
                    text: (Adapters.RecordState.recorded.warnings ?? []).join("\n")
                    color: styleTokens.warning
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Controls.ShellButton {
                        id: stopButton
                        text: Adapters.RecordState.state === "starting" ? qsTr("Cancel") : qsTr("Stop")
                        style: styleTokens
                        inputState: root.inputState
                        emphasis: Theme.Interaction.primaryActionEmphasis
                        onClicked: { Adapters.RecordState.stop(); root.requestClose() }
                    }
                }
            }

            // ---- nothing is recording: choose and start ----
            ColumnLayout {
                id: idleView
                visible: !root.running
                Layout.fillWidth: true
                spacing: Config.Record.sectionSpacing
                Controls.TargetPicker {
                    id: picker
                    Layout.fillWidth: true
                    style: styleTokens
                    inputState: root.inputState
                    monitors: Adapters.RecordState.monitors
                    windows: Adapters.RecordState.windows
                    kinds: (Adapters.RecordState.capabilities.targets ?? ["monitor"])
                    lastRegion: Adapters.RecordState.lastRegion
                    onPickRegionRequested: { picker.note = qsTr("Drag a rectangle on the screen. Esc or a right click cancels."); Adapters.RecordState.pickRegion() }
                }

                // Explicit choices: each picker lists Off, the default device and every device the
                // recorder can use, so nothing is implicit.
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: styleTokens.spacingTight
                    Repeater {
                        model: [
                            { key: "desktop", label: qsTr("Desktop audio"), choices: root.desktopChoices, current: root.desktopSource, shown: true },
                            { key: "mic", label: qsTr("Microphone"), choices: root.micChoices, current: root.micSource, shown: true },
                            { key: "camera", label: qsTr("Webcam"), choices: root.cameraChoices, current: root.cameraPath, shown: root.webcamPossible }
                        ]
                        RowLayout {
                            id: pickRow
                            required property var modelData
                            visible: modelData.shown
                            Layout.fillWidth: true
                            spacing: styleTokens.spacing
                            Text {
                                Layout.preferredWidth: Config.ContextPanels.optionLabelWidth
                                text: pickRow.modelData.label
                                color: styleTokens.textMuted
                                font.family: styleTokens.uiFamily
                                font.pointSize: styleTokens.bodyPointSize
                            }
                            Controls.ShellComboBox {
                                id: pickBox
                                objectName: "recordPick-" + pickRow.modelData.key
                                Layout.fillWidth: true
                                style: styleTokens
                                inputState: root.inputState
                                emphasis: Theme.Interaction.selectorEmphasis
                                optionEmphasis: Theme.Interaction.selectorOptionEmphasis
                                model: pickRow.modelData.choices
                                textRole: "label"
                                Accessible.name: pickRow.modelData.label
                                Binding { target: pickBox; property: "currentIndex"; value: Math.max(0, pickRow.modelData.choices.findIndex(entry => entry.value === pickRow.modelData.current)) }
                                onActivated: index => RecordPanelState.pick(pickRow.modelData.key, pickRow.modelData.choices[index].value)
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: styleTokens.spacing
                        Text {
                            Layout.preferredWidth: Config.ContextPanels.optionLabelWidth
                            text: qsTr("Countdown")
                            color: styleTokens.textMuted
                            font.family: styleTokens.uiFamily
                            font.pointSize: styleTokens.bodyPointSize
                        }
                        Controls.ShellComboBox {
                            id: countdownBox
                            Layout.fillWidth: true
                            style: styleTokens
                            inputState: root.inputState
                            emphasis: Theme.Interaction.selectorEmphasis
                            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
                            model: root.countdownChoices
                            textRole: "label"
                            Accessible.name: qsTr("Countdown")
                            Binding { target: countdownBox; property: "currentIndex"; value: Math.max(0, root.countdownChoices.findIndex(entry => entry.value === root.countdown)) }
                            onActivated: index => root.countdownChoice = root.countdownChoices[index].value
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.available && (Adapters.RecordState.capabilities.screens ?? 1) === 0
                    wrapMode: Text.Wrap
                    text: qsTr("GPU Screen Recorder sees no screen here. It captures through the GPU, so it cannot record a nested test session: run the shell on your real desktop (make dev-run).")
                    color: styleTokens.warning
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.available && !root.webcamPossible
                    wrapMode: Text.Wrap
                    text: qsTr("No camera was found, so there is no webcam overlay.")
                    color: styleTokens.textMuted
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.available && !root.micPossible
                    wrapMode: Text.Wrap
                    text: qsTr("No microphone was found, so the microphone is unavailable.")
                    color: styleTokens.warning
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.available && !root.audioPossible && (Adapters.RecordState.capabilities.audioNote ?? "").length > 0
                    wrapMode: Text.Wrap
                    text: (Adapters.RecordState.capabilities.audioNote ?? "") + " " + qsTr("The recording will have no sound.")
                    color: styleTokens.warning
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Text {
                    Layout.fillWidth: true
                    visible: !root.available
                    wrapMode: Text.Wrap
                    text: qsTr("GPU Screen Recorder was not found. Install gpu-screen-recorder to record.")
                    color: styleTokens.warning
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.bodyPointSize
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Controls.ShellButton {
                        id: startButton
                        text: root.countdown > 0 ? qsTr("Start in %1 s").arg(root.countdown) : qsTr("Start")
                        enabled: root.canStart
                        style: styleTokens
                        inputState: root.inputState
                        emphasis: Theme.Interaction.primaryActionEmphasis
                        onClicked: root.startRecording()
                    }
                }
                // The recording that was just saved: where it is and how big, with its path to copy.
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.savedHint !== null
                    spacing: styleTokens.spacing
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                        text: root.savedHint
                            ? qsTr("Saved %1  ·  %2").arg(root.savedHint.output.split("/").pop()).arg(Adapters.RecordState.size(root.savedHint.size))
                            : ""
                        color: styleTokens.textMuted
                        font.family: styleTokens.monoFamily
                        font.pointSize: styleTokens.captionPointSize
                    }
                    Controls.ShellButton {
                        text: pathCopied ? qsTr("Copied") : qsTr("Copy path")
                        property bool pathCopied: false
                        style: styleTokens
                        inputState: root.inputState
                        emphasis: Theme.Interaction.buttonEmphasis
                        Accessible.name: qsTr("Copy the path of the saved recording")
                        onClicked: {
                            pathText.text = root.savedHint.output
                            pathText.selectAll(); pathText.copy(); pathText.deselect()
                            pathCopied = true
                        }
                    }
                    // Native Qt clipboard copy, as the error popup does; no clipboard command.
                    TextEdit { id: pathText; visible: false; readOnly: true }
                }
            }
        }
    }
}

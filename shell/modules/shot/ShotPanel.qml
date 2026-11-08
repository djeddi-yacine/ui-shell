pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// Screenshot: pick what to capture, pick where the picture goes, press Capture. The panel's window
// is hidden while the picture is taken and comes back showing what was saved. The lists of
// screens, windows and the region selection are shared with the recording panel.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    property bool open: false
    // The user's choices override the saved defaults for this picture only.
    property var copyChoice: undefined
    property var saveChoice: undefined
    signal closed()
    readonly property bool copy: copyChoice === undefined ? options.option("copyToClipboard") : copyChoice
    readonly property bool save: saveChoice === undefined ? options.option("saveToFile") : saveChoice
    readonly property bool available: Adapters.ShotRunner.capabilities.available === true
    readonly property bool canCapture: available && picker.target.length > 0 && (copy || save) && !Adapters.ShotRunner.busy
    // The picture that was just taken, only while it is news (announced once) and while its file exists.
    readonly property var savedHint: {
        const result = Adapters.ShotRunner.lastResult
        return result && result.id !== ShotPanelState.acknowledgedResult ? result : null
    }
    onSavedHintChanged: if (savedHint) ShotPanelState.displayedResult = savedHint.id
    readonly property Controls.PanelContext contextPopup: context

    function activate() {
        // What was shown last time is old now; and a picture whose file was deleted is dropped.
        ShotPanelState.acknowledgedResult = ShotPanelState.displayedResult
        Adapters.ShotRunner.verifyLast()
        failures.close()
        context.close()
        options.refresh()
        copyChoice = undefined
        saveChoice = undefined
        ShotPanelState.capturing = false
        Adapters.ShotRunner.loadCapabilities()
        Adapters.RecordState.loadMonitors()
        Adapters.RecordState.loadWindows()
        Adapters.RecordState.loadLastRegion()
        picker.kind = "monitor"
        picker.windowAddress = ""
        picker.region = ""
        picker.note = ""
        motion.enter()
        Qt.callLater(focusFirst)
        if (ShotPanelState.initialContext) Qt.callLater(() => showContext(ShotPanelState.initialContext))
    }
    function focusFirst() { picker.focusFirst() }
    function showContext(kind) {
        if (failures.visible) return
        if (kind === "info") {
            context.infoTitle = qsTr("Screenshot")
            context.infoDescription = qsTr("Choose a screen, a window or a region, choose where the picture goes, then Capture. The panel hides while the picture is taken so it is not in it, and comes back showing what was saved.")
            context.infoDetails = [
                { label: qsTr("Target"), value: picker.target },
                { label: qsTr("Clipboard"), value: root.copy ? qsTr("yes") : qsTr("no") },
                { label: qsTr("File"), value: root.save ? qsTr("yes") : qsTr("no") }
            ]
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function requestClose() { motion.leave() }
    function capture() {
        if (!canCapture) return
        ShotPanelState.capturing = true
        Adapters.ShotRunner.capture(picker.target, { copy: copy, save: save, delay: Config.Shot.closeDelayMilliseconds })
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
        if (event.key === Config.Keyboard.cancelKey) { requestClose(); event.accepted = true }
    }
    Component.onCompleted: { if (open) activate() }
    onOpenChanged: if (open) activate()
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Adapters.ComponentSettings {
        id: options
        component: "shot"
        screenName: root.screenName
        onFailed: failures.present(options.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Connections {
        target: Adapters.ShotRunner
        function onCaptured() { ShotPanelState.capturing = false; Qt.callLater(root.focusFirst) }
        function onFailed(failure) {
            ShotPanelState.capturing = false
            failures.present(failure, root.Window.window ? root.Window.window.activeFocusItem : null)
        }
    }
    Connections {
        target: Adapters.RecordState
        function onRegionPicked(region) { if (root.open) { picker.note = ""; picker.region = region; picker.kind = "region"; Qt.callLater(root.focusFirst) } }
        function onRegionCancelled() { if (root.open) { picker.note = qsTr("No region was selected (cancelled, or a click without a drag). Drag a rectangle, or type one below."); Qt.callLater(root.focusFirst) } }
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
            { key: Qt.Key_Return, modifiers: Qt.NoModifier, action: qsTr("Choose a target, toggle an option, or Capture") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Screenshot information") },
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
        width: Math.min(root.width - Config.Shot.outerMargin * 2, Config.Shot.maximumWidth)
        y: Config.Placement.y(Config.Shot.placement, root.height, card.height, styleTokens.barHeight, Config.Shot.outerMargin)
        height: layout.implicitHeight + Config.Shot.padding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        transform: Translate { y: motion.offset }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: layout
            x: Config.Shot.padding
            y: Config.Shot.padding
            width: parent.width - Config.Shot.padding * 2
            spacing: Config.Shot.sectionSpacing

            Controls.TargetPicker {
                id: picker
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                monitors: Adapters.RecordState.monitors
                windows: Adapters.RecordState.windows
                kinds: Adapters.ShotRunner.capabilities.targets ?? ["monitor"]
                lastRegion: Adapters.RecordState.lastRegion
                onPickRegionRequested: { picker.note = qsTr("Drag a rectangle on the screen. Esc or a right click cancels."); Adapters.RecordState.pickRegion() }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: styleTokens.spacing
                Controls.ShellButton {
                    Layout.fillWidth: true
                    text: root.copy ? qsTr("Clipboard: on") : qsTr("Clipboard: off")
                    Accessible.name: root.copy ? qsTr("The picture is copied to the clipboard") : qsTr("The picture is not copied")
                    enabled: Adapters.ShotRunner.capabilities.clipboard === true
                    style: styleTokens
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    selected: root.copy
                    onClicked: root.copyChoice = !root.copy
                }
                Controls.ShellButton {
                    Layout.fillWidth: true
                    text: root.save ? qsTr("File: on") : qsTr("File: off")
                    Accessible.name: root.save ? qsTr("The picture is saved to a file") : qsTr("The picture is not saved")
                    style: styleTokens
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    selected: root.save
                    onClicked: root.saveChoice = !root.save
                }
            }
            Text {
                Layout.fillWidth: true
                visible: !root.available
                wrapMode: Text.Wrap
                text: qsTr("grim was not found. Install grim to take screenshots.")
                color: styleTokens.warning
                font.family: styleTokens.uiFamily
                font.pointSize: styleTokens.bodyPointSize
            }
            Text {
                Layout.fillWidth: true
                visible: root.available && !root.copy && !root.save
                wrapMode: Text.Wrap
                text: qsTr("Turn on the clipboard or the file: a screenshot needs somewhere to go.")
                color: styleTokens.warning
                font.family: styleTokens.uiFamily
                font.pointSize: styleTokens.captionPointSize
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Controls.ShellButton {
                    id: captureButton
                    text: qsTr("Capture")
                    enabled: root.canCapture
                    style: styleTokens
                    inputState: root.inputState
                    emphasis: Theme.Interaction.primaryActionEmphasis
                    onClicked: root.capture()
                }
            }
            // What was just taken: where it went and how big it is, with its path to copy.
            RowLayout {
                Layout.fillWidth: true
                visible: root.savedHint !== null
                spacing: styleTokens.spacing
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    text: {
                        const result = root.savedHint
                        if (!result) return ""
                        const where = [result.file ? qsTr("saved %1").arg(result.file.split("/").pop()) : "", result.copied ? qsTr("copied") : ""]
                            .filter(part => part.length > 0).join(qsTr("  ·  "))
                        return where + qsTr("  ·  %1").arg(Adapters.RecordState.size(result.size))
                    }
                    color: styleTokens.textMuted
                    font.family: styleTokens.monoFamily
                    font.pointSize: styleTokens.captionPointSize
                }
                Controls.ShellButton {
                    visible: root.savedHint !== null && root.savedHint.file !== null
                    property bool pathCopied: false
                    text: pathCopied ? qsTr("Copied") : qsTr("Copy path")
                    Accessible.name: qsTr("Copy the path of the screenshot")
                    style: styleTokens
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    onClicked: {
                        pathText.text = root.savedHint.file
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

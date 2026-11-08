pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// Audio control, one task per tab: output and input devices, playback and recording
// streams (with the device each one uses), sound cards, and the patchbay. Control only.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    property bool open: false
    property string tab: AudioState.initialTab
    signal closed()
    readonly property var graph: audio.graph
    readonly property var sinks: graph.sinks ?? []
    readonly property var sources: graph.sources ?? []
    readonly property var playback: (graph.streams ?? []).filter(stream => stream.kind === "playback")
    readonly property var recording: (graph.streams ?? []).filter(stream => stream.kind === "record")
    readonly property var cards: graph.cards ?? []
    readonly property var defaultSink: sinks.find(sink => sink.default) ?? null
    readonly property int maximumVolume: options.option("maximumVolume")
    readonly property int volumeStep: options.option("volumeStep")
    readonly property Controls.PanelContext contextPopup: context
    readonly property var tabs: [
        { key: "output", label: qsTr("Output"), count: sinks.length },
        { key: "input", label: qsTr("Input"), count: sources.length },
        { key: "playback", label: qsTr("Playback"), count: playback.length },
        { key: "recording", label: qsTr("Recording"), count: recording.length },
        { key: "cards", label: qsTr("Cards"), count: cards.length },
        { key: "patchbay", label: qsTr("Patchbay"), count: -1 }
    ]
    readonly property var currentTab: tabs.find(entry => entry.key === tab) ?? tabs[0]
    // The rows of the volume tabs; cards and patchbay have their own views.
    readonly property bool devicesTab: tab === "output" || tab === "input"
    readonly property var rows: tab === "output" ? sinks : tab === "input" ? sources
        : tab === "playback" ? playback : tab === "recording" ? recording : []
    // Ids of the rows, replaced only when the list itself changes, not on every volume update.
    property var rowIds: []
    onRowsChanged: {
        const ids = rows.map(item => item.id)
        if (ids.join() !== rowIds.join()) rowIds = ids
    }
    // A wheel gesture that scrolls the list keeps scrolling it instead of moving a slider.
    property bool scrolling: false
    readonly property var chooserDevices: tab === "playback" ? sinks : sources
    readonly property string emptyText: tab === "playback" ? qsTr("Nothing is playing.")
        : tab === "recording" ? qsTr("Nothing is recording.")
        : tab === "output" ? qsTr("No output devices.") : qsTr("No input devices.")

    function activate() {
        failures.close()
        context.close()
        options.refresh()
        audio.refresh()
        motion.enter()
        Qt.callLater(focusCurrentTab)
        if (AudioState.initialContext) Qt.callLater(() => showContext(AudioState.initialContext))
    }
    // The buttons exist only after the first layout; focus the open tab then.
    function focusCurrentTab() {
        const button = tabBar.itemAt(Math.max(0, tabs.findIndex(entry => entry.key === tab)))
        if (button) button.forceActiveFocus()
    }
    function showContext(kind) {
        if (failures.visible) return
        if (kind === "info") {
            context.infoTitle = qsTr("Audio")
            context.infoDescription = root.defaultSink ? qsTr("Playing through %1").arg(root.defaultSink.label) : ""
            context.infoDetails = [
                { label: qsTr("Default output"), value: root.graph.defaults?.sink ?? "" },
                { label: qsTr("Default input"), value: root.graph.defaults?.source ?? "" },
                { label: qsTr("Playback"), value: String(root.playback.length) },
                { label: qsTr("Recording"), value: String(root.recording.length) },
                { label: qsTr("Links"), value: String((root.graph.links ?? []).length) }
            ]
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function requestClose() { motion.leave() }
    function selectTab(key) {
        tab = key
        if (key === "patchbay") Qt.callLater(() => patch.forceActiveFocus())
    }
    // Where a stream is routed, as a choice value: a device name, or "default".
    function choiceFor(stream, devices) {
        if (typeof stream.target === "string") return stream.target
        if (typeof stream.target === "number") {
            const device = devices.find(entry => entry.id === stream.target)
            return device ? device.name : "default"
        }
        return "default"
    }
    function choicesFor(devices) {
        return [{ label: qsTr("Follow default"), value: "default" }]
            .concat(devices.map(device => ({ label: device.label, value: device.name })))
    }
    function reveal(item) {
        if (!item || !flick.contentItem) return
        const y = item.mapToItem(flick.contentItem, 0, 0).y
        if (y < 0 || y > flick.contentHeight) return
        if (y < flick.contentY) flick.contentY = y
        else if (y + item.height > flick.contentY + flick.height) flick.contentY = y + item.height - flick.height
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
    Component.onCompleted: { rowIds = rows.map(item => item.id); if (open) activate() }
    onOpenChanged: if (open) activate()
    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() { root.reveal(root.Window.window.activeFocusItem) }
    }
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Adapters.AudioGraph { id: audio; active: root.open }
    Adapters.ComponentSettings {
        id: options
        component: "audio"
        screenName: root.screenName
        onFailed: failures.present(options.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: options
        shortcutsEnabled: !failures.visible
        bindings: [
            { key: Qt.Key_Left, modifiers: Qt.NoModifier, action: qsTr("Lower volume, or previous tab") },
            { key: Qt.Key_Right, modifiers: Qt.NoModifier, action: qsTr("Raise volume, or next tab") },
            { key: Qt.Key_M, modifiers: Qt.NoModifier, action: qsTr("Mute or unmute the focused row") },
            { key: Qt.Key_D, modifiers: Qt.NoModifier, action: qsTr("Make the focused device the default") },
            { key: Qt.Key_Up, modifiers: Qt.NoModifier, action: qsTr("Patchbay: previous row") },
            { key: Qt.Key_Down, modifiers: Qt.NoModifier, action: qsTr("Patchbay: next row") },
            { key: Qt.Key_Return, modifiers: Qt.NoModifier, action: qsTr("Press or choose; in the patchbay select a node, then another to link or unlink") },
            { key: Qt.Key_X, modifiers: Qt.NoModifier, action: qsTr("Patchbay: remove the links of a node") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Audio information") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Config.Keyboard.settingsKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component settings") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, leave link mode, then close panel") }
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
        width: Math.min(root.width - Config.Audio.outerMargin * 2, Config.Audio.maximumWidth)
        y: Config.Placement.y(Config.Audio.placement, root.height, height, styleTokens.barHeight, Config.Audio.outerMargin)
        // Fits under the bar whatever the placement.
        height: Math.min(root.height - styleTokens.barHeight - Config.Audio.outerMargin * 2, Config.Audio.maximumHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        transform: Translate { y: motion.offset }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.Audio.padding
            spacing: styleTokens.spacingLoose

            // One tab per task; Left and Right move between them.
            RowLayout {
                spacing: styleTokens.spacingTight
                Repeater {
                    id: tabBar
                    model: root.tabs
                    Controls.ShellButton {
                        id: tabButton
                        required property var modelData
                        required property int index
                        text: modelData.label
                        style: styleTokens
                        inputState: root.inputState
                        emphasis: Theme.Interaction.buttonEmphasis
                        selected: root.tab === modelData.key
                        Accessible.name: modelData.label
                        onClicked: root.selectTab(modelData.key)
                        Keys.onLeftPressed: event => { tabBar.itemAt(Math.max(0, index - 1)).forceActiveFocus(); event.accepted = true }
                        Keys.onRightPressed: event => { tabBar.itemAt(Math.min(root.tabs.length - 1, index + 1)).forceActiveFocus(); event.accepted = true }
                        // Space or Enter on a focused tab opens it; arrows only move focus.
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: audio.error.length > 0
                    text: audio.error
                    color: styleTokens.negative
                    elide: Text.ElideRight
                    Layout.maximumWidth: Config.Audio.errorMaximumWidth
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: content.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                onContentYChanged: { root.scrolling = true; scrollQuiet.restart() }
                Timer { id: scrollQuiet; interval: Theme.Motion.scrollQuietDelay; onTriggered: root.scrolling = false }

                ColumnLayout {
                    id: content
                    width: flick.width
                    spacing: Config.Audio.rowSpacing

                    // The tab's name and size, ruled like the references' section labels.
                    RowLayout {
                        Layout.topMargin: Config.Audio.sectionSpacing - styleTokens.cardPadding
                        spacing: styleTokens.spacingTight
                        Text {
                            text: root.currentTab.label.toUpperCase()
                            color: styleTokens.controls.muted
                            font.family: styleTokens.monoFamily
                            font.pointSize: styleTokens.captionPointSize
                            font.letterSpacing: styleTokens.labelLetterSpacing
                        }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Theme.Shape.borderWidth; color: styleTokens.rule }
                        Text {
                            visible: root.currentTab.count >= 0
                            text: String(root.currentTab.count)
                            color: styleTokens.controls.muted
                            font.family: styleTokens.monoFamily
                            font.pointSize: styleTokens.captionPointSize
                        }
                    }

                    // ---- Output, Input, Playback, Recording: one list of rows ----
                    Repeater {
                        // Rows are keyed by id, so a graph refresh updates them in place and never
                        // rebuilds one (a rebuilt slider would drop the drag in progress).
                        model: root.rowIds
                        AudioRow {
                            id: row
                            required property int modelData
                            readonly property var entry: root.rows.find(item => item.id === modelData)
                                ?? ({ label: "", appName: "", volume: null, muted: false, default: false })
                            Layout.fillWidth: true
                            style: styleTokens
                            inputState: root.inputState
                            title: root.devicesTab ? entry.label : entry.appName
                            subtitle: root.devicesTab ? "" : entry.label
                            volume: entry.volume
                            muted: entry.muted
                            maximumPercent: root.maximumVolume
                            stepPercent: root.volumeStep
                            wheelAllowed: !root.scrolling
                            showDefault: root.devicesTab
                            isDefault: root.devicesTab && entry.default
                            tag: root.devicesTab && entry.default ? qsTr("Default") : ""
                            choices: root.devicesTab ? [] : root.choicesFor(root.chooserDevices)
                            choice: root.devicesTab ? "" : root.choiceFor(entry, root.chooserDevices)
                            chooserLabel: root.tab === "recording" ? qsTr("Input of %1").arg(entry.appName) : ""
                            onDefaultRequested: audio.run(["default", modelData])
                            onVolumeMoved: percent => audio.run(["volume", modelData, percent], "v" + modelData)
                            onMuteToggled: audio.run(["mute", modelData, "toggle"])
                            onChoiceMade: value => audio.run(["move", modelData, value])
                        }
                    }
                    Text {
                        visible: root.rows.length === 0 && root.tab !== "cards" && root.tab !== "patchbay"
                        text: root.emptyText
                        color: styleTokens.textMuted
                        font.family: styleTokens.uiFamily
                        font.pointSize: styleTokens.bodyPointSize
                    }

                    // ---- Cards ----
                    Repeater {
                        model: root.tab === "cards" ? root.cards : []
                        RowLayout {
                            id: cardRow
                            required property var modelData
                            readonly property var profiles: modelData.profiles.filter(profile => profile.available !== "no")
                            Layout.fillWidth: true
                            spacing: styleTokens.controlPaddingX
                            Text {
                                Layout.fillWidth: true
                                text: cardRow.modelData.label
                                color: styleTokens.text
                                elide: Text.ElideRight
                                font.family: styleTokens.uiFamily
                                font.pointSize: styleTokens.bodyPointSize
                            }
                            Controls.ShellComboBox {
                                id: profileChooser
                                Layout.preferredWidth: Config.Audio.cardChooserWidth
                                style: styleTokens
                                inputState: root.inputState
                                emphasis: Theme.Interaction.selectorEmphasis
                                optionEmphasis: Theme.Interaction.selectorOptionEmphasis
                                model: cardRow.profiles
                                textRole: "description"
                                Accessible.name: qsTr("Profile of %1").arg(cardRow.modelData.label)
                                Binding { target: profileChooser; property: "currentIndex"
                                    value: Math.max(0, cardRow.profiles.findIndex(profile => profile.index === cardRow.modelData.profile)) }
                                onActivated: index => audio.run(["profile", cardRow.modelData.id, cardRow.profiles[index].index])
                            }
                        }
                    }

                    // ---- Patchbay ----
                    PatchView {
                        id: patch
                        visible: root.tab === "patchbay"
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? implicitHeight : 0
                        style: styleTokens
                        inputState: root.inputState
                        graph: root.graph
                        onConnectRequested: (out, into) => audio.run(["connect", out, into])
                        onDisconnectRequested: (out, into) => audio.run(["disconnect", out, into])
                        onDisconnectNodeRequested: (node, isSource) => {
                            // Every node the clicked node is linked to, from whichever side it is on.
                            const links = root.graph.links.filter(link => isSource ? link.outNode === node : link.inNode === node)
                            const others = new Set(links.map(link => isSource ? link.inNode : link.outNode))
                            others.forEach(other => audio.run(isSource ? ["disconnect", node, other] : ["disconnect", other, node]))
                        }
                    }
                }
            }
        }
    }
}

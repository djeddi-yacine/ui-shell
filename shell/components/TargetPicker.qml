pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

// What to capture: a screen, a window or a region. Pure presentation: the lists come in as
// properties and the choice goes out as `target` ("monitor:NAME", "window:ADDRESS" or
// "region:WxH+X+Y", empty while nothing valid is chosen); picking a region with the pointer
// is requested with a signal, because the panel must get out of the way for it. Shared by the
// recording and screenshot panels. Keys: Left/Right change the kind, Up/Down move in a list.
ColumnLayout {
    id: root
    required property var style
    required property InputState inputState
    // [{ name, width, height }]
    property var monitors: []
    // [{ address, title, class, width, height }]
    property var windows: []
    // The kinds the backend offers, in this order: monitor, window, region.
    property var kinds: ["monitor", "window", "region"]
    // The last region the user selected this session, "" if none.
    property string lastRegion: ""
    property string kind: "monitor"
    property string monitor: ""
    property string windowAddress: ""
    property string region: ""
    // A line under the region button: what the last pointer selection did (cancelled, failed).
    property string note: ""
    readonly property bool regionValid: /^[1-9][0-9]{0,4}x[1-9][0-9]{0,4}\+[0-9]{1,6}\+[0-9]{1,6}$/.test(region)
    readonly property string target: kind === "monitor" ? (monitor ? "monitor:" + monitor : "")
        : kind === "window" ? (windowAddress && windows.some(entry => entry.address === windowAddress) ? "window:" + windowAddress : "")
        : (regionValid ? "region:" + region : "")
    readonly property var kindLabels: ({ monitor: qsTr("Screen"), window: qsTr("Window"), region: qsTr("Region") })
    // Offer a "Pick" button that selects a window by clicking it on the screen.
    property bool pointerWindowPick: false
    signal pickRegionRequested()
    signal pickWindowRequested()
    // The user chose a screen or a window from a list (or the last region): the panel takes it at once.
    signal chosen()
    // Nothing is chosen until the user chooses: a choice that no longer exists is cleared, never
    // replaced, so Start cannot record something that was not picked.
    onMonitorsChanged: if (!monitors.some(entry => entry.name === monitor)) monitor = ""
    onWindowsChanged: if (!windows.some(entry => entry.address === windowAddress)) windowAddress = ""
    onKindsChanged: if (!kinds.includes(kind) && kinds.length > 0) kind = kinds[0]
    spacing: style.spacingTight

    function focusFirst() {
        const first = kind === "monitor" ? monitorList.itemAt(0) : kind === "window" ? (pickWindowButton.visible ? pickWindowButton : windowList.itemAt(0)) : selectButton
        if (first) first.forceActiveFocus()
        else kindRow.itemAt(Math.max(0, kinds.indexOf(kind)))?.forceActiveFocus()
    }
    function setKind(next) { if (kinds.includes(next)) kind = next }

    RowLayout {
        Layout.fillWidth: true
        spacing: root.style.spacingTight
        Repeater {
            id: kindRow
            model: root.kinds
            ShellButton {
                id: kindButton
                required property string modelData
                required property int index
                Layout.fillWidth: true
                text: root.kindLabels[modelData]
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.selectorEmphasis
                selected: root.kind === modelData
                Accessible.name: qsTr("Capture a %1").arg(root.kindLabels[modelData].toLowerCase())
                Keys.onLeftPressed: event => { const previous = kindRow.itemAt(index - 1); if (previous) { previous.forceActiveFocus(); root.setKind(root.kinds[index - 1]) } event.accepted = true }
                Keys.onRightPressed: event => { const next = kindRow.itemAt(index + 1); if (next) { next.forceActiveFocus(); root.setKind(root.kinds[index + 1]) } event.accepted = true }
                Keys.onDownPressed: event => { root.focusFirst(); event.accepted = true }
                onClicked: root.setKind(modelData)
            }
        }
    }

    // ---- screens ----
    ColumnLayout {
        visible: root.kind === "monitor"
        Layout.fillWidth: true
        spacing: root.style.spacingTight
        Repeater {
            id: monitorList
            model: root.monitors
            ShellButton {
                id: monitorRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                text: modelData.name + "   " + modelData.width + "×" + modelData.height
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.selectorEmphasis
                selected: modelData.name === root.monitor
                Accessible.name: qsTr("Record screen %1").arg(modelData.name)
                Keys.onUpPressed: event => { const previous = monitorList.itemAt(index - 1); if (previous) previous.forceActiveFocus(); else kindRow.itemAt(0)?.forceActiveFocus(); event.accepted = true }
                Keys.onDownPressed: event => { const next = monitorList.itemAt(index + 1); if (next) next.forceActiveFocus(); event.accepted = next !== null }
                onClicked: { root.monitor = modelData.name; root.chosen() }
            }
        }
        Text {
            visible: root.monitors.length === 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("No screens found.")
            color: root.style.textMuted
            font.family: root.style.uiFamily
            font.pointSize: root.style.bodyPointSize
        }
    }

    // ---- windows ----
    ShellButton {
        id: pickWindowButton
        visible: root.kind === "window" && root.pointerWindowPick
        Layout.fillWidth: true
        text: qsTr("Pick")
        Accessible.name: qsTr("Pick a window with the pointer")
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.buttonEmphasis
        Keys.onDownPressed: event => { windowList.itemAt(0)?.forceActiveFocus(); event.accepted = true }
        Keys.onUpPressed: event => { kindRow.itemAt(1)?.forceActiveFocus(); event.accepted = true }
        onClicked: root.pickWindowRequested()
    }
    Flickable {
        id: windowFlick
        visible: root.kind === "window"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(windowColumn.implicitHeight, root.style.listVisibleRows * (root.style.controlHeight + root.style.spacingTight))
        contentWidth: width
        contentHeight: windowColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        function reveal(item) {
            if (!item) return
            const y = item.mapToItem(windowFlick.contentItem, 0, 0).y
            if (y < contentY) contentY = y
            else if (y + item.height > contentY + height) contentY = y + item.height - height
        }
        ColumnLayout {
            id: windowColumn
            width: windowFlick.width
            spacing: root.style.spacingTight
            Repeater {
                id: windowList
                model: root.windows
                ShellButton {
                    id: windowRow
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    text: (modelData.title || modelData.class) + "   " + modelData.width + "×" + modelData.height
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.selectorEmphasis
                    selected: modelData.address === root.windowAddress
                    Accessible.name: qsTr("Record window %1").arg(modelData.title || modelData.class)
                    onActiveFocusChanged: if (activeFocus) windowFlick.reveal(windowRow)
                    Keys.onUpPressed: event => { const previous = windowList.itemAt(index - 1); if (previous) previous.forceActiveFocus(); else if (pickWindowButton.visible) pickWindowButton.forceActiveFocus(); else kindRow.itemAt(1)?.forceActiveFocus(); event.accepted = true }
                    Keys.onDownPressed: event => { const next = windowList.itemAt(index + 1); if (next) next.forceActiveFocus(); event.accepted = next !== null }
                    onClicked: { root.windowAddress = modelData.address; root.chosen() }
                }
            }
            Text {
                visible: root.windows.length === 0
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: qsTr("No windows to record.")
                color: root.style.textMuted
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
        }
    }

    // ---- region ----
    ColumnLayout {
        visible: root.kind === "region"
        Layout.fillWidth: true
        spacing: root.style.spacingTight
        ShellButton {
            id: selectButton
            Layout.fillWidth: true
            text: qsTr("Select a region with the pointer")
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            onClicked: root.pickRegionRequested()
        }
        Text {
            visible: root.note.length > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.note
            color: root.style.textMuted
            font.family: root.style.uiFamily
            font.pointSize: root.style.captionPointSize
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: root.style.spacingTight
            ShellTextField {
                id: regionField
                Layout.fillWidth: true
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.inputEmphasis
                text: root.region
                placeholderText: qsTr("WxH+X+Y, for example 800x600+100+50")
                maximumLength: 24
                validator: RegularExpressionValidator { regularExpression: /[0-9x+]*/ }
                Accessible.name: qsTr("Region, width x height plus x plus y")
                onTextEdited: root.region = text
            }
            ShellButton {
                visible: root.lastRegion.length > 0 && root.lastRegion !== root.region
                text: qsTr("Last: %1").arg(root.lastRegion)
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Use the last region %1").arg(root.lastRegion)
                onClicked: { root.region = root.lastRegion; root.chosen() }
            }
        }
        Text {
            visible: root.region.length > 0 && !root.regionValid
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("Write the region as width x height + x + y, for example 800x600+100+50.")
            color: root.style.warning
            font.family: root.style.uiFamily
            font.pointSize: root.style.captionPointSize
        }
    }
}

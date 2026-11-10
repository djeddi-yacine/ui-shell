pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config
import "../../adapters" as Adapters

// The clipboard history: a search field, the entries (newest first), a preview of the selected
// one and a line of keys. It fills its window; the window is the card. Choosing an entry copies
// it back to the clipboard and closes the panel. Nothing is kept once the panel is closed.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    // The history source. Tests replace it with a fake that has the same members.
    property var runner: Adapters.ClipboardRunner
    // Set by the window while it is mapped. Only the panel on screen reacts to the shared source.
    property bool shown: false
    signal closed()
    property string query: ""
    property int selectedIndex: -1
    // The selected entry's list line; it follows the entry when the list changes.
    property string selectedLine: ""
    // Shift+Delete was pressed: Enter now clears the whole history, Escape cancels.
    property bool confirmingClear: false
    // The picture preview of the selected entry: a data URL, or "" while there is none.
    property string previewSource: ""
    // "", "loading", "failed" or "tooLarge" for the selected picture.
    property string previewState: ""
    // The preview under the list is closed until Space or a right click asks for it.
    property bool previewOpen: false
    readonly property real previewReveal: previewOpen && selectedEntry !== null ? 1 : 0
    readonly property var matches: ClipboardSearch.results(runner.items, query)
    readonly property var selectedEntry: selectedIndex >= 0 && selectedIndex < matches.length ? matches[selectedIndex] : null
    readonly property bool ready: runner.state === "ok"
    readonly property bool busy: runner.busy
    readonly property bool closing: motion.closing
    readonly property bool contextOpen: context.visible
    readonly property Controls.PanelContext contextPopup: context
    readonly property bool errorOpen: failures.visible
    readonly property Controls.ErrorPopup errorPopup: failures
    readonly property alias entryView: list
    readonly property bool idle: !busy && !closing && !contextOpen && !errorOpen
    readonly property int pageSize: Math.max(1, Math.floor((list.height + Config.Clipboard.rowSpacing)
        / (Config.Clipboard.rowHeight + Config.Clipboard.rowSpacing)))
    // What the list area says when it has no rows; empty when there are rows.
    readonly property string notice: {
        switch (runner.state) {
        case "ok": return runner.items.length === 0 ? Config.Clipboard.emptyText
            : matches.length === 0 ? Config.Clipboard.noMatchText : ""
        case "unknown": return qsTr("Loading…")
        case "no-cliphist": return qsTr("cliphist is not installed.")
        case "no-wl-clipboard": return qsTr("wl-clipboard is not installed.")
        case "no-tool": return qsTr("%1 is not installed.").arg(runner.tool)
        case "store-outside-runtime": return qsTr("The history is not stored in memory only. Run make dev-seed-clipboard, then restart cliphist.")
        case "watcher-off": return qsTr("Nothing is recording the clipboard. Start it with systemctl --user start cliphist.")
        default: return qsTr("The clipboard history could not be read.")
        }
    }

    onMatchesChanged: reselect()
    onQueryChanged: { selectedLine = ""; selectedIndex = 0 }
    onSelectedEntryChanged: refreshPreview()

    // Keeps the selection on the same entry when the list changes; when that entry is gone, on
    // the same position (so deleting an entry selects the one after it).
    function reselect() {
        let index = selectedLine ? matches.findIndex(item => item.line === selectedLine) : -1
        if (index < 0) index = matches.length ? Math.min(Math.max(selectedIndex, 0), matches.length - 1) : -1
        selectedIndex = index
        selectedLine = index >= 0 ? matches[index].line : ""
        if (index >= 0) list.positionViewAtIndex(index, ListView.Contain)
    }
    function select(index) {
        if (index < 0 || index >= matches.length) return
        selectedIndex = index
        selectedLine = matches[index].line
        list.positionViewAtIndex(index, ListView.Contain)
    }
    function refreshPreview() {
        imageDelay.stop()
        runner.cancelImage()
        previewSource = ""
        previewState = ""
        if (previewOpen && selectedEntry && selectedEntry.kind === "image") {
            previewState = "loading"
            imageDelay.restart()
        }
    }
    function togglePreview() {
        if (!idle || !selectedEntry) return
        previewOpen = !previewOpen
        if (previewOpen) refreshPreview()
        else { imageDelay.stop(); runner.cancelImage() }
    }
    function forget() {
        previewOpen = false
        imageDelay.stop()
        previewSource = ""
        previewState = ""
        confirmingClear = false
        query = ""
        runner.forget()
    }
    function activate() {
        failures.close()
        context.close()
        confirmingClear = false
        previewOpen = false
        query = ""
        selectedLine = ""
        selectedIndex = 0
        runner.refresh()
        search.forceActiveFocus()
        motion.enter()
        presentLateFailure()
    }
    // A copy now closes the panel before it finishes; if it then failed, the panel was reopened
    // for the failure and shows it here.
    function presentLateFailure() {
        const failure = ClipboardState.lateFailure
        if (!shown || !failure) return
        ClipboardState.lateFailure = null
        failures.present(failure, search)
    }
    function requestClose() {
        if (failures.visible) failures.close()
        else if (context.visible) context.close()
        else if (confirmingClear) confirmingClear = false
        else motion.leave()
    }
    function moveSelection(delta) {
        if (!idle || matches.length === 0) return
        list.forceActiveFocus()
        select(Math.max(0, Math.min(matches.length - 1, selectedIndex + delta)))
    }
    function copySelection() {
        if (!idle || !selectedEntry) return
        // Closes at once; a failure that comes back later reopens the panel (ClipboardState).
        runner.copy(selectedEntry.line)
        requestClose()
    }
    // A file entry only; any other entry has no file to read, so the key does nothing.
    function copySelectionContent() {
        if (!idle || !selectedEntry || selectedEntry.kind !== "file") return
        runner.copyContent(selectedEntry.line)
        requestClose()
    }
    function removeSelection() {
        if (idle && selectedEntry) runner.remove(selectedEntry.line)
    }
    function askToClear() {
        if (idle && runner.items.length > 0) confirmingClear = true
    }
    function confirmClear() {
        confirmingClear = false
        if (idle) runner.wipe()
    }
    function refresh() { if (idle) runner.refresh() }
    function showHelp() {
        if (idle) context.show("help", root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function handleKey(event) {
        inputState.keyboardUsed()
        if (failures.visible) {
            if (event.key === Config.ErrorPanels.dismissKey) failures.close()
            else if (event.key === Config.ErrorPanels.copyKey && event.modifiers === Config.ErrorPanels.copyModifiers)
                failures.copyDiagnostic()
            event.accepted = true
            return
        }
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === Config.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        if (event.key === Config.Keyboard.cancelKey) requestClose()
        else if (confirmingClear) {
            if (event.key === Config.Keyboard.applyKey || event.key === Config.Keyboard.alternateApplyKey) confirmClear()
        }
        else if ((event.key === Config.Keyboard.applyKey || event.key === Config.Keyboard.alternateApplyKey)
                 && event.modifiers === Config.Clipboard.copyContentModifiers) copySelectionContent()
        else if (event.key === Config.Keyboard.applyKey || event.key === Config.Keyboard.alternateApplyKey) copySelection()
        else if (event.key === Config.Clipboard.previewKey && event.modifiers === Qt.NoModifier
                 && !(search.activeFocus && search.text.length > 0)) togglePreview()
        else if (event.key === Config.Clipboard.previousKey) moveSelection(-1)
        else if (event.key === Config.Clipboard.nextKey) moveSelection(1)
        else if (event.key === Config.Clipboard.previousPageKey) moveSelection(-pageSize)
        else if (event.key === Config.Clipboard.nextPageKey) moveSelection(pageSize)
        else if (event.key === Config.Clipboard.deleteKey) {
            // In the search field Delete edits the text until the cursor is at its end.
            if (search.activeFocus && search.cursorPosition < search.text.length) { event.accepted = false; return }
            if (event.modifiers === Config.Clipboard.clearModifiers) askToClear()
            else if (event.modifiers === Qt.NoModifier) removeSelection()
            else { event.accepted = false; return }
        }
        else if (event.key === Config.Clipboard.refreshKey && event.modifiers === Qt.NoModifier) refresh()
        else if (event.key === Config.Clipboard.refreshLetterKey && event.modifiers === Qt.ControlModifier) refresh()
        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { event.accepted = false; return }
        else if (!search.activeFocus && event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            search.forceActiveFocus()
            search.insert(search.cursorPosition, event.text)
        } else { event.accepted = false; return }
        event.accepted = true
    }
    Keys.onPressed: event => root.handleKey(event)
    Component.onCompleted: { if (shown) activate() }

    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Timer {
        id: imageDelay
        interval: Config.Clipboard.imageDelayMilliseconds
        onTriggered: if (root.selectedEntry && root.selectedEntry.kind === "image") root.runner.loadImage(root.selectedEntry.line)
    }
    Connections {
        target: ClipboardState
        function onLateFailureChanged() { root.presentLateFailure() }
    }
    // Only the panel that is on screen reacts; the source is shared by every screen's panel.
    Connections {
        target: root.runner
        enabled: root.shown
        function onRemoved() { root.runner.refresh() }
        function onWiped() { root.runner.refresh() }
        function onFailed(failure) {
            root.confirmingClear = false
            failures.present(failure, root.Window.window ? root.Window.window.activeFocusItem : null)
        }
        function onImageLoaded(line, mime, data) {
            if (!root.selectedEntry || root.selectedEntry.line !== line) return
            root.previewSource = "data:" + mime + ";base64," + data
            root.previewState = ""
        }
        function onImageFailed(line, code) {
            if (!root.selectedEntry || root.selectedEntry.line !== line) return
            root.previewState = code === 6 ? "tooLarge" : "failed"
        }
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        shortcutsEnabled: !failures.visible
        bindings: [
            { key: Config.Clipboard.previousKey, modifiers: Qt.NoModifier, action: qsTr("Previous entry") },
            { key: Config.Clipboard.nextKey, modifiers: Qt.NoModifier, action: qsTr("Next entry") },
            { key: Config.Clipboard.previousPageKey, modifiers: Qt.NoModifier, action: qsTr("Previous page") },
            { key: Config.Clipboard.nextPageKey, modifiers: Qt.NoModifier, action: qsTr("Next page") },
            { key: Config.Keyboard.applyKey, modifiers: Qt.NoModifier, action: qsTr("Copy the entry and close") },
            { key: Config.Keyboard.applyKey, modifiers: Config.Clipboard.copyContentModifiers, action: qsTr("Copy a copied file's content, not its address") },
            { key: Config.Clipboard.previewKey, modifiers: Qt.NoModifier, action: qsTr("Open or close the preview (right click too)") },
            { key: Config.Clipboard.deleteKey, modifiers: Qt.NoModifier, action: qsTr("Delete the entry") },
            { key: Config.Clipboard.deleteKey, modifiers: Config.Clipboard.clearModifiers, action: qsTr("Clear the history (Enter confirms)") },
            { key: Config.Clipboard.refreshKey, modifiers: Qt.NoModifier, action: qsTr("Read the history again") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then panel") }
        ]
        onRequested: kind => { if (kind === "help") root.showHelp() }
    }
    Controls.ErrorPopup {
        id: failures
        owner: root
        style: styleTokens
        inputState: root.inputState
    }

    Rectangle {
        id: card
        objectName: "clipboardCard"
        anchors.fill: parent
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        scale: motion.cardScale
        MouseArea { anchors.fill: parent; onClicked: function() {} }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.Clipboard.panelPadding
            spacing: Config.Clipboard.sectionSpacing
            Controls.ShellTextField {
                id: search
                objectName: "clipboardSearchInput"
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.inputEmphasis
                enabled: !root.busy
                Accessible.name: qsTr("Search the clipboard history")
                placeholderText: qsTr("Search the clipboard history…")
                text: root.query
                onTextChanged: root.query = text
                Keys.onPressed: event => { pointerPressed = false; root.handleKey(event) }
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: list
                KeyNavigation.backtab: list
            }
            Controls.ShellListView {
                id: list
                objectName: "clipboardList"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Config.Clipboard.rowSpacing
                model: ScriptModel { values: root.matches }
                enabled: !root.busy
                activeFocusOnTab: true
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: search
                KeyNavigation.backtab: search
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleKey(event)
                delegate: ClipboardRow {
                    required property int index
                    required property var modelData
                    width: list.width
                    entry: modelData
                    style: styleTokens
                    inputState: root.inputState
                    selected: index === root.selectedIndex
                    candidateVisible: (search.activeFocus || list.activeFocus) && root.idle
                    keyboardCandidate: list.activeFocus && root.idle
                    onChosen: {
                        root.select(index)
                        if (root.idle) list.forceActiveFocus()
                    }
                    onActivated: root.copySelection()
                    onPreviewRequested: {
                        root.select(index)
                        root.togglePreview()
                    }
                }
                Text {
                    objectName: "clipboardNotice"
                    anchors.centerIn: parent
                    width: parent.width - Config.Clipboard.panelPadding * 2
                    visible: root.notice !== ""
                    text: root.notice
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: styleTokens.textMuted
                    font.pointSize: styleTokens.bodyPointSize
                }
            }
            Rectangle {
                id: preview
                objectName: "clipboardPreview"
                Layout.fillWidth: true
                // The height, the gap above and the opacity follow one value, so the list gives
                // way smoothly and no gap is left behind when the preview is closed.
                property real reveal: root.previewReveal
                Behavior on reveal { NumberAnimation { duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing } }
                Layout.preferredHeight: Config.Clipboard.previewHeight * reveal
                Layout.topMargin: (reveal - 1) * Config.Clipboard.sectionSpacing
                opacity: reveal
                visible: reveal > 0
                color: "transparent"
                radius: styleTokens.pickerRadius
                border.width: Theme.Shape.borderWidth
                border.color: styleTokens.rule
                clip: true
                Image {
                    id: picture
                    objectName: "clipboardPicture"
                    anchors.fill: parent
                    anchors.margins: Config.Clipboard.sectionSpacing
                    visible: root.previewSource !== "" && status === Image.Ready
                    source: root.previewSource
                    cache: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: Config.Clipboard.previewHeight * 2
                    Accessible.name: qsTr("Preview of the selected picture")
                }
                Text {
                    objectName: "clipboardPreviewText"
                    anchors.fill: parent
                    anchors.margins: Config.Clipboard.sectionSpacing
                    visible: !picture.visible
                    // A message (loading, failed, too large) sits in the middle; copied text starts at the top left.
                    horizontalAlignment: root.previewState !== "" ? Text.AlignHCenter : Text.AlignLeft
                    verticalAlignment: root.previewState !== "" ? Text.AlignVCenter : Text.AlignTop
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                    color: root.previewState === "failed" || root.previewState === "tooLarge" ? styleTokens.warning : styleTokens.text
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.bodyPointSize
                    text: {
                        if (!root.selectedEntry) return ""
                        if (root.previewState === "loading") return qsTr("Loading the picture…")
                        if (root.previewState === "failed") return qsTr("The picture could not be read.")
                        if (root.previewState === "tooLarge") return qsTr("The picture is too large to preview.")
                        return root.selectedEntry.text ?? ""
                    }
                }
            }
            // Only while a clear-all waits for Enter; the keys themselves live in the Ctrl+Space popup.
            Text {
                objectName: "clipboardHint"
                Layout.fillWidth: true
                visible: root.confirmingClear
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: styleTokens.negative
                font.family: styleTokens.uiFamily
                font.pointSize: styleTokens.captionPointSize
                text: qsTr("Clear the whole history? Enter confirms, Esc cancels.")
            }
        }
    }
}

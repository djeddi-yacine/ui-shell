pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config

// The menu card: tabs (only with two or more apps waiting), the prompt, a search field, the lines
// of the request and nothing else. Enter answers with the selected line, Escape answers with no
// choice. The answer is given at once; the card is closed by the state, not by this panel.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    // Set by the window while it is mapped.
    property bool shown: false
    property string query: ""
    property int selectedIndex: -1

    readonly property var request: MenuState.visibleRequest
    // The last request shown. After an answer the card keeps showing it, as it was, until it has
    // closed: the list never blanks while the card is held open and plays its leave animation.
    property var held: null
    readonly property var content: request ?? held
    readonly property var lines: content ? content.lines : []
    // The action label as the program sent it, without the trailing space and colon of a prompt.
    readonly property string title: content ? content.prompt.replace(/[\s:]+$/, "") : ""
    // Indexes into `lines` of what the query leaves.
    readonly property var matches: MenuSearch.matches(lines, query)
    readonly property bool hasRequest: request !== null
    readonly property bool contextOpen: context.visible
    readonly property alias entryView: list
    readonly property int pageSize: Math.max(1, Math.floor((list.height + Config.Menu.rowSpacing)
        / (Config.Menu.rowHeight + Config.Menu.rowSpacing)))

    // A new request (or another tab) starts with an empty search and the first line selected.
    onRequestChanged: {
        if (request === null) return
        held = request
        query = ""
        selectedIndex = matches.length > 0 ? 0 : -1
    }
    onQueryChanged: selectedIndex = matches.length > 0 ? 0 : -1
    onMatchesChanged: {
        if (matches.length === 0) selectedIndex = -1
        else if (selectedIndex < 0 || selectedIndex >= matches.length) selectedIndex = 0
    }

    function select(index) {
        if (index < 0 || index >= matches.length) return
        selectedIndex = index
        list.positionViewAtIndex(index, ListView.Contain)
    }
    function moveSelection(delta) {
        if (matches.length === 0) return
        list.forceActiveFocus()
        select(Math.max(0, Math.min(matches.length - 1, (selectedIndex < 0 ? 0 : selectedIndex) + delta)))
    }
    // Nothing happens while no line matches: the card stays and waits for another query.
    function answer() {
        if (selectedIndex < 0 || selectedIndex >= matches.length) return
        MenuState.choose(matches[selectedIndex])
    }
    function activate() {
        context.close()
        query = ""
        selectedIndex = matches.length > 0 ? 0 : -1
        search.forceActiveFocus()
        motion.enter()
    }
    function forget() { query = ""; held = null }
    // Plays the leave animation; `closed` follows when it has finished.
    function leave() { motion.leave() }
    signal closed()
    function showHelp() {
        if (shown && request) context.show("help", root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function handleKey(event) {
        inputState.keyboardUsed()
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === Config.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        if (event.modifiers === Config.Menu.tabModifiers && event.key === Config.Menu.previousTabKey) MenuState.queue.cycle(-1)
        else if (event.modifiers === Config.Menu.tabModifiers && event.key === Config.Menu.nextTabKey) MenuState.queue.cycle(1)
        else if (event.key === Config.Keyboard.cancelKey) MenuState.cancel()
        else if (event.key === Config.Keyboard.applyKey || event.key === Config.Keyboard.alternateApplyKey) answer()
        else if (event.key === Config.Menu.previousKey) moveSelection(-1)
        else if (event.key === Config.Menu.nextKey) moveSelection(1)
        else if (event.key === Config.Menu.previousPageKey) moveSelection(-pageSize)
        else if (event.key === Config.Menu.nextPageKey) moveSelection(pageSize)
        else if (event.key === Config.Menu.firstKey && !(search.activeFocus && search.text.length > 0)) select(0)
        else if (event.key === Config.Menu.lastKey && !(search.activeFocus && search.text.length > 0)) select(matches.length - 1)
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
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        bindings: [
            { key: Config.Menu.previousKey, modifiers: Qt.NoModifier, action: qsTr("Previous line") },
            { key: Config.Menu.nextKey, modifiers: Qt.NoModifier, action: qsTr("Next line") },
            { key: Config.Menu.previousPageKey, modifiers: Qt.NoModifier, action: qsTr("Previous page") },
            { key: Config.Menu.nextPageKey, modifiers: Qt.NoModifier, action: qsTr("Next page") },
            { key: Config.Keyboard.applyKey, modifiers: Qt.NoModifier, action: qsTr("Choose the line") },
            { key: Config.Menu.previousTabKey, modifiers: Config.Menu.tabModifiers, action: qsTr("Previous app") },
            { key: Config.Menu.nextTabKey, modifiers: Config.Menu.tabModifiers, action: qsTr("Next app") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then answer with no choice") }
        ]
        onRequested: kind => { if (kind === "help") root.showHelp() }
    }

    Rectangle {
        id: card
        objectName: "menuCard"
        anchors.fill: parent
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        scale: motion.cardScale
        MouseArea { anchors.fill: parent; onClicked: function() {} }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.Menu.panelPadding
            spacing: Config.Menu.sectionSpacing
            MenuTabs {
                objectName: "menuTabs"
                Layout.fillWidth: true
                style: styleTokens
                apps: MenuState.queue.apps
                current: MenuState.queue.current
                onPicked: name => { MenuState.queue.current = name }
            }
            // The title: what is being asked, with the process that asks it on the right.
            RowLayout {
                objectName: "menuTitle"
                Layout.fillWidth: true
                visible: root.content !== null && (root.title !== "" || root.content.pid > 0)
                spacing: Config.Menu.sectionSpacing
                Text {
                    objectName: "menuPrompt"
                    Layout.fillWidth: true
                    text: root.title
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    color: styleTokens.text
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.titlePointSize
                    font.weight: Font.DemiBold
                }
                Text {
                    objectName: "menuPid"
                    visible: root.content !== null && root.content.pid > 0
                    text: root.content ? qsTr("pid %1").arg(root.content.pid) : ""
                    textFormat: Text.PlainText
                    color: styleTokens.textMuted
                    font.family: styleTokens.uiFamily
                    font.pointSize: styleTokens.captionPointSize
                }
            }
            Controls.ShellTextField {
                id: search
                objectName: "menuSearchInput"
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.inputEmphasis
                Accessible.name: qsTr("Filter the lines")
                placeholderText: qsTr("Filter…")
                text: root.query
                onTextChanged: root.query = text
                Keys.onPressed: event => { pointerPressed = false; root.handleKey(event) }
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: list
                KeyNavigation.backtab: list
            }
            Controls.ShellListView {
                id: list
                objectName: "menuList"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Config.Menu.rowSpacing
                model: ScriptModel { values: root.matches }
                activeFocusOnTab: true
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: search
                KeyNavigation.backtab: search
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleKey(event)
                delegate: MenuRow {
                    required property int index
                    required property int modelData
                    width: list.width
                    line: root.lines[modelData] ?? ""
                    style: styleTokens
                    inputState: root.inputState
                    selected: index === root.selectedIndex
                    candidateVisible: search.activeFocus || list.activeFocus
                    onChosen: {
                        root.select(index)
                        list.forceActiveFocus()
                    }
                    onActivated: root.answer()
                }
                Text {
                    objectName: "menuNotice"
                    anchors.centerIn: parent
                    width: parent.width - Config.Menu.panelPadding * 2
                    visible: root.content !== null && root.matches.length === 0
                    text: Config.Menu.noMatchText
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: styleTokens.textMuted
                    font.pointSize: styleTokens.bodyPointSize
                }
            }
        }
    }
}

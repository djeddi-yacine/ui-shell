pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config
import "../../adapters" as Adapters

FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    signal closed()
    property string query: ""
    property int selectedIndex: 0
    property string runnerExecutable: Config.AppLauncher.runnerExecutable
    property list<string> runnerArguments: Config.AppLauncher.runnerArguments
    property Item launchFocus: null
    readonly property var matches: AppCatalog.results(query)
    readonly property var selectedEntry: selectedIndex >= 0 && selectedIndex < matches.length ? matches[selectedIndex] : null
    readonly property bool busy: runner.busy
    readonly property string error: runner.error
    readonly property string runnerOutput: runner.output
    readonly property bool closing: motion.closing
    readonly property bool contextOpen: context.visible
    readonly property Controls.PanelContext contextPopup: context
    readonly property bool errorOpen: failures.visible
    readonly property Controls.ErrorPopup errorPopup: failures
    readonly property Adapters.ComponentSettings componentSettings: componentOptions
    readonly property alias applicationView: list
    readonly property int pageSize: Math.max(1, Math.floor((list.height
        + Config.AppLauncher.rowSpacing) / (Config.AppLauncher.rowHeight + Config.AppLauncher.rowSpacing)))
    onMatchesChanged: selectedIndex = matches.length ? 0 : -1
    onSelectedIndexChanged: { if (selectedIndex >= 0) list.positionViewAtIndex(selectedIndex, ListView.Contain) }
    function activate() {
        failures.close()
        context.close()
        componentOptions.refresh()
        query = ""
        selectedIndex = matches.length ? 0 : -1
        search.forceActiveFocus()
        motion.enter()
    }
    function choose(index) {
        if (!busy && !closing && !context.visible && !failures.visible && index >= 0 && index < matches.length) selectedIndex = index
    }
    function focusSelection() {
        if (!busy && !closing && !context.visible && !failures.visible)
            list.forceActiveFocus()
    }
    function moveSelection(delta) {
        if (!busy && !closing && !context.visible && !failures.visible && matches.length) {
            list.forceActiveFocus()
            choose(Math.max(0, Math.min(matches.length - 1, selectedIndex + delta)))
        }
    }
    function launchSelection() {
        if (selectedEntry && !busy && !closing && !context.visible && !failures.visible) {
            launchFocus = root.Window.window ? root.Window.window.activeFocusItem : null
            runner.launch(selectedEntry)
        }
    }
    function requestClose() {
        if (failures.visible) failures.close()
        else if (context.visible) context.close()
        else motion.leave()
    }
    function showContext(kind) {
        if (busy || closing || failures.visible) return
        if (kind === "info") {
            context.infoTitle = selectedEntry ? selectedEntry.name : qsTr("No application selected")
            context.infoDescription = selectedEntry ? selectedEntry.comment || selectedEntry.genericName : ""
            context.infoDetails = selectedEntry ? [
                { label: qsTr("Desktop ID"), value: selectedEntry.id + ".desktop" },
                { label: qsTr("Command"), value: selectedEntry.execString },
                { label: qsTr("Runner"), value: runnerExecutable }
            ] : []
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
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
        else if (event.key === Config.Keyboard.applyKey || event.key === Config.Keyboard.alternateApplyKey) launchSelection()
        else if (event.key === Config.AppLauncher.previousKey) moveSelection(-1)
        else if (event.key === Config.AppLauncher.nextKey) moveSelection(1)
        else if (event.key === Config.AppLauncher.previousPageKey) moveSelection(-pageSize)
        else if (event.key === Config.AppLauncher.nextPageKey) moveSelection(pageSize)
        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { event.accepted = false; return }
        else if (!search.activeFocus && event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            search.forceActiveFocus()
            search.insert(search.cursorPosition, event.text)
        } else { event.accepted = false; return }
        event.accepted = true
    }
    Keys.onPressed: event => root.handleKey(event)
    Component.onCompleted: { if (visible) activate() }
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Adapters.ComponentSettings {
        id: componentOptions
        component: "launcher"
        screenName: root.screenName
        onFailed: failures.present(componentOptions.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: componentOptions
        shortcutsEnabled: !failures.visible
        bindings: [
            { key: Config.AppLauncher.previousKey, modifiers: Qt.NoModifier, action: qsTr("Previous application") },
            { key: Config.AppLauncher.nextKey, modifiers: Qt.NoModifier, action: qsTr("Next application") },
            { key: Config.AppLauncher.previousPageKey, modifiers: Qt.NoModifier, action: qsTr("Previous page") },
            { key: Config.AppLauncher.nextPageKey, modifiers: Qt.NoModifier, action: qsTr("Next page") },
            { key: Config.Keyboard.applyKey, modifiers: Qt.NoModifier, action: qsTr("Launch application") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Selection information") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Config.Keyboard.settingsKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component settings") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then panel") }
        ]
        onRequested: kind => root.showContext(kind)
    }
    Controls.ErrorPopup {
        id: failures
        owner: root
        style: styleTokens
        inputState: root.inputState
    }
    Adapters.AppRunner {
        id: runner
        executable: root.runnerExecutable
        launchArguments: root.runnerArguments
        onAccepted: { root.launchFocus = null; root.requestClose() }
        onFailed: {
            const previous = root.launchFocus
            root.launchFocus = null
            failures.present(runner.failure, previous)
        }
    }
    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(Config.ContextPanels.scrimOpacity)
        MouseArea { anchors.fill: parent; onClicked: root.requestClose() }
    }
    Rectangle {
        id: card
        objectName: "appPanelCard"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.Placement.y(Config.AppLauncher.placement, parent.height, height, styleTokens.barHeight, Config.AppLauncher.outerMargin)
        width: Math.min(parent.width - Config.AppLauncher.outerMargin * 2, Config.AppLauncher.maximumWidth)
        height: Math.min(parent.height - Config.AppLauncher.outerMargin * 2,
            Config.AppLauncher.maximumHeight, panelLayout.implicitHeight + Config.AppLauncher.panelPadding * 2)
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        scale: motion.cardScale
        MouseArea { anchors.fill: parent; onClicked: function() {} }
        ColumnLayout {
            id: panelLayout
            anchors.fill: parent
            anchors.margins: Config.AppLauncher.panelPadding
            spacing: Config.AppLauncher.sectionSpacing
            Controls.ShellTextField {
                id: search
                objectName: "appSearchInput"
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.inputEmphasis
                enabled: !root.busy
                Accessible.name: qsTr("Search installed applications")
                placeholderText: qsTr("Search applications…")
                text: root.query
                onTextChanged: root.query = text
                Keys.onPressed: event => { pointerPressed = false; root.handleKey(event) }
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: list
                KeyNavigation.backtab: list
            }
            ListView {
                id: list
                objectName: "appList"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: componentOptions.visibleRows * (Config.AppLauncher.rowHeight + Config.AppLauncher.rowSpacing)
                    - Config.AppLauncher.rowSpacing
                clip: true
                spacing: Config.AppLauncher.rowSpacing
                // ScriptModel diffs the new results against the old by identity, so the view
                // animates what changed (rows slide, fade in or out) instead of being rebuilt.
                model: ScriptModel { values: root.matches }
                enabled: !root.busy
                activeFocusOnTab: true
                keyNavigationEnabled: false
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: search
                KeyNavigation.backtab: search
                // Pooled rows would jump instead of animating, so rows are not reused.
                reuseItems: false
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 } }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing }
                    NumberAnimation { property: "opacity"; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
                }
                move: Transition {
                    NumberAnimation { property: "y"; duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing }
                    NumberAnimation { property: "opacity"; to: 1; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 }
                }
                highlightMoveDuration: 0
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleKey(event)
                delegate: AppRow {
                    required property int index
                    required property var modelData
                    width: list.width
                    entry: modelData
                    style: styleTokens
                    inputState: root.inputState
                    selected: index === root.selectedIndex
                    candidateVisible: (search.activeFocus || list.activeFocus)
                        && !root.contextOpen && !root.errorOpen
                    launching: root.busy && runner.launchTarget === modelData.id + ".desktop"
                    showIcon: componentOptions.showIcons
                    keyboardCandidate: list.activeFocus && !root.contextOpen && !root.errorOpen
                    onChosen: {
                        root.choose(index)
                        root.focusSelection()
                    }
                    onActivated: root.launchSelection()
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.matches.length === 0
                    text: qsTr("No matching applications")
                    color: styleTokens.textMuted
                    font.pointSize: styleTokens.bodyPointSize
                }
            }
        }
    }
}

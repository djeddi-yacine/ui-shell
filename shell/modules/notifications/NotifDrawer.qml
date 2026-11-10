pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// The history drawer: every notification of this session, grouped by app, newest first.
FocusScope {
    id: root
    required property var style
    required property var inputState
    signal closed()

    // Notifications the stacks draw, in on-screen order; the keyboard moves over these.
    readonly property var flat: NotifCenter.visibleEntries()
    property int currentId: -1
    readonly property int currentPos: {
        const i = flat.findIndex(e => e.id === currentId)
        return i >= 0 ? i : 0
    }
    readonly property var currentEntry: flat.length > 0 ? flat[currentPos] : null
    function moveCurrent(step) {
        if (flat.length === 0) return
        currentId = flat[Math.max(0, Math.min(flat.length - 1, currentPos + step))].id
        const gi = NotifCenter.groups.findIndex(g => g.appName === currentEntry.appName)
        if (gi >= 0) list.positionViewAtIndex(gi, ListView.Contain)
    }

    // The mounted stack that holds the selected notification, or null.
    function currentStack() {
        const e = currentEntry
        if (!e) return null
        for (let i = 0; i < NotifCenter.groups.length; ++i)
            if (NotifCenter.groups[i].appName === e.appName) return list.itemAtIndex(i)
        return null
    }

    // Clear everything: the drawn stacks fade out one by one, the ones not drawn just go.
    function clearEverything() {
        // Collect first: clearing can reshuffle the list under the loop.
        const groups = NotifCenter.groups
        const stacks = groups.map((g, i) => list.itemAtIndex(i))
        for (let i = 0; i < groups.length; ++i) {
            if (stacks[i]) stacks[i].clearAll()
            else NotifCenter.clearGroup(groups[i].appName)
        }
    }

    function activate() {
        root.forceActiveFocus()
        list.forceActiveFocus()
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.closed()
    }
    // Drawer-local keys, live only while the drawer is open: no global chord is taken.
    Shortcut { sequence: "D"; context: Qt.WindowShortcut; onActivated: NotifCenter.setDnd(!NotifCenter.dnd) }
    Shortcut { sequence: "Shift+Delete"; context: Qt.WindowShortcut
        onActivated: { const stack = root.currentStack(); if (stack) stack.clearAll() } }
    Shortcut { sequence: "R"; context: Qt.WindowShortcut; onActivated: { if (root.currentEntry) NotifCenter.toggleRead(root.currentEntry.id) } }
    Shortcut { sequence: "Shift+R"; context: Qt.WindowShortcut; onActivated: NotifCenter.markAllRead() }
    Shortcut { sequence: "Ctrl+Shift+Delete"; context: Qt.WindowShortcut; onActivated: root.clearEverything() }
    Repeater {
        model: 9
        Item {
            id: action
            required property int index
            Shortcut {
                sequence: String(action.index + 1)
                context: Qt.WindowShortcut
                onActivated: {
                    const e = root.currentEntry
                    if (e && e.actions.length > action.index) NotifCenter.invoke(e.id, e.actions[action.index].identifier)
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.style.surface
        border.color: root.style.outline
        radius: root.style.surfaceRadius
    }

    ColumnLayout {
        anchors { fill: parent; margins: root.style.spacingTight * 2 }
        spacing: root.style.spacingTight

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                color: root.style.text
                font.bold: true
                text: qsTr("Notifications") + (NotifCenter.dnd ? qsTr("  ·  do not disturb") : "")
                       + (NotifCenter.suppressed > 0 ? qsTr("  ·  %1 hidden by rules").arg(NotifCenter.suppressed) : "")
                       + (NotifCenter.unread > 0 ? "  (" + NotifCenter.unread + ")" : "")
            }
            Repeater {
                model: [
                    { glyph: "do-not-disturb", label: qsTr("Do not disturb"), on: NotifCenter.dnd, run: () => NotifCenter.setDnd(!NotifCenter.dnd) },
                    { glyph: "clear-all", label: qsTr("Clear all"), on: false, run: () => root.clearEverything() },
                    { glyph: "check", label: qsTr("Mark all as read"), on: false, run: () => NotifCenter.markAllRead() }
                ]
                Controls.ShellIconButton {
                    required property var modelData
                    Layout.preferredWidth: Config.Notifications.iconButtonSize
                    Layout.preferredHeight: Config.Notifications.iconButtonSize
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    glyph: modelData.glyph
                    label: modelData.label
                    selected: modelData.on
                    iconSize: Config.Notifications.iconGlyphSize
                    onClicked: modelData.run()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: NotifCenter.rules !== null && NotifCenter.rules.error !== ""
            color: root.style.negative
            wrapMode: Text.Wrap
            text: NotifCenter.rules ? NotifCenter.rules.error : ""
        }

        Text {
            Layout.fillWidth: true
            visible: NotifCenter.entries.length === 0
            horizontalAlignment: Text.AlignHCenter
            color: root.style.textMuted
            text: qsTr("No notifications")
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            spacing: 0
            // Rows keep their identity so a removed stack fades out instead of jumping.
            reuseItems: false
            model: ScriptModel {
                values: NotifCenter.groups
                objectProp: "appName"
            }
            // The list only moves rows. A stack fades itself in (NotifStack.entrance), so no
            // reshuffle can leave one part-way faded; a removed row fades out to nothing.
            displaced: Transition {
                NumberAnimation { property: "y"; duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing }
            }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.Motion.active ? Theme.Motion.listFadeDuration : 0 } }
            delegate: NotifStack {
                required property var modelData
                width: list.width
                group: modelData
                style: root.style
                inputState: root.inputState
                currentId: root.currentEntry ? root.currentEntry.id : -1
                onSelected: id => root.currentId = id
            }
            Keys.onUpPressed: root.moveCurrent(-1)
            Keys.onDownPressed: root.moveCurrent(1)
            Keys.onSpacePressed: { if (root.currentEntry) NotifCenter.toggleGroup(root.currentEntry.appName) }
            Keys.onReturnPressed: {
                const e = root.currentEntry
                if (e && e.actions.length > 0) NotifCenter.invoke(e.id, e.actions[0].identifier)
            }
            Keys.onDeletePressed: {
                const e = root.currentEntry
                if (!e) return
                const stack = root.currentStack()
                if (stack) stack.dismiss(e.id)
                else NotifCenter.clear(e.id)
            }
        }
    }
}

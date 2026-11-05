import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme
import "../shell/config" as Config

Item {
    id: root
    width: 800
    height: 600
    Controls.InputState { id: input; pointerActive: false }
    Component {
        id: component
        Controls.ContextPopup {
            id: popupControl
            width: 400
            height: 200
            owner: root
            style: Theme.Style
            inputState: input
            contentItem: FocusScope {
                focus: true
                Keys.onPressed: event => {
                    event.accepted = popupControl.handleShortcut(event) || event.key !== Qt.Key_Escape
                }
            }
            onRequested: kind => show(kind, previous)
        }
    }
    Component {
        id: actionComponent
        Controls.ContextPopup {
            id: popupControl
            width: 400
            height: 200
            owner: root
            style: Theme.Style
            inputState: input
            shortcutsEnabled: false
            primaryAction: confirm
            property int commits: 0
            contentItem: FocusScope {
                focus: true
                Controls.ShellTextField {
                    objectName: "popupDraft"
                    width: 320
                    height: 40
                    style: Theme.Style
                    inputState: input
                    emphasis: Theme.Interaction.inputEmphasis
                }
                Controls.ShellButton {
                    id: confirm
                    y: 60
                    width: 100
                    height: 40
                    style: Theme.Style
                    inputState: input
                    emphasis: Theme.Interaction.primaryActionEmphasis
                    text: qsTr("Save")
                    onClicked: popupControl.commits += 1
                }
            }
        }
    }
    Controls.ShellButton {
        id: previous
        x: 20
        y: 20
        width: 100
        height: 40
        style: Theme.Style
        inputState: input
        emphasis: Theme.Interaction.buttonEmphasis
        text: qsTr("Target")
    }
    TestCase {
        name: "ContextPopup"
        when: windowShown
        function init() { root.Window.window.requestActivate(); tryCompare(root.Window.window, "active", true) }
        function test_escapeRestoresFocus() {
            const popup = createTemporaryObject(component, root)
            verify(!!popup, "Component exists")
            previous.forceActiveFocus()
            tryCompare(previous, "activeFocus", true)
            popup.show("info", previous)
            tryCompare(popup, "opened", true)
            compare(popup.kind, "info")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            tryCompare(previous, "activeFocus", true)
        }
        function test_outsideDismissesWithoutClickThrough() {
            const popup = createTemporaryObject(component, root)
            verify(!!popup, "Component exists")
            previous.forceActiveFocus()
            popup.show("help", previous)
            tryCompare(popup, "opened", true)
            mouseClick(root, 10, 10)
            tryCompare(popup, "visible", false)
            tryCompare(previous, "activeFocus", true)
        }
        function test_shortcutsReplaceTopmost() {
            const popup = createTemporaryObject(component, root)
            verify(!!popup, "Component exists")
            previous.forceActiveFocus()
            keyClick(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
            tryCompare(popup, "opened", true)
            compare(popup.kind, "info")
            keyClick(Config.Keyboard.helpKey, Config.Keyboard.contextModifiers)
            tryCompare(popup, "kind", "help")
            compare(popup.returnFocus, previous)
            keyClick(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
            tryCompare(popup, "kind", "settings")
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            tryCompare(previous, "activeFocus", true)
        }
        function test_parentHiddenClosesPopup() {
            const popup = createTemporaryObject(component, root)
            verify(!!popup, "Component exists")
            popup.show("info", previous)
            tryCompare(popup, "opened", true)
            root.visible = false
            tryCompare(popup, "visible", false)
            root.visible = true
            compare(root.visible, true)
        }
        function test_primaryShortcutFromField_data() {
            return Config.Keyboard.popupActionKeys.map(key => ({
                tag: Config.Keyboard.shortcut(key, Config.Keyboard.popupActionModifiers), key: key
            }))
        }
        function test_primaryShortcutFromField(data) {
            const popup = createTemporaryObject(actionComponent, root)
            verify(!!popup, "Component exists")
            popup.show("settings", previous)
            tryCompare(popup, "opened", true)
            const field = findChild(popup.contentItem, "popupDraft")
            verify(!!field, "Object exists")
            field.forceActiveFocus()
            tryCompare(field, "activeFocus", true)
            tryCompare(popup, "activeFocus", true)
            keyClick(data.key, Config.Keyboard.popupActionModifiers)
            tryCompare(popup, "commits", 1)
        }
        function test_disabledPrimaryDoesNotRun() {
            const popup = createTemporaryObject(actionComponent, root)
            verify(!!popup, "Component exists")
            popup.primaryAction.enabled = false
            popup.show("settings", previous)
            tryCompare(popup, "opened", true)
            keyClick(Config.Keyboard.applyKey, Config.Keyboard.popupActionModifiers)
            tryCompare(popup, "commits", 0)
        }
        function test_nestedPrimaryDoesNotReachParent() {
            const outer = createTemporaryObject(actionComponent, root)
            verify(!!outer, "Component exists")
            outer.show("settings", previous)
            tryCompare(outer, "opened", true)
            const field = findChild(outer.contentItem, "popupDraft")
            verify(!!field, "Object exists")
            field.forceActiveFocus()
            const inner = createTemporaryObject(actionComponent, root, { owner: outer.contentItem })
            verify(!!inner, "Component exists")
            inner.show("color", field)
            tryCompare(inner, "opened", true)
            tryCompare(outer, "activeFocus", false)
            keyClick(Config.Keyboard.applyKey, Config.Keyboard.popupActionModifiers)
            tryCompare(inner, "commits", 1)
            compare(outer.commits, 0)
            inner.close()
            tryCompare(inner, "visible", false)
            tryCompare(field, "activeFocus", true)
            keyClick(Config.Keyboard.applyKey, Config.Keyboard.popupActionModifiers)
            tryCompare(outer, "commits", 1)
            compare(inner.commits, 1)
            inner.destroy()
        }
        function test_closedPrimaryDoesNotRun() {
            const popup = createTemporaryObject(actionComponent, root)
            verify(!!popup, "Component exists")
            previous.forceActiveFocus()
            keyClick(Config.Keyboard.applyKey, Config.Keyboard.popupActionModifiers)
            tryCompare(popup, "commits", 0)
        }
    }
}

import QtQuick
import QtQuick.Window
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

// The exit rule: a view leaves at once; unsaved work needs a second Esc, which
// confirms; "Keep editing" and a click outside keep the work.
Item {
    id: root
    width: 800
    height: 600
    Controls.InputState { id: input; pointerActive: false }
    Component {
        id: dialogComponent
        Controls.ExitDialog { owner: root; style: Theme.Style; inputState: input }
    }
    TestCase {
        name: "ExitDialog"
        when: windowShown
        function init() { root.Window.window.requestActivate(); tryCompare(root.Window.window, "active", true) }

        function make() {
            const dialog = createTemporaryObject(dialogComponent, root)
            verify(!!dialog)
            return { dialog: dialog, spy: createTemporaryObject(spyComponent, root, { target: dialog, signalName: "confirmed" }) }
        }
        Component { id: spyComponent; SignalSpy {} }

        function test_viewLeavesAtOnce() {
            const t = make()
            compare(t.dialog.request(false, null), false)
            compare(t.spy.count, 1)
            compare(t.dialog.visible, false)
        }
        function test_unsavedAsksFirstThenEscConfirms() {
            const t = make()
            compare(t.dialog.request(true, null), true)
            tryCompare(t.dialog, "opened", true)
            compare(t.spy.count, 0, "a first Esc must not leave")
            keyClick(Qt.Key_Escape)
            tryCompare(t.spy, "count", 1)
            tryCompare(t.dialog, "visible", false)
        }
        function test_keepEditingLeavesNothing() {
            const t = make()
            t.dialog.request(true, null)
            tryCompare(t.dialog, "opened", true)
            keyClick(Qt.Key_Return)   // the default button is Keep editing
            tryCompare(t.dialog, "visible", false)
            compare(t.spy.count, 0)
        }
    }
}

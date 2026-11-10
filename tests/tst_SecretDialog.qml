import QtQuick
import QtQuick.Window
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

// The field shows nothing about the secret: not the characters, not the length, not a reaction
// to a key. Typing a known canary must leave every visible string and the field's size exactly
// as they were.
Item {
    id: root
    width: 800
    height: 600
    Component {
        id: dialogComponent
        Controls.SecretDialog { style: Theme.Style; guardMs: 60; message: "Authentication is required"; accounts: [{ id: "a", label: "root" }] }
    }
    Component { id: spyComponent; SignalSpy {} }
    TestCase {
        name: "SecretDialog"
        when: windowShown
        function init() { root.Window.window.requestActivate(); tryCompare(root.Window.window, "active", true) }

        function make(props) {
            const d = createTemporaryObject(dialogComponent, root, props || {})
            verify(!!d)
            d.forceActiveFocus()
            tryCompare(d, "guarded", false)
            return d
        }
        function spy(d, name) { return createTemporaryObject(spyComponent, root, { target: d, signalName: name }) }
        function texts(item, out) {
            if (item.text !== undefined && item.visible && item.opacity > 0) out.push(String(item.text))
            for (let i = 0; i < item.children.length; i++) texts(item.children[i], out)
            return out
        }
        function everything(d) { return texts(d, []).join("|") }

        function test_nothingOnScreenChangesWhileTyping() {
            const d = make()
            const field = findChild(d, "secretField")
            const before = everything(d)
            const width = field.width, height = field.height, childCount = field.children.length
            const canary = "Zq9#kW2m"
            for (const c of canary) keyClick(c)
            compare(everything(d), before)
            verify(!everything(d).includes("Z"))
            verify(!everything(d).includes("*"))
            verify(!everything(d).includes("•"))
            compare(field.width, width)
            compare(field.height, height)
            compare(field.children.length, childCount)
        }
        function test_enterSubmitsTheTypedSecretThenClearsIt() {
            const d = make()
            const submitted = spy(d, "submitted")
            for (const c of "pa ss") keyClick(c)
            keyClick(Qt.Key_Return)
            compare(submitted.count, 1)
            compare(submitted.signalArguments[0][0], "pa ss")
            compare(d.buffer, "")
        }
        function test_enterOnAnEmptyFieldIsIgnored() {
            const d = make()
            const submitted = spy(d, "submitted")
            keyClick(Qt.Key_Return)
            compare(submitted.count, 0)
        }
        function test_backspaceEmptiesTheWholeField() {
            const d = make()
            const submitted = spy(d, "submitted")
            for (const c of "abc") keyClick(c)
            keyClick(Qt.Key_Backspace)
            keyClick(Qt.Key_Return)
            compare(submitted.count, 0)
        }
        function test_keysInsideTheGuardAreDropped() {
            const d = createTemporaryObject(dialogComponent, root, { guardMs: 10000 })
            d.forceActiveFocus()
            const submitted = spy(d, "submitted")
            keyClick("x")
            keyClick(Qt.Key_Return)
            compare(d.buffer, "")
            compare(submitted.count, 0)
        }
        function test_escCancelsInEveryState() {
            const d = make()
            const cancelled = spy(d, "cancelled")
            keyClick(Qt.Key_Escape)
            compare(cancelled.count, 1)
            d.checking = true
            keyClick(Qt.Key_Escape)
            compare(cancelled.count, 2)
        }
        function test_keysAreDroppedWhileChecking() {
            const d = make()
            d.checking = true
            keyClick("a")
            compare(d.buffer, "")
        }
        function test_controlChordsAreIgnored() {
            const d = make()
            keyClick("v", Qt.ControlModifier)
            compare(d.buffer, "")
        }
        function test_anyKeyAfterAFailureIsReported() {
            const d = make()
            const after = spy(d, "keyAfterFailure")
            d.failed = true
            keyClick("a")
            compare(after.count, 1)
            compare(findChild(d, "lockIcon").name, "lock-cross")
        }
        function test_acceptedShowsTheCheckedLockAndDropsKeys() {
            const d = make()
            const icon = findChild(d, "lockIcon")
            compare(icon.name, "lock")
            d.succeeded = true
            compare(icon.name, "lock-checked")
            const submitted = spy(d, "submitted")
            keyClick("a")
            keyClick(Qt.Key_Return)
            compare(submitted.count, 0)
        }
        function test_visiblePromptShowsWhatIsTyped() {
            const d = make({ visibleEcho: true })
            for (const c of "bob") keyClick(c)
            verify(everything(d).includes("bob"))
            keyClick(Qt.Key_Backspace)
            verify(everything(d).includes("bo"))
        }
        function test_arrowsChooseAnAccountOnlyWhenThereAreSeveralAndTheFieldIsEmpty() {
            const d = make({ accounts: [{ id: "a", label: "ann" }, { id: "b", label: "bob" }] })
            const chosen = spy(d, "accountChosen")
            keyClick(Qt.Key_Right)
            compare(chosen.signalArguments[0][0], 1)
            keyClick("x")
            keyClick(Qt.Key_Right)
            compare(chosen.count, 1)
        }
        function test_singleAccountHasNoChoice() {
            const d = make()
            const chosen = spy(d, "accountChosen")
            keyClick(Qt.Key_Right)
            compare(chosen.count, 0)
        }
    }
}

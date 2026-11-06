import QtQuick
import QtTest
import "auth" as Fake
import "../shell/tests/auth" as Adapters

// The polkit logic against a fake flow: phases, the single try, the failure that stays until a
// key, polkit's own cancel, several rounds and a second request that waits.
Item {
    id: root
    Component { id: flowComponent; Fake.FakeFlow {} }
    Component { id: sourceComponent; Fake.FakeSource {} }
    Component { id: authComponent; Adapters.PolkitAuth {} }
    TestCase {
        name: "PolkitAuth"

        function make() {
            const source = createTemporaryObject(sourceComponent, root)
            const auth = createTemporaryObject(authComponent, root, { source: source, successMs: 20 })
            return { source: source, auth: auth }
        }
        function flow(props) { return createTemporaryObject(flowComponent, root, props || {}) }

        function test_idleUntilARequestArrives() {
            const t = make()
            compare(t.auth.phase, "idle")
            compare(t.auth.active, false)
            const f = flow({ message: "Install a package" })
            t.source.flow = f
            compare(t.auth.phase, "prompt")
            compare(t.auth.displayed.message, "Install a package")
            compare(t.auth.displayed.accounts[0].label, "root")
        }
        function test_cannotAnswerUntilPolkitAsks() {
            const t = make()
            const f = flow()
            t.source.flow = f
            compare(t.auth.canAnswer, false)
            t.auth.submit("x")
            compare(f.submitted.length, 0)
            f.isResponseRequired = true
            compare(t.auth.canAnswer, true)
            t.auth.submit("secret")
            compare(f.submitted[0], "secret")
            compare(t.auth.phase, "checking")
        }
        function test_successShowsAcceptedThenCloses() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            t.auth.submit("secret")
            // As in the real module: success and completion are set together, then the signal fires.
            f.isSuccessful = true
            f.isCompleted = true
            f.authenticationSucceeded()
            compare(t.auth.phase, "succeeded")
            compare(t.auth.active, true)
            tryCompare(t.auth, "phase", "idle")
        }
        function test_nextRequestWaitsBehindTheAcceptedState() {
            const t = make()
            const first = flow({ isResponseRequired: true, message: "first" })
            t.source.flow = first
            t.auth.submit("secret")
            first.isSuccessful = true
            first.isCompleted = true
            first.authenticationSucceeded()
            t.source.flow = flow({ isResponseRequired: true, message: "second" })
            compare(t.auth.displayed.message, "first")
            tryCompare(t.auth, "phase", "prompt")
            compare(t.auth.displayed.message, "second")
        }
        function test_wrongPasswordEndsTheRequestAndStaysUntilAKey() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            t.auth.submit("wrong")
            f.authenticationFailed()
            compare(t.auth.phase, "failed")
            tryCompare(f, "cancels", 1)
            // The fresh session polkit makes must not bring the prompt back.
            f.isResponseRequired = true
            compare(t.auth.phase, "failed")
            compare(t.auth.displayed.message, "Authentication is required")
            t.auth.dismissFailure()
            compare(t.auth.phase, "idle")
        }
        function test_secondRequestWaitsBehindTheFailureMessage() {
            const t = make()
            const first = flow({ isResponseRequired: true, message: "first" })
            t.source.flow = first
            t.auth.submit("wrong")
            first.authenticationFailed()
            tryCompare(first, "cancels", 1)
            t.source.flow = flow({ isResponseRequired: true, message: "second" })
            compare(t.auth.displayed.message, "first")
            t.auth.dismissFailure()
            compare(t.auth.phase, "prompt")
            compare(t.auth.displayed.message, "second")
        }
        function test_polkitCancelClosesTheDialog() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            f.isCompleted = true
            f.authenticationRequestCancelled()
            compare(t.auth.phase, "idle")
        }
        function test_escCancelsInPolkitNotOnlyOnScreen() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            t.auth.cancel()
            compare(f.cancels, 1)
            compare(t.auth.phase, "idle")
        }
        function test_escWhileCheckingStillCancels() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            t.auth.submit("x")
            t.auth.cancel()
            compare(f.cancels, 1)
            compare(t.auth.phase, "idle")
        }
        function test_secondRoundShowsTheNewPrompt() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            t.auth.submit("secret")
            compare(t.auth.phase, "checking")
            f.inputPrompt = "Code:"
            f.isResponseRequired = true
            compare(t.auth.phase, "prompt")
            compare(t.auth.displayed.prompt, "Code:")
        }
        function test_visibleInputIsOnlyForThatPrompt() {
            const t = make()
            const f = flow({ isResponseRequired: true, responseVisible: true, inputPrompt: "Name:" })
            t.source.flow = f
            compare(t.auth.displayed.visibleEcho, true)
            t.auth.submit("n")
            f.responseVisible = false
            f.inputPrompt = "Password:"
            f.isResponseRequired = true
            compare(t.auth.displayed.visibleEcho, false)
        }
        function test_infoLineIsShown() {
            const t = make()
            const f = flow({ isResponseRequired: true })
            t.source.flow = f
            f.supplementaryMessage = "Touch the key"
            compare(t.auth.displayed.info, "Touch the key")
        }
        function test_noAccountsIsRefused() {
            const t = make()
            t.source.flow = flow({ identities: [] })
            compare(t.auth.phase, "refused")
            t.auth.dismissFailure()
            compare(t.auth.phase, "idle")
        }
        function test_selectingAnAccountChangesTheIdentity() {
            const t = make()
            const f = flow({ isResponseRequired: true, identities: [{ id: "a", displayName: "ann", string: "a" }, { id: "b", displayName: "bob", string: "b" }] })
            t.source.flow = f
            t.auth.selectAccount(1)
            compare(f.selectedIdentity.id, "b")
            compare(t.auth.displayed.selectedIndex, 1)
        }
    }
}

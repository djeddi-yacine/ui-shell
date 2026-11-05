import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme
import "../shell/config" as Config

Item {
    id: root
    width: 800
    height: 600
    property int backgroundClicks: 0

    Controls.InputState { id: input; pointerActive: false }

    MouseArea {
        anchors.fill: parent
        onClicked: root.backgroundClicks += 1
    }

    Controls.ShellButton {
        id: firstFocus
        x: 20
        y: 20
        width: 100
        height: 40
        style: Theme.Style
        inputState: input
        emphasis: Theme.Interaction.buttonEmphasis
        text: qsTr("First focus")
    }

    Controls.ShellButton {
        id: secondFocus
        x: 140
        y: 20
        width: 100
        height: 40
        style: Theme.Style
        inputState: input
        emphasis: Theme.Interaction.buttonEmphasis
        text: qsTr("Second focus")
    }

    Component {
        id: errorPopupComponent
        Controls.ErrorPopup {
            owner: root
            style: Theme.Style
            inputState: input
        }
    }

    Component {
        id: lowerPopupComponent
        Controls.ContextPopup {
            owner: root
            style: Theme.Style
            inputState: input
            width: 400
            height: 200
            contentItem: FocusScope {
                focus: true
                Controls.ShellButton {
                    id: editor
                    objectName: "lowerPopupEditor"
                    anchors.centerIn: parent
                    width: 140
                    height: 40
                    style: Theme.Style
                    inputState: input
                    emphasis: Theme.Interaction.buttonEmphasis
                    text: qsTr("Editor")
                }
            }
        }
    }

    function failure(source, sequence, details) {
        return {
            source: source,
            sequence: sequence,
            title: qsTr("Unable to complete action"),
            message: qsTr("The requested action failed."),
            operation: qsTr("write configuration"),
            target: qsTr("launcher/output-1"),
            details: details === undefined ? qsTr("Permission denied") : details
        }
    }

    SignalSpy {
        id: copiedDiagnosticSpy
        signalName: "copiedDiagnostic"
    }

    SignalSpy {
        id: requestedSpy
        signalName: "requested"
    }

    TestCase {
        name: "ErrorPopup"
        when: windowShown

        function init() {
            root.Window.window.requestActivate()
            tryCompare(root.Window.window, "active", true)
        }

        function test_escapeRestoresFocus() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            firstFocus.forceActiveFocus()
            tryCompare(firstFocus, "activeFocus", true)
            compare(popup.present(failure("launcher", 1), firstFocus), true)
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            tryCompare(firstFocus, "activeFocus", true)
        }

        function test_outsideClickDismissesWithoutClickThrough() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            firstFocus.forceActiveFocus()
            popup.present(failure("launcher", 1), firstFocus)
            tryCompare(popup, "opened", true)
            root.backgroundClicks = 0
            mouseClick(root, 5, 5)
            tryCompare(popup, "visible", false)
            tryCompare(root, "backgroundClicks", 0)
            tryCompare(firstFocus, "activeFocus", true)
        }

        function test_errorAboveContextPopupRestoresEditor() {
            const lower = createTemporaryObject(lowerPopupComponent, root)
            verify(!!lower, "Component exists")
            const editor = findChild(lower, "lowerPopupEditor")
            verify(!!editor, "Object exists")
            lower.show("settings", editor)
            tryCompare(lower, "opened", true)
            editor.forceActiveFocus()
            tryCompare(editor, "activeFocus", true)

            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            popup.present(failure("settings", 1), editor)
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            tryCompare(lower, "visible", true)
            tryCompare(editor, "activeFocus", true)
        }

        function test_deduplicatesDismissedFailureAndAcceptsNewSequence() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            compare(popup.present(failure("runner", 4), firstFocus), true)
            tryCompare(popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            compare(popup.present(failure("runner", 4), secondFocus), false)
            compare(popup.visible, false)
            compare(popup.present(failure("runner", 5), secondFocus), true)
            tryCompare(popup, "opened", true)
            compare(popup.failure.sequence, 5)
        }

        function test_failurePayloadIsCopiedAndSequencesArePerSource() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            const original = failure("adapter-a", 3, qsTr("Original details"))
            compare(popup.present(original, firstFocus), true)
            original.title = qsTr("Mutated title")
            original.details = qsTr("Mutated details")
            compare(popup.failure.title, qsTr("Unable to complete action"))
            compare(popup.failure.details, qsTr("Original details"))
            compare(popup.present(failure("adapter-b", 3), secondFocus), true)
            compare(popup.failure.source, "adapter-b")
        }

        function test_replacingOpenFailureKeepsOriginalReturnFocus() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            firstFocus.forceActiveFocus()
            popup.present(failure("settings", 1), firstFocus)
            tryCompare(popup, "opened", true)
            compare(popup.present(failure("settings", 2), secondFocus), true)
            compare(popup.returnFocus, firstFocus)
            keyClick(Qt.Key_Escape)
            tryCompare(popup, "visible", false)
            tryCompare(firstFocus, "activeFocus", true)
        }

        function test_diagnosticPreservesPlainTextAndLongDetailsInBoundedScroll() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            const special = qsTr("<tag>& plain text\n\"quoted\" ") + "x".repeat(6000)
            popup.present(failure("settings", 1, special), firstFocus)
            tryCompare(popup, "opened", true)
            const diagnostics = findChild(popup, "errorDiagnostics")
            verify(!!diagnostics, "Object exists")
            const scroll = findChild(popup, "errorDetailsScroll")
            verify(!!scroll, "Object exists")
            compare(diagnostics.text, qsTr("Operation: write configuration\n\nTarget: launcher/output-1\n\n") + special)
            compare(diagnostics.textFormat, TextEdit.PlainText)
            compare(diagnostics.selectByMouse, true)
            diagnostics.selectAll()
            compare(diagnostics.selectedText, diagnostics.text)
            verify(scroll.height <= Config.ErrorPanels.maximumDetailsHeight)
            verify(scroll.contentHeight > scroll.height)
            compare(popup.diagnostic,
                qsTr("Unable to complete action\n\nThe requested action failed.\n\n")
                    + diagnostics.text)
        }

        function test_diagnosticsEditorUsesTheThemedContextMenu() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            tryVerify(() => !!popup.diagnosticsControl)
            // Qt's default menu is a white popup; the editor must own the themed one.
            const menu = popup.diagnosticsControl.ContextMenu.menu
            verify(!!menu, "The diagnostics editor has a context menu")
            compare(String(menu.palette.window), String(Theme.Style.controls.surface))
            compare(String(menu.palette.windowText), String(Theme.Style.controls.text))
        }
        function test_copyCallbackRunsOnlyWhenCopyIsActivated() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            const copyButton = findChild(popup, "errorCopy")
            verify(!!copyButton, "Object exists")
            copiedDiagnosticSpy.target = popup
            copiedDiagnosticSpy.clear()
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            compare(popup.copied, false)
            compare(copiedDiagnosticSpy.count, 0)
            mouseClick(copyButton)
            tryCompare(popup, "copied", true)
            tryCompare(copiedDiagnosticSpy, "count", 1)
        }

        function test_focusedActionsActivateOnKeyRelease_data() {
            return [
                { tag: "copy-return", action: "errorCopy", key: Qt.Key_Return, modifiers: Qt.NoModifier },
                { tag: "copy-keypad-enter", action: "errorCopy", key: Qt.Key_Enter, modifiers: Qt.KeypadModifier },
                { tag: "copy-space", action: "errorCopy", key: Qt.Key_Space, modifiers: Qt.NoModifier },
                { tag: "dismiss-return", action: "errorDismiss", key: Qt.Key_Return, modifiers: Qt.NoModifier },
                { tag: "dismiss-keypad-enter", action: "errorDismiss", key: Qt.Key_Enter, modifiers: Qt.KeypadModifier },
                { tag: "dismiss-space", action: "errorDismiss", key: Qt.Key_Space, modifiers: Qt.NoModifier }
            ]
        }

        function test_configuredCtrlEnterDismissesPrimaryAction_data() {
            return Config.Keyboard.popupActionKeys.map(function(key) {
                return { tag: Config.Keyboard.shortcut(key, Config.Keyboard.popupActionModifiers), key: key }
            })
        }

        function test_configuredCtrlEnterDismissesPrimaryAction(data) {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            copiedDiagnosticSpy.target = popup
            copiedDiagnosticSpy.clear()
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            tryCompare(popup, "activeFocus", true)
            keyClick(data.key, Config.Keyboard.popupActionModifiers)
            tryCompare(popup, "visible", false)
            compare(copiedDiagnosticSpy.count, 0)
        }

        function test_focusedActionsActivateOnKeyRelease(data) {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            copiedDiagnosticSpy.target = popup
            copiedDiagnosticSpy.clear()
            firstFocus.forceActiveFocus()
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            const button = findChild(popup, data.action)
            verify(!!button, "Object exists")
            button.forceActiveFocus(Qt.TabFocusReason)
            tryCompare(button, "activeFocus", true)
            keyPress(data.key, data.modifiers)
            compare(popup.visible, true)
            compare(copiedDiagnosticSpy.count, 0)
            keyRelease(data.key, data.modifiers)
            if (data.action === "errorCopy") {
                tryCompare(copiedDiagnosticSpy, "count", 1)
                compare(popup.copied, true)
                compare(popup.visible, true)
            } else {
                tryCompare(popup, "visible", false)
                tryCompare(firstFocus, "activeFocus", true)
                compare(copiedDiagnosticSpy.count, 0)
            }
        }

        function test_initialFocusAndTabOrder() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            const dismissButton = findChild(popup, "errorDismiss")
            verify(!!dismissButton, "Object exists")
            const diagnostics = findChild(popup, "errorDiagnostics")
            verify(!!diagnostics, "Object exists")
            const copyButton = findChild(popup, "errorCopy")
            verify(!!copyButton, "Object exists")
            tryCompare(dismissButton, "activeFocus", true)
            compare(copyButton.activeFocus, false)
            compare(diagnostics.activeFocus, false)
            keyClick(Qt.Key_Tab)
            tryCompare(copyButton, "activeFocus", true)
            compare(dismissButton.activeFocus, false)
            compare(diagnostics.activeFocus, false)
            keyClick(Qt.Key_Tab)
            tryCompare(dismissButton, "activeFocus", true)
            compare(copyButton.activeFocus, false)
            compare(diagnostics.activeFocus, false)
            keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
            tryCompare(copyButton, "activeFocus", true)
            compare(dismissButton.activeFocus, false)
            compare(diagnostics.activeFocus, false)
            keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
            tryCompare(dismissButton, "activeFocus", true)
            compare(copyButton.activeFocus, false)
            compare(diagnostics.activeFocus, false)
        }

        function test_tabLeavesPointerFocusedDiagnostics() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            const diagnostics = findChild(popup, "errorDiagnostics")
            const copyButton = findChild(popup, "errorCopy")
            const dismissButton = findChild(popup, "errorDismiss")
            verify(!!diagnostics, "Object exists")
            verify(!!copyButton, "Object exists")
            verify(!!dismissButton, "Object exists")

            mouseClick(diagnostics, 20, 20)
            tryCompare(diagnostics, "activeFocus", true)
            keyClick(Qt.Key_Tab)
            tryCompare(copyButton, "activeFocus", true)
            tryCompare(diagnostics, "activeFocus", false)
            compare(dismissButton.activeFocus, false)
        }

        function test_tabLeavesExplicitlyFocusedDiagnostics() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            const diagnostics = findChild(popup, "errorDiagnostics")
            const copyButton = findChild(popup, "errorCopy")
            verify(!!diagnostics, "Object exists")
            verify(!!copyButton, "Object exists")

            diagnostics.forceActiveFocus()
            tryCompare(diagnostics, "activeFocus", true)
            keyClick(Qt.Key_Tab)
            tryCompare(copyButton, "activeFocus", true)
            tryCompare(diagnostics, "activeFocus", false)
        }

        function test_keyboardCopyFromDiagnostics() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            copiedDiagnosticSpy.target = popup
            copiedDiagnosticSpy.clear()
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            const diagnostics = findChild(popup, "errorDiagnostics")
            verify(!!diagnostics, "Object exists")
            diagnostics.forceActiveFocus()
            tryCompare(diagnostics, "activeFocus", true)
            keyClick(Config.ErrorPanels.copyKey, Config.ErrorPanels.copyModifiers)
            tryCompare(copiedDiagnosticSpy, "count", 1)
            compare(popup.copied, true)
            compare(popup.visible, true)
        }

        function test_contextShortcutsDoNotRequestAnotherPanel() {
            const popup = createTemporaryObject(errorPopupComponent, root)
            verify(!!popup, "Component exists")
            requestedSpy.target = popup
            requestedSpy.clear()
            popup.present(failure("runner", 1), firstFocus)
            tryCompare(popup, "opened", true)
            keyClick(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
            keyClick(Config.Keyboard.helpKey, Config.Keyboard.contextModifiers)
            keyClick(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
            compare(requestedSpy.count, 0)
            tryCompare(popup, "visible", true)
        }
    }
}

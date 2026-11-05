import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme
import "../shell/config" as Config

Item {
    id: root
    width: 480
    height: 240
    property int parentPresses: 0
    property int parentReleases: 0
    readonly property list<int> trackedKeys: [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space, Config.Keyboard.settingsKey]

    Controls.InputState { id: input; pointerActive: false }
    Keys.onPressed: event => {
        if (root.trackedKeys.includes(event.key)) root.parentPresses += 1
        event.accepted = true
    }
    Keys.onReleased: event => {
        if (root.trackedKeys.includes(event.key)) root.parentReleases += 1
        event.accepted = true
    }

    Component {
        id: buttonComponent
        Controls.ShellButton {
            width: 160
            height: 40
            style: Theme.Style
            emphasis: Theme.Interaction.buttonEmphasis
            inputState: input
            text: qsTr("Save")
            property int clicks: 0
            onClicked: clicks += 1
        }
    }

    TestCase {
        name: "ShellButton"
        when: windowShown

        function init() {
            root.Window.window.requestActivate()
            tryCompare(root.Window.window, "active", true)
            root.parentPresses = 0
            root.parentReleases = 0
            input.pointerActive = false
        }

        function focusedButton() {
            const button = createTemporaryObject(buttonComponent, root)
            verify(!!button, "Component exists")
            button.forceActiveFocus(Qt.TabFocusReason)
            tryCompare(button, "activeFocus", true)
            tryCompare(button.background.border, "color", button.background.controlState.border)
            return button
        }

        function activationKeys() {
            return [
                { tag: "return", key: Qt.Key_Return, modifiers: Qt.NoModifier },
                { tag: "enter", key: Qt.Key_Enter, modifiers: Qt.NoModifier },
                { tag: "keypad-enter", key: Qt.Key_Enter, modifiers: Qt.KeypadModifier }
            ]
        }

        function test_focusRingOnlyWhenKeyboardDrives() {
            const button = focusedButton()
            const colors = button.style.controls
            input.pointerActive = false
            compare(button.background.controlState.focused, true)
            tryCompare(button.background.border, "color", colors.focus)
            // A mouse click focuses the button but must not draw a border.
            input.pointerActive = true
            compare(button.activeFocus, true)
            compare(button.background.controlState.focused, false)
            tryVerify(() => Qt.colorEqual(button.background.border.color, colors.outline)
                || Qt.colorEqual(button.background.border.color, Qt.rgba(0, 0, 0, 0)))
        }

        function test_activatesOnceOnRelease_data() {
            return activationKeys().concat([{ tag: "native-space", key: Qt.Key_Space, modifiers: Qt.NoModifier }])
        }

        function test_activatesOnceOnRelease(data) {
            const button = focusedButton()
            input.pointerActive = true
            keyPress(data.key, data.modifiers)
            compare(button.clicks, 0)
            compare(button.background.controlState.pressed, true)
            // Press recolours the fill; the border stays the keyboard-focus ring.
            tryCompare(button.background, "color", button.style.controls.containerPressed)
            tryCompare(button.background.border, "color", button.style.controls.focus)
            compare(input.pointerActive, false)
            keyRelease(data.key, data.modifiers)
            compare(button.clicks, 1)
            compare(button.activationKey, 0)
            compare(button.background.controlState.pressed, false)
            compare(root.parentPresses, 0)
            compare(root.parentReleases, 0)
        }

        function test_repeatedPressesAndUnarmedReleasesDoNotCommit_data() {
            return activationKeys()
        }

        function test_repeatedPressesAndUnarmedReleasesDoNotCommit(data) {
            const button = focusedButton()
            keyRelease(data.key, data.modifiers)
            compare(button.clicks, 0)
            keyPress(data.key, data.modifiers)
            keyPress(data.key, data.modifiers)
            keyPress(data.key, data.modifiers)
            compare(button.clicks, 0)
            keyRelease(data.key, data.modifiers)
            compare(button.clicks, 1)
            keyRelease(data.key, data.modifiers)
            compare(button.clicks, 1)
            compare(root.parentPresses, 0)
            compare(root.parentReleases, 0)
        }

        function test_focusLossCancelsAndDoesNotActivateNewOwner_data() {
            return activationKeys()
        }

        function test_focusLossCancelsAndDoesNotActivateNewOwner(data) {
            const button = focusedButton()
            keyPress(data.key, data.modifiers)
            const other = focusedButton()
            compare(button.activationKey, 0)
            keyRelease(data.key, data.modifiers)
            compare(button.clicks, 0)
            compare(other.clicks, 0)
        }

        function test_disabledOrHiddenCancels_data() {
            return [{ tag: "disabled", property: "enabled" }, { tag: "hidden", property: "visible" }]
        }

        function test_disabledOrHiddenCancels(data) {
            const button = focusedButton()
            keyPress(Qt.Key_Return)
            button[data.property] = false
            compare(button.activationKey, 0)
            button[data.property] = true
            button.forceActiveFocus()
            keyRelease(Qt.Key_Return)
            compare(button.clicks, 0)
        }

        function test_tabCancelsTheArmedAction() {
            const button = focusedButton()
            const other = createTemporaryObject(buttonComponent, root, { x: 180 })
            verify(!!other, "Component exists")
            keyPress(Qt.Key_Return)
            keyClick(Qt.Key_Tab)
            tryCompare(other, "activeFocus", true)
            compare(button.activationKey, 0)
            keyRelease(Qt.Key_Return)
            compare(button.clicks, 0)
            compare(other.clicks, 0)
        }

        function test_disabledPointerDoesNotActivate() {
            const button = focusedButton()
            button.enabled = false
            mouseClick(button)
            tryCompare(button, "clicks", 0)
        }

        function test_unconfiguredModifiersDoNotActivate_data() {
            return [
                { tag: "control-return", key: Qt.Key_Return, modifiers: Qt.ControlModifier },
                { tag: "shift-return", key: Qt.Key_Return, modifiers: Qt.ShiftModifier },
                { tag: "alt-keypad-enter", key: Qt.Key_Enter, modifiers: Qt.AltModifier | Qt.KeypadModifier }
            ]
        }

        function test_unconfiguredModifiersDoNotActivate(data) {
            const button = focusedButton()
            keyClick(data.key, data.modifiers)
            compare(button.clicks, 0)
            compare(button.activationKey, 0)
            compare(root.parentPresses, 1)
            compare(root.parentReleases, 1)
        }

        function test_modifierChangeCancelsTheArmedAction() {
            const button = focusedButton()
            keyPress(Qt.Key_Return)
            keyRelease(Qt.Key_Return, Qt.ControlModifier)
            compare(button.clicks, 0)
            compare(button.activationKey, 0)
            compare(root.parentReleases, 0)
        }

        function test_otherActivationKeyDoesNotReplaceTheArmedKey() {
            const button = focusedButton()
            keyPress(Qt.Key_Return)
            keyPress(Qt.Key_Enter)
            keyRelease(Qt.Key_Enter)
            compare(button.clicks, 0)
            compare(button.activationKey, Qt.Key_Return)
            keyRelease(Qt.Key_Return)
            compare(button.clicks, 1)
            compare(button.activationKey, 0)
        }

        function test_pointerActivationRemainsNative() {
            const button = focusedButton()
            mousePress(button)
            tryCompare(button, "clicks", 0)
            mouseRelease(button)
            tryCompare(button, "clicks", 1)
        }

        function test_unrelatedShortcutStillReachesTheOwner() {
            const button = focusedButton()
            keyClick(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
            compare(button.clicks, 0)
            compare(root.parentPresses, 1)
            compare(root.parentReleases, 1)
        }
    }
}

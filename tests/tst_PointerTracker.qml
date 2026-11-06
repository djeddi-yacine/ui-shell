import QtQuick
import QtQuick.Window
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

// Hover is shown only while the pointer is the active input device. This drives real mouse
// events: the first real movement turns hover on, and any key press turns it off until the
// mouse moves again.
Item {
    id: root
    width: 400
    height: 300
    Controls.InputState { id: input; pointerActive: false }
    Item {
        id: area
        anchors.fill: parent
        Controls.PointerTracker { inputState: input }
        Controls.ShellButton {
            id: button
            x: 100; y: 100; width: 120; height: 40
            style: Theme.Style
            inputState: input
            emphasis: Theme.Interaction.buttonEmphasis
            text: "Hover me"
        }
    }
    TestCase {
        name: "PointerTracker"
        when: windowShown
        function init() { root.Window.window.requestActivate(); input.pointerActive = false; mouseMove(root, 5, 5); wait(30) }

        function test_movingTurnsHoverOn() {
            mouseMove(button, 60, 20)
            mouseMove(button, 64, 22)
            tryCompare(input, "pointerActive", true)
            tryCompare(button, "hovered", true)
        }
        function test_aKeyPressTurnsItOffUntilTheMouseMovesAgain() {
            mouseMove(button, 60, 20)
            mouseMove(button, 64, 22)
            tryCompare(input, "pointerActive", true)
            input.keyboardUsed()
            compare(input.pointerActive, false)
            mouseMove(button, 70, 24)
            tryCompare(input, "pointerActive", true)
        }
    }
}

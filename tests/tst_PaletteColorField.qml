import QtQuick
import QtTest

import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 520
    height: 120

    Controls.InputState { id: fieldInput; pointerActive: false }

    Component {
        id: fieldComponent
        Controls.PaletteColorField {
            width: 500
            height: 40
            role: ({ label: qsTr("Accent") })
            style: Theme.Style
            inputState: fieldInput
            value: "#336699"
        }
    }

    TestCase {
        name: "PaletteColorField"
        when: windowShown

        function test_hexValidatorAcceptsAndRejectsColors() {
            const field = createTemporaryObject(fieldComponent, root)
            verify(!!field, "Component exists")
            const hex = findChild(field, "paletteHex")
            verify(!!hex, "Object exists")

            hex.text = "#a1B2c3"
            compare(hex.acceptableInput, true)
            hex.text = "#12xz56"
            compare(hex.acceptableInput, false)
            hex.text = "336699"
            compare(hex.acceptableInput, false)
        }

        function test_enterRestoresCommittedValueAfterFocus() {
            const field = createTemporaryObject(fieldComponent, root)
            verify(!!field, "Component exists")
            const hex = findChild(field, "paletteHex")
            verify(!!hex, "Object exists")

            hex.text = "#aabbcc"
            hex.forceActiveFocus()
            tryCompare(hex, "activeFocus", true)
            keyPress(Qt.Key_Return)
            keyRelease(Qt.Key_Return)
            tryCompare(hex, "text", "#336699")
        }
    }
}

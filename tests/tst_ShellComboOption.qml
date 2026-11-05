import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 360
    height: 160
    Rectangle { anchors.fill: parent; color: Theme.Style.surface; z: -1 }
    Controls.InputState { id: input; pointerActive: false }
    Controls.PointerTracker { inputState: input }
    Component {
        id: optionComponent
        Controls.ShellComboOption {
            x: 24
            y: 24
            width: 300
            height: 36
            style: Theme.Style
            inputState: input
            emphasis: Theme.Interaction.selectorOptionEmphasis
            currentChoice: false
            keyboardCandidate: false
            text: qsTr("Option")
        }
    }
    Component {
        id: comboComponent
        Controls.ShellComboBox {
            x: 24
            y: 24
            width: 300
            style: Theme.Style
            inputState: input
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            model: [{ label: "On" }, { label: "Off" }]
            textRole: "label"
            currentIndex: 0
        }
    }
    TestCase {
        name: "ShellComboOption"
        when: windowShown
        function init() {
            mouseMove(root, root.width - 2, root.height - 2)
            root.forceActiveFocus()
            input.keyboardUsed()
        }
        function test_pointerMovementDoesNotAddHoverState_data() {
            return [{ tag: "ordinary", current: false }, { tag: "committed", current: true }]
        }
        function test_pointerMovementDoesNotAddHoverState(data) {
            const option = createTemporaryObject(optionComponent, root, { currentChoice: data.current })
            verify(!!option, "Component exists")
            tryCompare(option, "foregroundColor", data.current ? Theme.Style.controls.currentText : Theme.Style.controls.text)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            mouseMove(option, option.width / 2, option.height / 2)
            mouseMove(option, option.width / 2 + 1, option.height / 2)
            tryCompare(input, "pointerActive", true)
            tryCompare(option, "hovered", false)
            tryCompare(option, "foregroundColor", data.current ? Theme.Style.controls.currentText : Theme.Style.controls.text)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            tryCompare(option, "currentChoice", data.current)
            compare(option.font.weight, Theme.Style.bodyWeight)
            verify(Theme.Interaction.contrast(option.foregroundColor, option.background.color) >= Theme.Interaction.minimumTextContrast)
            input.keyboardUsed()
            tryCompare(option, "foregroundColor", data.current ? Theme.Style.controls.currentText : Theme.Style.controls.text)
            tryCompare(option, "candidate", false)
        }
        function test_candidateAndCommittedChoiceRemainSeparate() {
            const option = createTemporaryObject(optionComponent, root, { currentChoice: true })
            verify(!!option, "Component exists")
            option.keyboardCandidate = true
            tryCompare(option, "candidate", true)
            tryCompare(option, "foregroundColor", Theme.Style.controls.selectionText)
            compare(option.font.weight, Theme.Style.bodyWeight)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            compare(option.currentChoice, true)
            compare(option.background.border.width, 0)
            input.pointerUsed()
            tryCompare(option, "candidate", true)
            tryCompare(option, "foregroundColor", Theme.Style.controls.selectionText)
            compare(option.font.weight, Theme.Style.bodyWeight)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            compare(option.width, 300)
            compare(option.x, 24)
        }
        function test_focusAndPressNeverAddRowBorders() {
            const option = createTemporaryObject(optionComponent, root)
            verify(!!option, "Component exists")
            option.forceActiveFocus()
            tryCompare(option, "foregroundColor", Theme.Style.controls.focusText)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            compare(option.background.border.width, 0)
            mousePress(option, option.width / 2, option.height / 2)
            tryCompare(option, "down", true)
            tryCompare(option, "foregroundColor", Theme.Style.controls.pressedText)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
            compare(option.background.border.width, 0)
            mouseRelease(option, option.width / 2, option.height / 2)
            compare(option.width, 300)
            compare(option.x, 24)
        }
        function test_disabledSuppressesPointerFeedback() {
            const option = createTemporaryObject(optionComponent, root, { currentChoice: true, enabled: false })
            verify(!!option, "Component exists")
            mouseMove(option, option.width / 2, option.height / 2)
            input.pointerUsed()
            tryCompare(option, "foregroundColor", Theme.Style.controls.disabledText)
            tryCompare(option.background, "color", Theme.Style.controls.surface)
            tryCompare(option.background.border, "color", Theme.Interaction.transparentColor)
        }
        function test_nativeDropdownKeepsKeyboardCandidateDuringPointerMovement() {
            const combo = createTemporaryObject(comboComponent, root)
            verify(!!combo, "Component exists")
            combo.forceActiveFocus()
            keyClick(Qt.Key_Space)
            tryCompare(combo.popup, "opened", true)
            keyClick(Qt.Key_Down)
            tryCompare(combo, "highlightedIndex", 1)
            tryVerify(() => combo.popup.contentItem.itemAtIndex(1) !== null)
            const option = combo.popup.contentItem.itemAtIndex(1)
            verify(!!option, "Native popup option exists")
            tryCompare(option, "candidate", true)
            tryCompare(option, "foregroundColor", Theme.Style.controls.selectionText)
            verify(waitForRendering(option), "Popup option rendered")
            mouseMove(option, option.width / 2, option.height / 2)
            mouseMove(option, option.width / 2 + 1, option.height / 2)
            tryCompare(option, "hovered", false)
            tryCompare(input, "pointerActive", true)
            tryCompare(option, "candidate", true)
            tryCompare(option, "foregroundColor", Theme.Style.controls.selectionText)
            keyClick(Qt.Key_Up)
            tryCompare(input, "pointerActive", false)
            tryCompare(combo, "highlightedIndex", 0)
            const committed = combo.popup.contentItem.itemAtIndex(0)
            verify(!!committed, "Native committed option exists")
            tryCompare(committed, "candidate", true)
            compare(committed.currentChoice, true)
            compare(committed.font.weight, Theme.Style.bodyWeight)
            compare(committed.background.border.width, 0)
            compare(combo.popup.background.border.width, Theme.Shape.borderWidth)
            compare(combo.popup.padding, Theme.Shape.borderWidth)
            compare(option.width, combo.popup.availableWidth)
            compare(combo.currentIndex, 0)
            keyClick(Qt.Key_Escape)
            tryCompare(combo.popup, "visible", false)
            compare(combo.currentIndex, 0)
        }
        function test_nativeDropdownStillAcceptsPointerClick() {
            const combo = createTemporaryObject(comboComponent, root)
            verify(!!combo, "ComboBox exists")
            combo.forceActiveFocus()
            keyClick(Qt.Key_Space)
            tryCompare(combo.popup, "opened", true)
            tryVerify(() => combo.popup.contentItem.itemAtIndex(1) !== null)
            const option = combo.popup.contentItem.itemAtIndex(1)
            verify(waitForRendering(option), "Popup option rendered")
            mouseClick(option, option.width / 2, option.height / 2)
            tryCompare(combo, "currentIndex", 1)
            tryCompare(combo.popup, "visible", false)
        }
    }
}

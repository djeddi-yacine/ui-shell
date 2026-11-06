import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 420
    height: 120
    Controls.InputState { id: input; pointerActive: false }
    Component {
        id: sliderComponent
        Controls.ShellSlider {
            x: 20
            y: 40
            width: 380
            height: 28
            style: Theme.Style
            inputState: input
            from: 0
            to: 1.5
            stepSize: 0.05
            value: 0.5
        }
    }
    SignalSpy { id: moved; signalName: "moved" }

    TestCase {
        name: "ShellSlider"
        when: windowShown

        function make() {
            const slider = createTemporaryObject(sliderComponent, root)
            verify(!!slider, "slider exists")
            moved.target = slider
            moved.clear()
            return slider
        }

        function test_keyboardStepsAndEnds() {
            const slider = make()
            slider.forceActiveFocus()
            keyClick(Qt.Key_Right)
            fuzzyCompare(slider.value, 0.55, 0.001)
            verify(moved.count >= 1, "a key step reports moved")
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Left)
            fuzzyCompare(slider.value, 0.45, 0.001)
            keyClick(Qt.Key_Home)
            compare(slider.value, 0)
            keyClick(Qt.Key_End)
            compare(slider.value, 1.5)
            keyClick(Qt.Key_Right)
            compare(slider.value, 1.5, "never beyond the ceiling")
        }

        function test_clickOnTheTrackJumps() {
            const slider = make()
            mouseClick(slider, slider.leftPadding + slider.availableWidth * 0.5, slider.height / 2)
            fuzzyCompare(slider.value, 0.75, 0.1)
            verify(moved.count >= 1, "a click reports moved")
        }

        function test_dragFollowsThePointerExactly() {
            const slider = make()
            mousePress(slider, slider.leftPadding + 5, slider.height / 2)
            compare(slider.pressed, true)
            mouseMove(slider, slider.leftPadding + slider.availableWidth * 0.8, slider.height / 2)
            mouseMove(slider, slider.leftPadding + slider.availableWidth * 0.3, slider.height / 2)
            fuzzyCompare(slider.value, 0.45, 0.1)
            mouseRelease(slider, slider.leftPadding + slider.availableWidth * 0.3, slider.height / 2)
            compare(slider.pressed, false)
            verify(moved.count >= 2, "dragging reports moved as it goes")
        }

        function test_wheelAdjustsUnlessTheListIsScrolling() {
            const slider = make()
            const before = slider.value
            mouseWheel(slider, slider.width / 2, slider.height / 2, 0, 120)
            verify(slider.value > before, "wheel up raises the value")
            const raised = slider.value
            slider.wheelAllowed = false
            mouseWheel(slider, slider.width / 2, slider.height / 2, 0, 120)
            compare(slider.value, raised, "a scrolling list keeps its wheel gesture")
        }

        function test_handleGlidesAfterAKeyChangeAndLandsExactly() {
            const slider = make()
            slider.forceActiveFocus()
            keyClick(Qt.Key_End)
            const handle = slider.handle
            const target = slider.leftPadding + slider.visualPosition * (slider.availableWidth - handle.width)
            tryCompare(handle, "x", target, 2000)
            compare(slider.visualPosition, 1)
        }

        function test_focusAndHoverAreVisibleWithoutChangingSize() {
            const slider = make()
            const size = Qt.size(slider.handle.width, slider.handle.height)
            const resting = Qt.colorEqual(slider.handle.border.color, Theme.Style.controls.outline)
            verify(resting, "an idle handle uses the outline colour")
            input.pointerActive = false
            slider.forceActiveFocus()
            tryVerify(() => Qt.colorEqual(slider.handle.border.color, Theme.Style.controls.focus), 1000, "keyboard focus shows the focus colour")
            compare(slider.handle.width, size.width)
            compare(slider.handle.height, size.height)
        }
    }
}

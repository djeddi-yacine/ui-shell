import QtQuick
import QtQuick.Window
import QtTest
import "../shell/tests/mpris" as Shell
import "../shell/theme" as Theme

// One fixed-height line that scrolls only when the text does not fit.
Item {
    id: root
    width: 300
    height: 80
    Component {
        id: lineComponent
        Shell.MarqueeText {
            width: 120
            color: "white"
            font.pointSize: 12
        }
    }
    TestCase {
        name: "MarqueeText"
        when: windowShown

        function make(text) { return createTemporaryObject(lineComponent, root, { text: text }) }

        function test_aShortTextDoesNotMove() {
            const line = make("Short")
            compare(line.overflow, 0)
            compare(line.animated, false)
        }
        function test_aLongTextScrollsWhileRunning() {
            const line = make("A title that is much too long for this narrow line")
            verify(line.overflow > 0)
            compare(line.animated, Theme.Motion.active)
        }
        function test_itDoesNotScrollWhenNotRunning() {
            const line = make("A title that is much too long for this narrow line")
            line.running = false
            compare(line.animated, false)
        }
        function test_theHeightDoesNotDependOnTheText() {
            const a = make("A"), b = make("A title that is much too long for this narrow line")
            compare(a.height, b.height)
            verify(a.height > 0)
        }
        function test_changingTheTextStartsFromTheBeginning() {
            const line = make("A title that is much too long for this narrow line")
            wait(200)
            line.text = "Another title that is also much too long for this line"
            compare(findChild(line, "marqueeLabel").x, 0)
        }
    }
}

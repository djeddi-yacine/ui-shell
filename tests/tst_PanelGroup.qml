import QtQuick
import QtTest
import "../shell/modules/panels" as Panels

// Opening a panel closes the other members of its group, and only those.
Item {
    id: root
    QtObject { id: a; property bool open: false }
    QtObject { id: b; property bool open: false }
    QtObject { id: c; property bool open: false }
    QtObject { id: outside; property bool open: false }
    Panels.PanelGroup { panels: [a, b, c] }

    TestCase {
        name: "PanelGroup"
        function init() { a.open = false; b.open = false; c.open = false; outside.open = false }

        function test_openingClosesTheOthers() {
            a.open = true
            b.open = true
            compare(a.open, false)
            compare(b.open, true)
            c.open = true
            compare(b.open, false)
            compare(c.open, true)
        }
        function test_closingOpensNothing() {
            a.open = true
            a.open = false
            compare(a.open, false)
            compare(b.open, false)
            compare(c.open, false)
        }
        function test_aPanelOutsideTheGroupCoexists() {
            outside.open = true
            a.open = true
            compare(outside.open, true)
            outside.open = false
            compare(a.open, true)
        }
    }
}

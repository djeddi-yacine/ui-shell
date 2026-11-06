import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 360
    height: 400
    Component {
        id: helpComponent
        Controls.ContextHelp {
            width: 320
            style: Theme.Style
            bindings: [
                { key: Qt.Key_Left, modifiers: Qt.NoModifier, action: "Short" },
                { key: Qt.Key_Return, modifiers: Qt.NoModifier,
                    action: "A deliberately long description of an action that has far more words than fit on one line of a narrow popup, so it must wrap" }
            ]
        }
    }
    TestCase {
        name: "ContextHelp"
        when: windowShown
        function test_longActionsWrapInsteadOfRunningOffTheEdge() {
            const help = createTemporaryObject(helpComponent, root)
            verify(!!help, "help exists")
            const rows = []
            for (let i = 0; i < help.children.length; i++)
                if (help.children[i].children && help.children[i].children.length === 0) continue
            // Every text stays inside the popup's width.
            function walk(item) {
                if (item.text !== undefined && item.contentWidth !== undefined) {
                    const right = item.mapToItem(help, item.width, 0).x
                    verify(right <= help.width + 0.5, "'" + String(item.text).slice(0, 24) + "' stays inside the help width")
                    if (String(item.text).startsWith("A deliberately"))
                        verify(item.lineCount > 1, "the long action wraps onto several lines")
                }
                for (let i = 0; i < item.children.length; i++) walk(item.children[i])
            }
            walk(help)
        }
    }
}

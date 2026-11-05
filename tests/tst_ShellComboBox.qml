import QtQuick
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 760
    height: 720
    Controls.InputState { id: input; pointerActive: false }
    Component {
        id: comboComponent
        Controls.ShellComboBox {
            x: 24
            y: 24
            width: 500
            height: Theme.Style.controlHeight
            style: Theme.Style
            inputState: input
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            textRole: "label"
            valueRole: "id"
        }
    }
    TestCase {
        name: "ShellComboBox"
        when: windowShown
        function choices() {
            const entries = []
            for (let number = 0; number < 500; number += 1)
                entries.push({ id: "theme-" + number, label: qsTr("Theme %1").arg(number) })
            return entries
        }
        function test_largeCatalogIsInactiveWhileClosed() {
            const combo = createTemporaryObject(comboComponent, root, { model: choices() })
            verify(!!combo, "Component exists")
            compare(combo.popup.contentItem.model, null)
            combo.popup.open()
            tryCompare(combo.popup, "opened", true)
            tryCompare(combo.popup.contentItem, "count", combo.model.length)
            verify(combo.popup.contentItem.reuseItems)
            verify(combo.popup.height <= Theme.Style.menuMaximumHeight)
            verify(combo.popup.contentItem.height < combo.popup.contentItem.implicitHeight)
            verify(combo.popup.contentItem.itemAtIndex(combo.model.length - 1) === null)
            combo.popup.close()
            tryCompare(combo.popup, "visible", false)
            tryCompare(combo.popup.contentItem, "model", null)
            tryCompare(combo.popup.contentItem, "count", 0)
        }
        function test_keyboardCanReachLastThemeWithoutCreatingWholeCatalog() {
            const entries = choices()
            const last = entries.find(entry => entry.id === "theme-499")
            const combo = createTemporaryObject(comboComponent, root, { model: entries })
            verify(!!combo, "Component exists")
            combo.focus = true
            keyClick(Qt.Key_Space)
            tryCompare(combo.popup, "opened", true)
            keyClick(Qt.Key_End)
            keyClick(Qt.Key_Return)
            tryCompare(combo.popup, "visible", false)
            tryCompare(combo, "currentValue", last.id)
            tryCompare(combo, "currentText", last.label)
            tryCompare(combo.popup.contentItem, "model", null)
        }
    }
}

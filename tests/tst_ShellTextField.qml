import QtQuick
import QtQuick.Controls.Basic
import QtTest

import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 360
    height: 80

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Theme.Style.background
    }

    Controls.InputState {
        id: fieldInput
        pointerActive: false
    }

    Component {
        id: shellTextFieldComponent
        Controls.ShellTextField {
            x: 20
            y: 20
            width: 300
            height: 40
            style: Theme.Style
            emphasis: Theme.Interaction.inputEmphasis
            inputState: fieldInput
        }
    }

    TestCase {
        name: "ShellTextField"
        when: windowShown

        function init() {
            fieldInput.keyboardUsed()
        }

        function colorsNear(actual, expected) {
            return Math.abs(actual.r * 255 - expected.r * 255) <= 2
                && Math.abs(actual.g * 255 - expected.g * 255) <= 2
                && Math.abs(actual.b * 255 - expected.b * 255) <= 2
        }

        function test_pointerPressAndStationaryKeyboardInput() {
            const field = createTemporaryObject(shellTextFieldComponent, root)
            verify(!!field, "Component exists")
            compare(field.pointerPressed, false)
            field.forceActiveFocus()
            tryCompare(field, "activeFocus", true)

            const image = grabImage(root)
            verify(colorsNear(image.pixel(field.x + field.width - 4,
                                         field.y + field.height / 2), Theme.Style.surface))

            mousePress(field, field.width / 2, field.height / 2)
            tryCompare(field, "pointerPressed", true)
            tryCompare(fieldInput, "pointerActive", true)

            mouseRelease(field, field.width / 2, field.height / 2)
            tryCompare(field, "pointerPressed", false)

            keyClick(Qt.Key_A)
            tryCompare(fieldInput, "pointerActive", false)
            tryCompare(field, "text", "a")
        }

        function test_focusRecolorsBorderAndFillWithoutChangingGeometry() {
            const field = createTemporaryObject(shellTextFieldComponent, root)
            verify(!!field, "Component exists")
            root.forceActiveFocus()
            tryCompare(field, "activeFocus", false)
            tryVerify(function() {
                return colorsNear(grabImage(root).pixel(field.x, field.y + field.height / 2), Theme.Style.controls.outline)
            })
            const originalPadding = field.leftPadding
            field.forceActiveFocus()
            tryCompare(field, "activeFocus", true)
            tryVerify(function() {
                const expectedFocus = Theme.Style.controls.focus
                const image = grabImage(root)
                const middle = field.y + field.height / 2
                return colorsNear(image.pixel(field.x, middle), expectedFocus)
                    && colorsNear(image.pixel(field.x - 1, middle), Theme.Style.background)
                    && colorsNear(image.pixel(field.x + 1, middle), Theme.Style.controls.focusSurface)
                    && colorsNear(image.pixel(field.x + field.width - 1, middle), expectedFocus)
                    && colorsNear(image.pixel(field.x + field.width, middle), Theme.Style.background)
            })
            compare(field.x, 20)
            compare(field.y, 20)
            compare(field.width, 300)
            compare(field.height, 40)
            compare(field.leftPadding, originalPadding)
            compare(field.background.border.width, Theme.Shape.borderWidth)
        }

        function test_builtInContextMenuReadsTheStylePalette() {
            const field = createTemporaryObject(shellTextFieldComponent, root)
            verify(!!field, "Component exists")
            // Qt's Cut/Copy/Paste menu reads these roles, not the field's own colors.
            const colors = Theme.Style.controls
            compare(String(field.palette.window), String(colors.surface))
            compare(String(field.palette.windowText), String(colors.text))
            compare(String(field.palette.dark), String(colors.outline))
            compare(String(field.palette.light), String(colors.hoverSurface))
            // The menu itself is a child of the field and must inherit the themed roles.
            const menu = field.ContextMenu.menu
            verify(!!menu, "The field has a built-in context menu")
            compare(String(menu.palette.window), String(colors.surface))
            compare(String(menu.palette.windowText), String(colors.text))
        }
    }
}

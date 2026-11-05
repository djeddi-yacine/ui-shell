import QtQuick
import QtTest

import "../shell/components" as Controls
import "../shell/theme" as Theme
import "../shell/config" as Config

Item {
    id: root
    width: 640
    height: 480
    property var activePicker: null
    property string chosenColor: ""

    Controls.InputState { id: pickerInput; pointerActive: false }

    Connections {
        target: root.activePicker
        function onChosen(color) { root.chosenColor = color }
    }

    Component {
        id: pickerComponent
        Controls.PaletteColorPicker {
            owner: root
            style: Theme.Style
            inputState: pickerInput
        }
    }

    TestCase {
        name: "PaletteColorPicker"
        when: windowShown

        SignalSpy {
            id: chosenSpy
            signalName: "chosen"
        }

        function openPicker() {
            const picker = createTemporaryObject(pickerComponent, root)
            verify(!!picker, "Component exists")
            root.activePicker = picker
            root.chosenColor = ""
            picker.begin({ key: "accent", label: qsTr("Accent") }, "#336699", null)
            tryCompare(picker, "opened", true)
            tryVerify(function() { return !!findChild(picker.contentItem, "paletteChannel-red") })
            return picker
        }

        function test_namedRgbChannelsInitializeFromSeed() {
            const picker = openPicker()
            const channels = Config.ThemeEditor.colorChannels
            for (let index = 0; index < channels.length; ++index) {
                const channel = channels[index]
                const slider = findChild(picker.contentItem, "paletteChannel-" + channel.key)
                verify(!!slider, "Object exists")
                const colorComponent = { red: "r", green: "g", blue: "b" }[channel.key]
                compare(slider.value, Math.round(picker.seedColor[colorComponent] * Config.ThemeEditor.channelMaximum))
            }
        }

        function test_sliderDragChangesPreviewAndCancelDoesNotChoose() {
            const picker = openPicker()
            const redSlider = findChild(picker.contentItem, "paletteChannel-red")
            verify(!!redSlider, "Object exists")
            const handleWidth = redSlider.handle.width
            const startX = redSlider.leftPadding + handleWidth / 2
                + redSlider.visualPosition * (redSlider.availableWidth - handleWidth)
            const targetX = redSlider.leftPadding + handleWidth / 2
                + 0.82 * (redSlider.availableWidth - handleWidth)
            const expectedRed = Math.round((redSlider.from + (redSlider.to - redSlider.from) * 0.82)
                                           / redSlider.stepSize) * redSlider.stepSize
            mousePress(redSlider, startX, redSlider.height / 2)
            mouseMove(redSlider, targetX, redSlider.height / 2)
            tryCompare(redSlider, "value", expectedRed)
            tryCompare(picker, "value", Qt.rgba(expectedRed / Config.ThemeEditor.channelMaximum,
                                                 picker.channels.green / Config.ThemeEditor.channelMaximum,
                                                 picker.channels.blue / Config.ThemeEditor.channelMaximum, 1))
            mouseRelease(redSlider, targetX, redSlider.height / 2)
            tryCompare(picker, "visible", true)

            chosenSpy.target = picker
            chosenSpy.clear()
            picker.close()
            tryCompare(picker, "visible", false)
            compare(chosenSpy.count, 0)
        }

        function test_enterOnChooseEmitsPreviewColor() {
            const picker = openPicker()
            const chooseButton = findChild(picker.contentItem, "paletteColorChoose")
            verify(!!chooseButton, "Object exists")
            chosenSpy.target = picker
            chosenSpy.clear()
            chooseButton.forceActiveFocus()
            tryCompare(chooseButton, "activeFocus", true)

            keyPress(Qt.Key_Return)
            keyRelease(Qt.Key_Return)
            tryCompare(chosenSpy, "count", 1)
            compare(root.chosenColor, "#336699")
        }

        function test_configuredCtrlEnterChoosesPrimaryAction_data() {
            return Config.Keyboard.popupActionKeys.map(function(key) {
                return { tag: Config.Keyboard.shortcut(key, Config.Keyboard.popupActionModifiers), key: key }
            })
        }

        function test_configuredCtrlEnterChoosesPrimaryAction(data) {
            const picker = openPicker()
            chosenSpy.target = picker
            chosenSpy.clear()
            keyClick(data.key, Config.Keyboard.popupActionModifiers)
            tryCompare(chosenSpy, "count", 1)
            tryCompare(picker, "visible", false)
            compare(root.chosenColor, "#336699")
        }
    }
}

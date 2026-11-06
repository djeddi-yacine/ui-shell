pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// One mixer entry as an outlined card, on two lines: identity and controls above, a
// full-width slider below. The card's outline takes the focus colour while anything
// inside it has focus. Keys on a focused row: M mutes, D makes a device the default
// (the slider keeps the arrow keys). It paints and reports; the panel decides.
Rectangle {
    id: root
    required property var style
    required property Controls.InputState inputState
    property string title: ""
    property string subtitle: ""
    // A small chip beside the title, e.g. "Default".
    property string tag: ""
    // Volume as users see it (1 = 100%); null hides the slider and mute.
    property var volume: null
    property bool muted: false
    // Slider ceiling in percent (Ctrl+E offers 100, 125, 150).
    property int maximumPercent: Config.Audio.maximumVolumePercent
    // Arrow-key step of the slider, in percent (Ctrl+E offers 1, 2, 5 or 10).
    property int stepPercent: 1
    // False while the list is scrolling, so the wheel keeps scrolling.
    property bool wheelAllowed: true
    property bool showDefault: false
    property bool isDefault: false
    // [{ label, value }] and the value currently chosen; empty hides the chooser.
    property var choices: []
    property string choice: ""
    property string chooserLabel: ""
    readonly property real shown: slider.pressed ? slider.value : (volume ?? 0)
    readonly property bool loud: volume !== null && shown > 1.001
    readonly property Item focusItem: Window.window ? Window.window.activeFocusItem : null
    readonly property bool focusWithin: {
        for (let item = focusItem; item; item = item.parent)
            if (item === root) return true
        return false
    }
    // A new row first shows 0 and then takes its real value, so the slider glides in
    // (a tab switch builds fresh rows) instead of appearing already set.
    property bool revealed: false
    Timer { running: true; interval: Theme.Motion.revealDelay; onTriggered: root.revealed = true }
    // The widest label of the mute button, so it does not change size when it toggles.
    TextMetrics { id: muteMetrics; text: qsTr("Muted"); font.family: root.style.uiFamily; font.pointSize: root.style.bodyPointSize }
    signal volumeMoved(int percent)
    signal muteToggled()
    signal defaultRequested()
    signal choiceMade(string value)

    implicitHeight: layout.implicitHeight + padding * 2
    readonly property int padding: style.cardPadding
    color: focusWithin ? root.style.controls.focusSurface : root.style.background
    border.width: Theme.Shape.borderWidth
    border.color: focusWithin ? root.style.controls.focus : root.style.softOutline
    Behavior on border.color { enabled: Theme.Motion.active; ColorAnimation { duration: Theme.Motion.stateDuration } }

    Keys.onPressed: event => {
        if (event.modifiers !== Qt.NoModifier) return
        if (event.key === Qt.Key_M && root.volume !== null) { root.muteToggled(); event.accepted = true }
        else if (event.key === Qt.Key_D && root.showDefault && !root.isDefault) { root.defaultRequested(); event.accepted = true }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.style.spacingTight

        RowLayout {
            Layout.fillWidth: true
            spacing: root.style.spacing
            ColumnLayout {
                Layout.fillWidth: true
                // A child's maximumWidth would otherwise cap how far this column can grow.
                Layout.maximumWidth: Infinity
                spacing: 0
                RowLayout {
                    spacing: root.style.spacingTight
                    Text {
                        Layout.maximumWidth: Config.Audio.titleMaximumWidth
                        text: root.title
                        color: root.muted ? root.style.controls.muted : root.style.text
                        elide: Text.ElideRight
                        font.family: root.style.uiFamily
                        font.pointSize: root.style.bodyPointSize
                        font.weight: root.style.emphasisWeight
                    }
                    Rectangle {
                        visible: root.tag.length > 0
                        implicitWidth: tagText.implicitWidth + 12
                        implicitHeight: tagText.implicitHeight + 4
                        color: root.style.controls.container
                        border.width: Theme.Shape.borderWidth
                        border.color: root.style.softAccent
                        Text {
                            id: tagText
                            anchors.centerIn: parent
                            text: root.tag.toUpperCase()
                            color: root.style.controls.containerText
                            font.family: root.style.monoFamily
                            font.pointSize: root.style.microPointSize
                            font.letterSpacing: root.style.chipLetterSpacing
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.subtitle
                    color: root.style.textMuted
                    elide: Text.ElideRight
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.captionPointSize
                }
            }
            Controls.ShellComboBox {
                id: chooser
                visible: root.choices.length > 0
                Layout.preferredWidth: root.style.chooserWidth
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.selectorEmphasis
                optionEmphasis: Theme.Interaction.selectorOptionEmphasis
                model: root.choices
                textRole: "label"
                Accessible.name: root.chooserLabel || qsTr("Output of %1").arg(root.title)
                Binding { target: chooser; property: "currentIndex"; value: Math.max(0, root.choices.findIndex(entry => entry.value === root.choice)) }
                onActivated: index => root.choiceMade(root.choices[index].value)
            }
            Text {
                visible: root.volume !== null
                Layout.preferredWidth: root.style.readoutWidth
                horizontalAlignment: Text.AlignRight
                // While dragging, the number follows the handle, not the lagging graph.
                text: Math.round(root.shown * 100) + "%"
                // Above 100% is amplification: say so with the warning colour, not only the number.
                color: root.loud ? root.style.warning : root.muted ? root.style.controls.muted : root.style.text
                font.family: root.style.monoFamily
                font.pointSize: root.style.bodyPointSize
            }
            Controls.ShellButton {
                visible: root.showDefault && !root.isDefault
                text: qsTr("Use")
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Make %1 the default").arg(root.title)
                onClicked: root.defaultRequested()
            }
            Controls.ShellButton {
                visible: root.volume !== null
                Layout.preferredWidth: Math.ceil(muteMetrics.advanceWidth) + root.style.controlPaddingX * 2 + Theme.Shape.borderWidth * 2
                text: root.muted ? qsTr("Muted") : qsTr("Mute")
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                selected: root.muted
                Accessible.name: qsTr("Mute %1").arg(root.title)
                onClicked: root.muteToggled()
            }
        }
        Controls.ShellSlider {
            id: slider
            visible: root.volume !== null
            Layout.fillWidth: true
            Layout.preferredHeight: root.style.sliderHeight
            style: root.style
            inputState: root.inputState
            wheelAllowed: root.wheelAllowed
            from: 0
            to: root.maximumPercent / 100
            stepSize: root.stepPercent / 100
            Accessible.name: qsTr("Volume of %1").arg(root.title)
            // The graph is the source of truth, except while a drag is in progress.
            Binding { target: slider; property: "value"; value: root.revealed ? (root.volume ?? 0) : 0; when: !slider.pressed }
            onMoved: root.volumeMoved(Math.round(value * 100))
        }
    }
}

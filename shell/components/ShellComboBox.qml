pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import "../theme" as Theme

ComboBox {
    id: root
    required property var style
    required property string emphasis
    required property string optionEmphasis
    required property InputState inputState
    focusPolicy: Qt.StrongFocus

    hoverEnabled: true
    implicitHeight: style.controlHeight
    padding: style.controlPaddingY
    leftPadding: style.controlPaddingX + (mirrored ? indicator.width + spacing : 0)
    rightPadding: style.controlPaddingX + (mirrored ? 0 : indicator.width + spacing)
    font.family: style.uiFamily
    font.pointSize: style.bodyPointSize
    palette.text: visual.foreground
    palette.buttonText: visual.foreground
    palette.base: style.surface
    palette.highlight: visual.selectedColor
    palette.highlightedText: style.controls.primaryText

    ShellControlState { id: visual; style: root.style; control: root; inputState: root.inputState; emphasis: root.emphasis }

    delegate: ShellComboOption {
        id: option
        required property int index
        required property var model
        width: root.popup.availableWidth
        style: root.style
        inputState: root.inputState
        emphasis: root.optionEmphasis
        currentChoice: index === root.currentIndex
        keyboardCandidate: highlighted
        text: model[root.textRole]
        highlighted: index === root.highlightedIndex
        enabled: root.enabled
    }
    indicator: Item {
        implicitWidth: Theme.Shape.chevronWidth
        implicitHeight: Theme.Shape.chevronHeight
        x: root.mirrored ? root.style.controlPaddingX : root.width - width - root.style.controlPaddingX
        y: (root.height - height) / 2
        Accessible.ignored: true

        Rectangle {
            x: 0
            y: Theme.Shape.chevronStrokeWidth
            width: Theme.Shape.chevronArmLength
            height: Theme.Shape.chevronStrokeWidth
            rotation: Theme.Shape.chevronAngle
            color: visual.foreground
        }
        Rectangle {
            x: Theme.Shape.chevronWidth / 3
            y: Theme.Shape.chevronStrokeWidth
            width: Theme.Shape.chevronArmLength
            height: Theme.Shape.chevronStrokeWidth
            rotation: -Theme.Shape.chevronAngle
            color: visual.foreground
        }
    }
    background: ShellControlBackground { controlState: visual }
    popup.padding: Theme.Shape.borderWidth
    popup.topMargin: style.menuViewportMargin
    popup.bottomMargin: style.menuViewportMargin
    popup.height: Math.min(popup.contentItem.implicitHeight + popup.topPadding + popup.bottomPadding,
        style.menuMaximumHeight, Math.max(0, root.Window.height - popup.topMargin - popup.bottomMargin))
    // Keep the native delegate model/activation, not Basic's extra list contours.
    popup.contentItem: ListView {
        clip: true
        implicitHeight: count * root.style.controlHeight
        model: root.popup.visible ? root.delegateModel : null
        reuseItems: true
        currentIndex: root.highlightedIndex
        highlightMoveDuration: 0
        ScrollIndicator.vertical: ScrollIndicator {
            palette.mid: root.style.controls.outline
            palette.text: root.style.controls.text
        }
    }
    popup.background: Rectangle {
        radius: root.style.popupRadius
        color: root.style.popupSurface
        border.width: Theme.Shape.borderWidth
        border.color: root.style.popupBorder
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        root.inputState.keyboardUsed()
        event.accepted = false
    }
    PointerTracker {
        inputState: root.inputState
        enabled: root.enabled
        cursorShape: root.editable ? Qt.IBeamCursor : Qt.PointingHandCursor
    }
}

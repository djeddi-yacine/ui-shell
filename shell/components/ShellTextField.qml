import QtQuick
import QtQuick.Controls.Basic
import "../theme" as Theme

TextField {
    id: root
    required property var style
    required property string emphasis
    required property InputState inputState
    property bool pointerPressed: false
    focusPolicy: Qt.StrongFocus
    Theme.ControlPalette { palette: root.palette; colors: root.style.controls }
    // Qt's default Cut/Copy/Paste menu is a popup and stays white; use the themed one.
    ContextMenu.menu: ShellEditingMenu { editor: root; style: root.style }

    hoverEnabled: true
    implicitHeight: style.controlHeight
    padding: style.controlPaddingY
    leftPadding: style.controlPaddingX
    rightPadding: style.controlPaddingX
    font.family: style.uiFamily
    font.pointSize: style.bodyPointSize
    color: visual.foreground
    placeholderTextColor: style.textMuted
    selectionColor: visual.selectedColor
    selectedTextColor: style.controls.primaryText

    // TextField.pressed is a MouseEvent signal, so its press state is tracked below.
    ShellControlState { id: visual; style: root.style; control: root; inputState: root.inputState
        emphasis: root.emphasis; pressed: root.pointerPressed; alwaysShowFocus: true }
    background: ShellControlBackground { controlState: visual }
    // TextField.pressed is a MouseEvent signal, unlike Button.down.
    onPressed: {
        root.pointerPressed = true
        root.inputState.pointerUsed()
    }
    onReleased: root.pointerPressed = false
    onEnabledChanged: {
        if (!enabled)
            pointerPressed = false
    }
    onActiveFocusChanged: {
        if (!activeFocus)
            pointerPressed = false
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        root.pointerPressed = false
        root.inputState.keyboardUsed()
        event.accepted = false
    }
    PointerTracker {
        inputState: root.inputState
        enabled: root.enabled
        cursorShape: Qt.IBeamCursor
    }
}

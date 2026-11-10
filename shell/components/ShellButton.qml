import QtQuick
import QtQuick.Controls.Basic
import "../config" as Config
import "../theme" as Theme

Button {
    id: root

    required property var style
    required property string emphasis
    required property InputState inputState
    property bool selected: false
    property bool current: false
    property bool keyboardCandidate: false
    property int activationKey: 0
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    implicitHeight: style.controlHeight
    padding: style.controlPaddingY
    leftPadding: style.controlPaddingX
    rightPadding: style.controlPaddingX
    font.family: style.uiFamily
    font.pointSize: style.bodyPointSize

    // The colour its label is drawn in, for a content item that is not text (an icon).
    readonly property color foreground: visual.foreground

    ShellControlState {
        id: visual
        style: root.style
        control: root
        inputState: root.inputState
        emphasis: root.emphasis
        pressed: root.down || root.activationKey !== 0
        selected: root.selected
        current: root.current
        focused: focusVisible || root.keyboardCandidate
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: visual.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: ShellControlBackground { controlState: visual }
    function matchesActivation(event) {
        return Config.Keyboard.buttonActivationKeys.includes(event.key)
            && (event.modifiers & ~Qt.KeypadModifier) === Config.Keyboard.buttonActivationModifiers
    }
    onActiveFocusChanged: {
        if (!activeFocus)
            activationKey = 0
        if (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
            root.inputState.keyboardUsed()
    }
    onEnabledChanged: if (!enabled) activationKey = 0
    onVisibleChanged: if (!visible) activationKey = 0
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        root.inputState.keyboardUsed()
        event.accepted = root.matchesActivation(event)
        if (event.accepted && !event.isAutoRepeat && root.activeFocus && root.enabled
            && root.visible && root.activationKey === 0)
            root.activationKey = event.key
    }
    Keys.onReleased: event => {
        event.accepted = root.matchesActivation(event) || root.activationKey === event.key
        if (!event.accepted || event.isAutoRepeat || root.activationKey !== event.key)
            return
        const activate = root.activeFocus && root.enabled && root.visible && root.matchesActivation(event)
        root.activationKey = 0
        if (activate)
            root.click()
    }
    PointerTracker {
        inputState: root.inputState
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }
}

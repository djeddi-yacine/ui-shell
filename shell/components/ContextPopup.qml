pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as Templates
import "../theme" as Theme
import "../config" as Config

Popup {
    id: root
    required property Item owner
    required property var style
    required property InputState inputState
    property string kind: ""
    property bool shortcutsEnabled: true
    property Templates.AbstractButton primaryAction: null
    property Item returnFocus: null
    signal requested(string kind)
    // Everything inside inherits it, including Qt's default controls and menus.
    Theme.ControlPalette { palette: root.palette; colors: root.style.controls }
    parent: root.owner
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: Config.ContextPanels.padding
    width: Math.max(0, Math.min(owner.width - Config.ContextPanels.outerMargin * 2, Config.ContextPanels.maximumWidth))
    height: Math.max(0, Math.min(owner.height - Config.ContextPanels.outerMargin * 2, implicitHeight))
    x: (owner.width - width) / 2
    y: (owner.height - height) / 2

    function handleShortcut(event) {
        if (!shortcutsEnabled) return false
        if (event.modifiers !== Config.Keyboard.contextModifiers) return false
        if (event.key === Config.Keyboard.infoKey) requested("info")
        else if (event.key === Config.Keyboard.helpKey) requested("help")
        else if (event.key === Config.Keyboard.settingsKey) requested("settings")
        else return false
        event.accepted = true
        return true
    }
    function show(nextKind, previousFocus) {
        if (!visible) returnFocus = previousFocus
        kind = nextKind
        open()
    }
    onClosed: {
        const previous = returnFocus
        returnFocus = null
        if (owner.visible && previous && previous.visible && previous.enabled)
            previous.forceActiveFocus()
    }
    Connections {
        target: root.owner
        function onVisibleChanged() { if (!root.owner.visible) root.close() }
    }
    background: Rectangle {
        color: root.style.surfaceRaised
        radius: root.style.menuRadius
        border.width: Theme.Shape.borderWidth
        border.color: Theme.Interaction.readable(root.style.outline, root.style.surfaceRaised,
            Theme.Interaction.minimumStateContrast)
    }
    Overlay.modal: Rectangle {
        color: Qt.rgba(root.style.scrim.r, root.style.scrim.g, root.style.scrim.b,
            Config.ContextPanels.scrimOpacity)
    }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: Theme.Motion.panelEnterOpacity; to: 1; duration: Theme.Motion.active ? Theme.Motion.enterDuration : 0; easing.type: Theme.Motion.enterEasing }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.Motion.active ? Theme.Motion.exitDuration : 0; easing.type: Theme.Motion.exitEasing }
    }
    Item {
        parent: root.contentItem
        Shortcut {
            sequences: Config.Keyboard.popupActionKeys.map(key =>
                Config.Keyboard.shortcut(key, Config.Keyboard.popupActionModifiers))
            context: Qt.WindowShortcut
            autoRepeat: false
            enabled: root.opened && root.activeFocus && root.primaryAction !== null && root.primaryAction.enabled
            onActivated: { root.inputState.keyboardUsed(); root.primaryAction.click() }
        }
    }
    // Contextual shortcuts also open the popup while it is closed.
    Item {
        parent: root.owner
        visible: root.shortcutsEnabled
        Shortcut {
            sequence: Config.Keyboard.shortcut(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
            context: Qt.WindowShortcut
            enabled: root.shortcutsEnabled && root.owner.visible && root.owner.enabled
            onActivated: { root.inputState.keyboardUsed(); root.requested("info") }
        }
        Shortcut {
            sequence: Config.Keyboard.shortcut(Config.Keyboard.helpKey, Config.Keyboard.contextModifiers)
            context: Qt.WindowShortcut
            enabled: root.shortcutsEnabled && root.owner.visible && root.owner.enabled
            onActivated: { root.inputState.keyboardUsed(); root.requested("help") }
        }
        Shortcut {
            sequence: Config.Keyboard.shortcut(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
            context: Qt.WindowShortcut
            enabled: root.shortcutsEnabled && root.owner.visible && root.owner.enabled
            onActivated: { root.inputState.keyboardUsed(); root.requested("settings") }
        }
    }
}

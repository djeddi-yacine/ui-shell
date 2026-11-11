pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config" as Config
import "../../components" as Controls
import "../../theme" as Theme

// Two windows on the screen the menu is shown on, mapped while a request waits and through the card's leave
// animation: a full-screen layer that dims the desktop and answers with no
// choice when clicked, and the card that holds the keyboard. The card is a separate window so
// that only it is kept out of screen capture (the compositor rule matches its namespace).
Scope {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property bool shown: MenuState.open && !MenuState.blocked && MenuState.screenName === modelData.name
    // The windows are mapped from the moment the card is shown until its leave animation has
    // finished; `shown` alone would unmap them at once and cut the animation.
    property bool mapped: false
    onShownChanged: {
        if (shown) {
            if (mapped) panel.activate()
            else mapped = true
        } else if (mapped) {
            panel.leave()
        }
    }
    Component.onCompleted: mapped = shown

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.modelData.name)
    }

    PanelWindow {
        screen: root.modelData
        visible: root.mapped
        color: styleTokens.scrimColor(Config.Menu.scrimOpacity * panel.opacity)
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: Config.Menu.scrimNamespace
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        MouseArea { anchors.fill: parent; onClicked: MenuState.cancel() }
    }
    PanelWindow {
        screen: root.modelData
        visible: root.mapped
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Math.min(Config.Menu.cardWidth, root.modelData.width - Config.Menu.outerMargin * 2)
        implicitHeight: Math.min(Config.Menu.cardHeight, root.modelData.height - Config.Menu.outerMargin * 2)
        WlrLayershell.namespace: Config.Menu.namespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: { if (visible) panel.activate(); else panel.forget() }
        MenuPanel {
            id: panel
            anchors.fill: parent
            shown: root.shown
            screenName: root.modelData.name
            inputState: root.inputState
            onClosed: root.mapped = false
        }
    }
}

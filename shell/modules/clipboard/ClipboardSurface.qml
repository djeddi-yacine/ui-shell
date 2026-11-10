pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config" as Config
import "../../components" as Controls
import "../../theme" as Theme

// Two windows on the screen the panel was opened on, mapped only while it is open: a full-screen
// layer that dims the desktop and closes the panel when clicked, and the card that holds the
// keyboard. The card is a separate window so that it, and only it, is kept out of screen capture
// (the compositor rule matches its namespace). It has its final size from the start and holds
// the panel directly, so it never maps half built.
Scope {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property bool shown: ClipboardState.open && ClipboardState.screenName === modelData.name

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.modelData.name)
    }

    PanelWindow {
        screen: root.modelData
        visible: root.shown
        // The scrim fades with the card, in and out, so neither end pops.
        color: styleTokens.scrimColor(Config.Clipboard.scrimOpacity * panel.opacity)
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: Config.Clipboard.scrimNamespace
        // One layer below the card, so the card is above it however the two are mapped.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        MouseArea { anchors.fill: parent; onClicked: ClipboardState.open = false }
    }
    PanelWindow {
        screen: root.modelData
        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Math.min(Config.Clipboard.cardWidth, root.modelData.width - Config.Clipboard.outerMargin * 2)
        implicitHeight: Math.min(Config.Clipboard.cardHeight, root.modelData.height - Config.Clipboard.outerMargin * 2)
        WlrLayershell.namespace: Config.Clipboard.namespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: { if (visible) panel.activate(); else panel.forget() }
        ClipboardPanel {
            id: panel
            anchors.fill: parent
            shown: root.shown
            screenName: root.modelData.name
            inputState: root.inputState
            onClosed: ClipboardState.open = false
        }
    }
}

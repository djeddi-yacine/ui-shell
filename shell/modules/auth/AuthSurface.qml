pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config" as Config
import "../../theme" as Theme

// Two windows on the focused screen, mapped only while a request is active (not one per screen):
// a full-screen dimming layer that screen capture does see, and a card-sized layer that holds
// the keyboard and is kept out of screen capture. A recording therefore shows the dimmed
// desktop with a black rectangle where the dialog is. The dialog is built before its window is
// mapped: one that fills in later, while it already holds the keyboard, invites typing a
// password into a half-built view.
Scope {
    id: root
    readonly property string namespace: "ui-shell-auth"
    readonly property string scrimNamespace: "ui-shell-auth-scrim"
    readonly property bool shown: Config.Config.authEnabled && AuthState.auth.active
    readonly property var screen: Config.Outputs.launcherScreen(Quickshell.screens)

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.screen ? root.screen.name : "")
    }

    PanelWindow {
        screen: root.screen
        visible: root.shown
        color: styleTokens.scrimColor(Config.Auth.scrimOpacity)
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: root.scrimNamespace
        // One layer below the card, so the card is above it however the two are mapped.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    }

    // The card window has its final size from the start: it holds the dialog directly, not a
    // loader that fills in after the window is already mapped (that showed a cut-off card).
    PanelWindow {
        screen: root.screen
        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: dialog.implicitWidth
        implicitHeight: dialog.implicitHeight
        WlrLayershell.namespace: root.namespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        onVisibleChanged: if (visible) dialog.reset()
        AuthDialog {
            id: dialog
            anchors.fill: parent
            style: styleTokens
        }
    }
}

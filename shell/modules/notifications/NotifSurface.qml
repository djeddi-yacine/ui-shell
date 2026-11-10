pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// The drawer window: right edge, one per screen, mapped only while open on its screen.
PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    screen: modelData
    readonly property bool wanted: NotifState.open && NotifState.screenName === modelData.name
    // 0 = closed, 1 = open. Opening and closing take the same short time.
    property real reveal: 0
    Behavior on reveal {
        enabled: Theme.Motion.active
        NumberAnimation { duration: Theme.Motion.drawerDuration; easing.type: Theme.Motion.enterEasing }
    }
    // The window stays mapped while it fades out.
    visible: wanted || reveal > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: Config.Notifications.drawerNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // The window gets keyboard focus after it maps, so ask for it on the next turn.
    onWantedChanged: {
        reveal = wanted ? 1 : 0
        if (wanted) Qt.callLater(drawer.activate)
    }

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.modelData.name)
    }
    // The backdrop dims the screen; a click anywhere outside the drawer closes it.
    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(Config.Notifications.backdropOpacity)
        opacity: root.reveal
        MouseArea {
            anchors.fill: parent
            onClicked: NotifState.open = false
        }
    }
    NotifDrawer {
        id: drawer
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; rightMargin: -Config.Notifications.drawerSlide * (1 - root.reveal) }
        opacity: root.reveal
        width: Config.Notifications.drawerWidth
        style: styleTokens
        inputState: root.inputState
        onClosed: NotifState.open = false
    }
}

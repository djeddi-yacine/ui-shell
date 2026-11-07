pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as Controls
import "../../config" as Config

// The panel's window, one per output, in the shape of the audio surface. The namespace comes
// from the config so the Hyprland rule and this window cannot drift apart (tests/scripts/check-mpris).
PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property MprisPanel panel: loader.status === Loader.Ready ? loader.item as MprisPanel : null
    property bool panelRequested: false
    screen: modelData
    visible: MprisState.open && MprisState.screenName === modelData.name
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: Config.Mpris.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: {
        if (visible) {
            panelRequested = true
            if (panel) panel.activate()
        }
    }
    Loader {
        id: loader
        anchors.fill: parent
        active: root.panelRequested
        visible: root.visible
        asynchronous: Config.Mpris.asynchronousPanelLoad
        sourceComponent: MprisPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            open: root.visible
            onClosed: MprisState.open = false
        }
    }
}

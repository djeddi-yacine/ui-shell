pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config" as Config
import "../../components" as Controls

PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property AppPanel panel: loader.status === Loader.Ready ? loader.item as AppPanel : null
    property bool panelRequested: false
    screen: modelData
    visible: AppState.open && AppState.screenName === modelData.name
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-app-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: {
        if (visible) {
            panelRequested = true
            if (panel) panel.activate()
        } else if (!Config.AppLauncher.retainPanelAfterClose) panelRequested = false
    }
    Loader {
        id: loader
        anchors.fill: parent
        active: root.panelRequested
        visible: root.visible
        asynchronous: Config.AppLauncher.asynchronousPanelLoad
        sourceComponent: AppPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            onClosed: AppState.open = false
        }
    }
}

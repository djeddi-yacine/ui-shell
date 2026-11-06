pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as Controls
import "../../config" as Config

PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property AudioPanel panel: loader.status === Loader.Ready ? loader.item as AudioPanel : null
    property bool panelRequested: false
    screen: modelData
    visible: AudioState.open && AudioState.screenName === modelData.name
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-audio-control"
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
        asynchronous: Config.Audio.asynchronousPanelLoad
        sourceComponent: AudioPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            open: root.visible
            onClosed: AudioState.open = false
        }
    }
}

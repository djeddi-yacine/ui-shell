pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components" as Controls
import "../../config" as Config

// Full-output overlay like the other pickers: the dimmed backdrop takes the
// pointer, and a click on it leaves the same way Esc does.
PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property TuningPanel panel: loader.status === Loader.Ready ? loader.item as TuningPanel : null
    property bool panelRequested: false
    screen: modelData
    visible: TuningState.open && TuningState.screenName === modelData.name
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-control-tuning"
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
        asynchronous: Config.Tuning.asynchronousPanelLoad
        sourceComponent: TuningPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            onClosed: TuningState.open = false
        }
    }
}

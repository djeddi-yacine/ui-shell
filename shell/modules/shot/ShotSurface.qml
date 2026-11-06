pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config

PanelWindow {
    id: root
    required property var modelData
    required property Controls.InputState inputState
    readonly property ShotPanel panel: loader.status === Loader.Ready ? loader.item as ShotPanel : null
    property bool panelRequested: false
    screen: modelData
    readonly property bool shown: ShotPanelState.open && ShotPanelState.screenName === modelData.name
    // Hidden while the pointer selection runs and while the picture is taken; the panel keeps its choices.
    visible: shown && !Adapters.RecordState.picking && !ShotPanelState.capturing
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-shot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onShownChanged: if (shown) panelRequested = true
    Loader {
        id: loader
        anchors.fill: parent
        active: root.panelRequested
        visible: root.visible
        asynchronous: Config.Shot.asynchronousPanelLoad
        sourceComponent: ShotPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            open: root.shown
            onClosed: ShotPanelState.open = false
        }
    }
}

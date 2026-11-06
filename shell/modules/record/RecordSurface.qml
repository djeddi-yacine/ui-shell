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
    readonly property RecordPanel panel: loader.status === Loader.Ready ? loader.item as RecordPanel : null
    property bool panelRequested: false
    screen: modelData
    // The panel stays loaded (and keeps its choices) while the pointer selection hides its window.
    readonly property bool shown: RecordPanelState.open && RecordPanelState.screenName === modelData.name
    visible: shown && !Adapters.RecordState.picking
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-record"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onShownChanged: if (shown) panelRequested = true
    Loader {
        id: loader
        anchors.fill: parent
        active: root.panelRequested
        visible: root.visible
        asynchronous: Config.Record.asynchronousPanelLoad
        sourceComponent: RecordPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            open: root.shown
            onClosed: RecordPanelState.open = false
        }
    }
}

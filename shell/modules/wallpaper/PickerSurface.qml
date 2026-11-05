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
    readonly property PickerPanel panel: panelLoader.item as PickerPanel
    property bool panelRequested: false

    screen: modelData
    visible: PickerState.open && PickerState.screenName === modelData.name
    onVisibleChanged: {
        if (visible) {
            panelRequested = true
            if (panel)
                panel.activate()
        } else if (!Config.WallpaperPicker.retainPanelAfterClose) {
            panelRequested = false
        }
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "ui-shell-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Loader {
        id: panelLoader
        anchors.fill: parent
        active: root.panelRequested
        visible: root.visible
        asynchronous: Config.WallpaperPicker.asynchronousPanelLoad
        sourceComponent: PickerPanel {
            screenName: root.modelData.name
            inputState: root.inputState
            onClosed: PickerState.open = false
        }
    }
}

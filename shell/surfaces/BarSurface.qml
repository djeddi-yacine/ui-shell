import QtQuick
import Quickshell
import Quickshell.Wayland

import "../config" as ShellConfig
import "../modules/bar" as BarModule
import "../components" as Controls

PanelWindow {
    id: root

    property var modelData
    required property Controls.InputState inputState

    screen: modelData
    visible: ShellConfig.Config.barEnabled
    color: "transparent"
    implicitHeight: ShellConfig.Config.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    exclusionMode: visible ? ExclusionMode.Auto : ExclusionMode.Ignore
    exclusiveZone: visible ? implicitHeight : 0

    WlrLayershell.namespace: "ui-shell-bar"
    WlrLayershell.layer: WlrLayer.Top

    BarModule.Bar {
        anchors.fill: parent
        screenName: root.modelData.name
        inputState: root.inputState
    }
}

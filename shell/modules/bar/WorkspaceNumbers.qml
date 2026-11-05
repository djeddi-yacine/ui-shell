pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import "../../config" as ShellConfig
import "../../theme" as Theme
import "../../components" as Controls

RowLayout {
    id: root

    required property string screenName
    required property var style
    required property Controls.InputState inputState

    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(output => output.name === root.screenName) ?? null
    spacing: root.style.controlPaddingY

    Repeater {
        model: ShellConfig.Config.barWorkspaceNumbers

        Controls.ShellButton {
            id: workspaceButton

            required property int modelData
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.barEntryEmphasis
            Layout.fillHeight: true
            Layout.minimumWidth: root.style.controlHeight
            text: String(workspaceButton.modelData)
            current: root.monitor?.activeWorkspace?.name === workspaceButton.text
            enabled: root.monitor !== null
            Accessible.name: qsTr("Switch to workspace %1").arg(workspaceButton.modelData)
            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + workspaceButton.modelData + '" })')
        }
    }
}

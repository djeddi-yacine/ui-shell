import QtQuick
import QtQuick.Layouts

import "../../config" as ShellConfig
import "../../theme" as Theme
import "../wallpaper" as Wallpaper
import "../../components" as Controls
import "../apps" as Apps
import "../tuning" as Tuning
import "../audio" as Audio
import "../shot" as Shot

Item {
    id: root

    required property string screenName
    required property Controls.InputState inputState

    Controls.PointerTracker {
        inputState: root.inputState
    }

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.screenName)
        controlMode: ShellConfig.Config.barControlMode
    }

    Rectangle {
        anchors.fill: parent
        color: styleTokens.surface
        radius: styleTokens.surfaceRadius
        border.color: styleTokens.outline
        border.width: Theme.Shape.borderWidth

        RowLayout {
            anchors.fill: parent
            // Entries stay inside the bar's own outline instead of painting over it.
            anchors.topMargin: Theme.Shape.borderWidth
            anchors.bottomMargin: Theme.Shape.borderWidth
            anchors.leftMargin: styleTokens.spacing
            anchors.rightMargin: styleTokens.spacing

            Controls.ShellButton {
                visible: ShellConfig.Config.appLauncherEnabled
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.barEntryEmphasis
                Layout.fillHeight: true
                text: qsTr("Launcher")
                selected: Apps.AppState.open && Apps.AppState.screenName === root.screenName
                onClicked: Apps.AppState.show(root.screenName)
            }
            Controls.ShellButton {
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.barEntryEmphasis
                Layout.fillHeight: true
                text: qsTr("Wallpaper")
                selected: Wallpaper.PickerState.open && Wallpaper.PickerState.screenName === root.screenName
                Accessible.name: qsTr("Open wallpaper picker")
                onClicked: {
                    Wallpaper.PickerState.screenName = root.screenName
                    Wallpaper.PickerState.targetOutput = root.screenName
                    Wallpaper.PickerState.open = true
                }
            }

            PanelButton {
                visible: ShellConfig.Config.controlTuningEnabled
                text: qsTr("Tuning")
                panelState: Tuning.TuningState
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            PanelButton {
                visible: ShellConfig.Config.audioControlEnabled
                text: qsTr("Audio")
                panelState: Audio.AudioState
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            PanelButton {
                visible: ShellConfig.Config.screenShotEnabled
                text: qsTr("Screenshot")
                panelState: Shot.ShotPanelState
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            RecordButton {
                visible: ShellConfig.Config.screenRecordEnabled
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            MprisButton {
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            NotifChip {
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            AuthChip {
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            WorkspaceNumbers {
                visible: ShellConfig.Config.barWorkspacesEnabled
                screenName: root.screenName
                style: styleTokens
                inputState: root.inputState
                Layout.fillHeight: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.screenName
                color: styleTokens.textMuted
                font.pointSize: styleTokens.bodyPointSize
            }
        }
    }
}

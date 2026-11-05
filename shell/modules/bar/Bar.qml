import QtQuick
import QtQuick.Layouts

import "../../config" as ShellConfig
import "../../theme" as Theme
import "../wallpaper" as Wallpaper
import "../../components" as Controls
import "../apps" as Apps

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
                text: qsTr("Apps")
                selected: Apps.AppState.open && Apps.AppState.screenName === root.screenName
                onClicked: Apps.AppState.show(root.screenName)
            }
            Controls.ShellButton {
                style: styleTokens
                inputState: root.inputState
                emphasis: Theme.Interaction.barEntryEmphasis
                Layout.fillHeight: true
                text: ShellConfig.Config.barLabel
                selected: Wallpaper.PickerState.open && Wallpaper.PickerState.screenName === root.screenName
                Accessible.name: qsTr("Open wallpaper picker")
                onClicked: {
                    Wallpaper.PickerState.screenName = root.screenName
                    Wallpaper.PickerState.targetOutput = root.screenName
                    Wallpaper.PickerState.open = true
                }
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

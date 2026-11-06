pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "../auth" as Auth

// Shown only when the shell's authentication agent could not register, so a `pkexec` that
// shows no dialog is not a mystery. Hidden for a short grace period after start-up, while the
// agent is still registering.
Controls.ShellButton {
    id: root
    property bool graceOver: false
    visible: Config.Config.authEnabled && graceOver && !Auth.AuthState.auth.agentActive
    emphasis: Theme.Interaction.barEntryEmphasis
    text: qsTr("No auth agent")
    Accessible.name: qsTr("The authentication agent is not active, show why")
    onClicked: popup.visible = !popup.visible
    onVisibleChanged: if (!visible) popup.visible = false
    Timer {
        interval: Config.Auth.startupGraceMs
        running: true
        onTriggered: root.graceOver = true
    }

    PopupWindow {
        id: popup
        visible: false
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        anchor {
            item: root
            edges: Edges.Bottom | Edges.Left
            gravity: Edges.Bottom | Edges.Right
        }
        Rectangle {
            id: card
            implicitWidth: Config.Auth.cardWidth
            implicitHeight: note.implicitHeight + root.style.cardPadding * 2
            color: root.style.popupSurface
            radius: root.style.popupRadius
            border.width: Theme.Shape.borderWidth
            border.color: root.style.popupBorder
            Text {
                id: note
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: root.style.cardPadding }
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: qsTr("Another authentication agent, usually hyprpolkitagent, already holds this session, so ui-shell cannot show password requests. Stop that agent, then restart the shell.")
                color: root.style.text
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
        }
    }
}

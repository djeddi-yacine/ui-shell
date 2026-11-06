pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "../record" as Record

// The recording domain's bar entry. Idle, it opens the recording panel. While a recording
// runs it shows the elapsed time, and clicking opens a small popup with the state and Stop.
Controls.ShellButton {
    id: root
    required property string screenName
    readonly property bool recording: Adapters.RecordState.active
    emphasis: Theme.Interaction.barEntryEmphasis
    // The clock slot has a fixed width so the bar does not shift when a recording starts or a
    // minute turns over.
    Layout.minimumWidth: (Adapters.RecordState.picking ? implicitWidth : clockMetrics.width + leftPadding + rightPadding)
    TextMetrics { id: clockMetrics; font: root.font; text: "● 00:00" }
    // While the pointer selection runs, every screen is covered by it: say what to do, here, where
    // the user is looking for a way out.
    text: Adapters.RecordState.picking ? qsTr("Drag a region · Esc cancels")
        : !recording ? qsTr("Rec")
        : Adapters.RecordState.state === "starting" ? (Adapters.RecordState.remaining > 0 ? "● " + Adapters.RecordState.remaining : "● …")
        : "● " + Adapters.RecordState.clock(Adapters.RecordState.elapsed)
    selected: recording || (Record.RecordPanelState.open && Record.RecordPanelState.screenName === screenName)
    Accessible.name: recording ? qsTr("Recording, show controls") : qsTr("Record the screen")

    onClicked: {
        if (recording) popup.visible = !popup.visible
        else Record.RecordPanelState.show(screenName)
    }
    onRecordingChanged: if (!recording) popup.visible = false

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
            implicitWidth: layout.implicitWidth + root.style.cardPadding * 2
            implicitHeight: layout.implicitHeight + root.style.cardPadding * 2
            color: root.style.popupSurface
            radius: root.style.popupRadius
            border.width: Theme.Shape.borderWidth
            border.color: root.style.popupBorder
            ColumnLayout {
                id: layout
                anchors.centerIn: parent
                spacing: root.style.spacingTight
                Text {
                    text: Adapters.RecordState.state === "starting"
                        ? (Adapters.RecordState.remaining > 0 ? qsTr("Starting in %1 s").arg(Adapters.RecordState.remaining) : qsTr("Starting…"))
                        : qsTr("Recording  %1").arg(Adapters.RecordState.clock(Adapters.RecordState.elapsed))
                    color: root.style.text
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.bodyPointSize
                    font.weight: root.style.emphasisWeight
                }
                Text {
                    text: (Adapters.RecordState.recorded.target ?? "").replace("monitor:", "")
                        + ((Adapters.RecordState.recorded.audio ?? []).includes("desktop") ? "  ·  " + (Adapters.RecordState.recorded.desktopSource ?? qsTr("desktop audio")) : "  ·  " + qsTr("no sound"))
                        + ((Adapters.RecordState.recorded.audio ?? []).includes("mic") ? "  ·  " + (Adapters.RecordState.recorded.micSource ?? qsTr("microphone")) : "")
                    color: root.style.textMuted
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.captionPointSize
                }
                Text {
                    visible: (Adapters.RecordState.recorded.warnings ?? []).length > 0
                    Layout.maximumWidth: Config.Record.popupTextMaximumWidth
                    wrapMode: Text.Wrap
                    text: (Adapters.RecordState.recorded.warnings ?? []).join("\n")
                    color: root.style.warning
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.captionPointSize
                }
                Controls.ShellButton {
                    Layout.fillWidth: true
                    text: Adapters.RecordState.state === "starting" ? qsTr("Cancel") : qsTr("Stop")
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.primaryActionEmphasis
                    onClicked: { Adapters.RecordState.stop(); popup.visible = false }
                }
            }
        }
    }
}

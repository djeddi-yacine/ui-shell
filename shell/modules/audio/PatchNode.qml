pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../theme" as Theme
import "PatchLogic.js" as Logic

// One node of the patchbay: an application, a device or a stream, with a socket on
// the side its links leave from (sources, right edge) or arrive at (destinations,
// left edge). The socket only shows state; clicking the node is how you link.
Controls.ShellButton {
    id: root
    required property var node
    required property bool isSource
    property bool cursor: false
    property int linkCount: 0

    focusPolicy: Qt.NoFocus
    text: node.label
    // Outlined at rest, like the reference graphs' nodes.
    emphasis: Theme.Interaction.selectorEmphasis
    keyboardCandidate: cursor
    Accessible.name: qsTr("%1, %2 links").arg(node.label).arg(linkCount)
    implicitHeight: 54
    topPadding: 6
    bottomPadding: 6

    contentItem: RowLayout {
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.node.label
                color: root.style.text
                elide: Text.ElideRight
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.node.detail.length > 0 ? root.node.detail : Logic.kindLabel(root.node.class)
                color: root.style.textMuted
                elide: Text.ElideRight
                font.family: root.style.monoFamily
                font.pointSize: root.style.captionPointSize
            }
        }
        Text {
            visible: root.linkCount > 0
            text: root.linkCount
            color: root.style.controls.muted
            font.family: root.style.monoFamily
            font.pointSize: root.style.captionPointSize
        }
    }

    // The socket sits on the card's edge and lights up when the node has links.
    Rectangle {
        width: 12; height: 12
        x: root.isSource ? root.width - width / 2 : -width / 2
        y: (root.height - height) / 2
        color: root.linkCount > 0 ? root.style.controls.primary : root.style.surface
        border.width: Theme.Shape.borderWidth
        border.color: root.linkCount > 0 ? root.style.controls.primary : root.style.controls.outline
    }
}

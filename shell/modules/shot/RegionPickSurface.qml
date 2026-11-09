pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../adapters" as Adapters
import "../../config" as Config
import "../../theme" as Theme

// The region picker overlay, one per screen. Press and drag to draw a rectangle: the rest of the
// screen dims, the rectangle gets a thick border with round handles, and a cord hangs from each
// screen corner to the matching corner of the selection and swings as you move (the look of
// zephyr's geom picker). The drag stays on the screen it started on. Release picks, Esc or a right
// click cancels, and a click without a drag selects nothing.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    visible: Adapters.RecordState.regionPicking
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-region-pick"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.modelData.name) }
    readonly property bool owner: Adapters.RecordState.regionDragging && Adapters.RecordState.regionScreen === modelData.name
    // The selection in this screen's own coordinates.
    readonly property real left: Math.min(Adapters.RecordState.regionFrom.x, Adapters.RecordState.regionTo.x)
    readonly property real top: Math.min(Adapters.RecordState.regionFrom.y, Adapters.RecordState.regionTo.y)
    readonly property real right: Math.max(Adapters.RecordState.regionFrom.x, Adapters.RecordState.regionTo.x)
    readonly property real bottom: Math.max(Adapters.RecordState.regionFrom.y, Adapters.RecordState.regionTo.y)
    readonly property int border: Config.RegionPick.borderWidth
    readonly property color dim: styleTokens.scrimColor(Config.RegionPick.dimOpacity)

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Adapters.RecordState.finishRegionPick("")

        // Before a drag, the whole screen is dim; during one, four bands leave the selection clear.
        Rectangle { visible: !root.owner; anchors.fill: parent; color: root.dim }
        Rectangle { visible: root.owner; x: 0; y: 0; width: parent.width; height: root.top; color: root.dim }
        Rectangle { visible: root.owner; x: 0; y: root.bottom; width: parent.width; height: parent.height - root.bottom; color: root.dim }
        Rectangle { visible: root.owner; x: 0; y: root.top; width: root.left; height: root.bottom - root.top; color: root.dim }
        Rectangle { visible: root.owner; x: root.right; y: root.top; width: parent.width - root.right; height: root.bottom - root.top; color: root.dim }

        Cords {
            anchors.fill: parent
            active: root.owner
            color: styleTokens.accent
            lineWidth: root.border
            from: [Qt.point(0, 0), Qt.point(width, 0), Qt.point(0, height), Qt.point(width, height)]
            to: [Qt.point(root.left, root.top), Qt.point(root.right, root.top), Qt.point(root.left, root.bottom), Qt.point(root.right, root.bottom)]
        }
        Rectangle {
            visible: root.owner
            x: root.left - root.border / 2; y: root.top - root.border / 2
            width: root.right - root.left + root.border; height: root.bottom - root.top + root.border
            color: "transparent"
            border.width: root.border
            border.color: styleTokens.accent
        }
        Repeater {
            model: root.owner ? [[root.left, root.top], [root.right, root.top], [root.left, root.bottom], [root.right, root.bottom]] : []
            Rectangle {
                required property var modelData
                width: Config.RegionPick.handleSize; height: width; radius: width / 2
                x: modelData[0] - width / 2; y: modelData[1] - height / 2
                color: styleTokens.accent
            }
        }
        Text {
            visible: root.owner && root.right - root.left > 0
            x: root.left; y: Math.max(0, root.top - height - root.border * 2 - Config.RegionPick.handleSize / 2)
            text: Math.round(root.right - root.left) + " × " + Math.round(root.bottom - root.top)
            color: styleTokens.text
            font.family: styleTokens.uiFamily
            font.pointSize: styleTokens.bodyPointSize
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) { Adapters.RecordState.finishRegionPick(""); return }
                Adapters.RecordState.regionScreen = root.modelData.name
                Adapters.RecordState.regionFrom = Qt.point(mouse.x, mouse.y)
                Adapters.RecordState.regionTo = Qt.point(mouse.x, mouse.y)
                Adapters.RecordState.regionDragging = true
            }
            onPositionChanged: mouse => {
                if (!root.owner) return
                Adapters.RecordState.regionTo = Qt.point(Math.max(0, Math.min(width, mouse.x)), Math.max(0, Math.min(height, mouse.y)))
            }
            onReleased: mouse => {
                if (!root.owner) return
                const width = Math.round(root.right - root.left), height = Math.round(root.bottom - root.top)
                if (width < 2 || height < 2) { Adapters.RecordState.finishRegionPick(""); return }
                Adapters.RecordState.finishRegionPick(width + "x" + height + "+" + Math.round(root.modelData.x + root.left) + "+" + Math.round(root.modelData.y + root.top))
            }
        }
    }
}

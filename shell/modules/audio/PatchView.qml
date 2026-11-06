pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "PatchLogic.js" as Logic

// The patchbay: sources on the left, destinations on the right, joined by curved links.
// Two modes, like a modal editor. Normal: nothing is selected. Click a node to enter
// link mode with it; the next click on a node of the other side links the two (or
// unlinks them if they were linked) and returns to normal mode. Clicking the same node,
// or Esc, leaves link mode without acting; a node on the same side takes over as the
// linking node. Either side can come first. Keyboard: arrows move, Return does what a
// click does, X removes the links of the node under the cursor.
// Layout is automatic, so no node positions are stored.
FocusScope {
    id: root
    required property var style
    required property Controls.InputState inputState
    required property var graph
    // The selected node and which column it is in.
    property int selectedId: -1
    property bool selectedIsSource: true
    property int cursorColumn: 0
    property int cursorRow: 0
    signal connectRequested(int out, int into)
    signal disconnectRequested(int out, int into)
    signal disconnectNodeRequested(int node, bool isSource)

    readonly property var parts: Logic.split(graph.nodes ?? [], graph.ports ?? [], graph.links ?? [])
    readonly property var sources: parts.sources
    readonly property var destinations: parts.destinations
    readonly property var edgeList: Logic.edges(graph.links ?? [], sources, destinations)
    // The layout's numbers, all from the theme and Config.Audio.
    readonly property var metrics: ({ row: style.rowHeight, gap: Config.Audio.patchGap,
        pullMinimum: Config.Audio.linkPullMinimum, pullMaximum: Config.Audio.linkPullMaximum, pullFraction: Config.Audio.linkPullFraction })
    readonly property real columnWidth: Math.max(Config.Audio.patchColumnMinimum, Math.min(Config.Audio.patchColumnMaximum, width * Config.Audio.patchColumnFraction))
    readonly property real leftSocket: columnWidth
    readonly property real rightSocket: width - columnWidth
    readonly property int rows: Math.max(sources.length, destinations.length, 1)
    implicitHeight: rows * Logic.step(metrics) - metrics.gap

    // What a click on a node does, from the selection: select it, deselect it, or link
    // it with the selected node on the other side.
    function activate(id, isSource) {
        if (selectedId < 0 || selectedIsSource === isSource) {
            if (selectedId === id && selectedIsSource === isSource) selectedId = -1
            else { selectedId = id; selectedIsSource = isSource }
            return
        }
        const out = isSource ? id : selectedId
        const into = isSource ? selectedId : id
        selectedId = -1   // the action ends link mode
        if (Logic.linked(edgeList, out, into)) disconnectRequested(out, into)
        else connectRequested(out, into)
    }
    function linkCountOf(id) { return edgeList.filter(edge => edge.out === id || edge.in === id).length }
    function touchesSelection(edge) {
        return selectedId >= 0 && (selectedIsSource ? edge.out === selectedId : edge.in === selectedId)
    }

    Keys.onPressed: event => {
        inputState.keyboardUsed()
        if (event.key === Config.Keyboard.cancelKey && selectedId >= 0) { selectedId = -1; event.accepted = true; return }
        const list = cursorColumn === 0 ? sources : destinations
        if (event.key === Qt.Key_Down) cursorRow = Math.min(list.length - 1, cursorRow + 1)
        else if (event.key === Qt.Key_Up) cursorRow = Math.max(0, cursorRow - 1)
        else if (event.key === Qt.Key_Right && destinations.length > 0) { cursorColumn = 1; cursorRow = Math.min(cursorRow, destinations.length - 1) }
        else if (event.key === Qt.Key_Left && sources.length > 0) { cursorColumn = 0; cursorRow = Math.min(cursorRow, sources.length - 1) }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (cursorRow < list.length) activate(list[cursorRow].id, cursorColumn === 0)
        } else if ((event.key === Qt.Key_X || event.key === Qt.Key_Delete) && cursorRow < list.length)
            disconnectNodeRequested(list[cursorRow].id, cursorColumn === 0)
        else return
        event.accepted = true
    }

    Repeater {
        model: root.edgeList
        Shape {
            id: link
            required property var modelData
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property var points: Logic.controlPoints(root.metrics, root.leftSocket, Logic.rowCenter(root.metrics, modelData.from), root.rightSocket, Logic.rowCenter(root.metrics, modelData.to))
            readonly property bool active: root.touchesSelection(modelData)
            ShapePath {
                fillColor: "transparent"
                strokeWidth: Theme.Shape.borderWidth * (link.active ? 3 : 2)
                strokeColor: link.active ? root.style.controls.primary : root.style.restingLink
                capStyle: ShapePath.RoundCap
                startX: root.leftSocket
                startY: Logic.rowCenter(root.metrics, link.modelData.from)
                PathCubic {
                    x: root.rightSocket
                    y: Logic.rowCenter(root.metrics, link.modelData.to)
                    control1X: link.points.c1x; control1Y: link.points.c1y
                    control2X: link.points.c2x; control2Y: link.points.c2y
                }
            }
        }
    }

    Repeater {
        model: root.sources
        PatchNode {
            required property var modelData
            required property int index
            x: 0
            y: Logic.rowTop(root.metrics, index)
            width: root.columnWidth
            height: root.metrics.row
            node: modelData
            isSource: true
            style: root.style
            inputState: root.inputState
            selected: root.selectedIsSource && modelData.id === root.selectedId
            cursor: root.activeFocus && root.cursorColumn === 0 && root.cursorRow === index
            linkCount: root.linkCountOf(modelData.id)
            onClicked: { root.cursorColumn = 0; root.cursorRow = index; root.activate(modelData.id, true); root.forceActiveFocus() }
        }
    }
    Repeater {
        model: root.destinations
        PatchNode {
            required property var modelData
            required property int index
            x: root.width - root.columnWidth
            y: Logic.rowTop(root.metrics, index)
            width: root.columnWidth
            height: root.metrics.row
            node: modelData
            isSource: false
            style: root.style
            inputState: root.inputState
            selected: !root.selectedIsSource && modelData.id === root.selectedId
            cursor: root.activeFocus && root.cursorColumn === 1 && root.cursorRow === index
            linkCount: root.linkCountOf(modelData.id)
            onClicked: { root.cursorColumn = 1; root.cursorRow = index; root.activate(modelData.id, false); root.forceActiveFocus() }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: root.sources.length === 0 && root.destinations.length === 0
        text: qsTr("No audio nodes.")
        color: root.style.textMuted
        font.family: root.style.uiFamily
        font.pointSize: root.style.bodyPointSize
    }
}

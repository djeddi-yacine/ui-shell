pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../adapters" as Adapters
import "../../config" as Config
import "../../theme" as Theme

// The window picker overlay, one per screen: dims the screen and outlines the windows shown now.
// The list is polled live (Adapters.RecordState.pickableWindows), so switching workspace or opening a
// window while it is up works. Click or Enter picks, Tab and the arrows move, Esc or a right click cancels.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    visible: Adapters.RecordState.windowPicking
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "ui-shell-window-pick"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var style: styleTokens
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.modelData.name) }
    readonly property var windows: Adapters.RecordState.pickableWindows
    // Screen-local rectangle of a window (window coordinates are global layout coordinates).
    function inside(entry) { return entry.x < modelData.x + width && entry.x + entry.width > modelData.x && entry.y < modelData.y + height && entry.y + entry.height > modelData.y }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            const key = event.key
            if (key === Qt.Key_Escape) Adapters.RecordState.finishWindowPick("")
            else if (key === Qt.Key_Return || key === Qt.Key_Enter) Adapters.RecordState.finishWindowPick(Adapters.RecordState.hoveredWindow || Adapters.RecordState.pickableWindows[0]?.address || "")
            else if (key === Qt.Key_Tab || key === Qt.Key_Right || key === Qt.Key_Down) Adapters.RecordState.stepHovered(1)
            else if (key === Qt.Key_Backtab || key === Qt.Key_Left || key === Qt.Key_Up) Adapters.RecordState.stepHovered(-1)
            else return
            event.accepted = true
        }
        Rectangle { anchors.fill: parent; color: root.style.scrimColor(Config.ContextPanels.scrimOpacity) }
        Repeater {
            model: root.windows
            Rectangle {
                id: box
                required property var modelData
                readonly property bool hovered: modelData.address === Adapters.RecordState.hoveredWindow
                visible: root.inside(modelData)
                x: modelData.x - root.modelData.x
                y: modelData.y - root.modelData.y
                width: modelData.width
                height: modelData.height
                color: hovered ? Qt.rgba(root.style.accent.r, root.style.accent.g, root.style.accent.b, 0.22) : "transparent"
                border.width: hovered ? 3 : 1
                border.color: hovered ? root.style.accent : root.style.pickerBorder
                Text {
                    visible: box.hovered
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, implicitWidth)
                    elide: Text.ElideRight
                    text: box.modelData.title || box.modelData.class
                    color: root.style.text
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.bodyPointSize
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPositionChanged: mouse => {
                const gx = mouse.x + root.modelData.x, gy = mouse.y + root.modelData.y
                const hit = Adapters.RecordState.pickableWindows.find(entry => gx >= entry.x && gx < entry.x + entry.width && gy >= entry.y && gy < entry.y + entry.height)
                Adapters.RecordState.hoveredWindow = hit ? hit.address : ""
            }
            onClicked: mouse => Adapters.RecordState.finishWindowPick(mouse.button === Qt.RightButton ? "" : Adapters.RecordState.hoveredWindow)
        }
    }
}

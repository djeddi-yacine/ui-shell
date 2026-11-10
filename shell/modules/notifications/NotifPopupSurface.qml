pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../config" as Config
import "../../theme" as Theme

// One popup window per screen, mapped only on the focused monitor while a notification is
// shown. It never takes keyboard focus, and its input region is the card only.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    readonly property bool onFocusedMonitor: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
    readonly property bool wanted: NotifCenter.popup !== null && onFocusedMonitor
    // Keep the last entry while the card fades out.
    property var shown: null
    readonly property var blank: ({ appName: "", tag: "", summary: "", body: "", progress: -1, actions: [] })
    onWantedChanged: if (wanted) shown = NotifCenter.popup
    Connections {
        target: NotifCenter
        function onPopupChanged() { if (NotifCenter.popup && root.onFocusedMonitor) root.shown = NotifCenter.popup }
    }
    visible: wanted || card.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: Config.Notifications.popupMargin; right: Config.Notifications.popupMargin }
    implicitWidth: Config.Notifications.popupWidth
    implicitHeight: card.height
    mask: Region { item: card }
    WlrLayershell.namespace: Config.Notifications.popupNamespace
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.modelData.name)
    }

    Rectangle {
        id: card
        width: parent.width
        // Height is capped, never left to the text.
        height: Math.min(content.implicitHeight + 2 * styleTokens.spacingTight * 2, Config.Notifications.popupMaxHeight)
        clip: true
        radius: styleTokens.popupRadius
        color: styleTokens.popupSurface
        border.color: root.shown && root.shown.urgency === "critical" ? styleTokens.negative : styleTokens.popupBorder
        opacity: root.wanted ? 1 : 0
        scale: root.wanted ? 1 : Theme.Motion.panelEnterScale
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: root.wanted ? Theme.Motion.popupInDuration : Theme.Motion.popupOutDuration } }
        Behavior on scale { NumberAnimation { duration: root.wanted ? Theme.Motion.popupInDuration : Theme.Motion.popupOutDuration } }

        HoverHandler { onHoveredChanged: NotifCenter.popupHovered = hovered }
        // A click anywhere on the card dismisses it.
        TapHandler { acceptedButtons: Qt.LeftButton | Qt.MiddleButton; onTapped: { if (NotifCenter.popup) NotifCenter.invokeDefault(NotifCenter.popup.id); NotifCenter.dismissPopup() } }

        NotifCard {
            id: content
            anchors { fill: parent; margins: styleTokens.spacingTight * 2 }
            entry: root.shown ?? root.blank
            style: styleTokens
        }
    }
}

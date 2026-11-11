import QtQuick
import "../../theme" as Theme
import "../../config" as Config

// One tab per app with a waiting request, shown only while two or more apps wait; the strip
// grows and fades in when the second app arrives and back out when it is the only one left.
Item {
    id: root
    required property var style
    // The apps as { name, count }, and the one shown.
    required property var apps
    required property string current
    signal picked(string name)

    readonly property bool wanted: apps.length > 1
    property real reveal: wanted ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: Theme.Motion.active ? Theme.Motion.listMoveDuration : 0; easing.type: Theme.Motion.listMoveEasing } }
    implicitHeight: Config.Menu.tabHeight * reveal
    opacity: reveal
    visible: reveal > 0
    clip: true

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        height: Config.Menu.tabHeight
        spacing: Config.Menu.tabSpacing
        Repeater {
            model: root.apps
            delegate: Rectangle {
                id: tab
                required property var modelData
                readonly property bool active: modelData.name === root.current
                objectName: "menuTab"
                height: Config.Menu.tabHeight
                width: label.implicitWidth + root.style.controlPaddingX * 2
                radius: root.style.pickerRadius
                color: active ? root.style.pickerSurface : "transparent"
                border.width: Theme.Shape.borderWidth
                border.color: active ? root.style.pickerBorder : root.style.rule
                Text {
                    id: label
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: tab.modelData.count > 1 ? tab.modelData.name + " · " + tab.modelData.count : tab.modelData.name
                    color: tab.active ? root.style.text : root.style.textMuted
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.bodyPointSize
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(tab.modelData.name)
                }
            }
        }
    }
}

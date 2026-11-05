import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config

Item {
    id: root
    required property var entry
    required property var style
    required property Controls.InputState inputState
    required property bool selected
    required property bool candidateVisible
    required property bool keyboardCandidate
    required property bool launching
    property bool showIcon: Config.AppLauncher.showIcons
    property bool pooled: false
    readonly property bool launchPulseRunning: pulse.running
    objectName: "appEntryRow"
    signal chosen()
    signal activated()
    // The list owns keyboard focus, including when delegates are reused.
    activeFocusOnTab: false
    // Item views can assign currentItem focus even to non-Tab delegates.
    onFocusChanged: { if (focus) focus = false }
    implicitHeight: Config.AppLauncher.rowHeight
    Accessible.role: Accessible.Button
    Accessible.name: entry.name
    Accessible.description: launching ? qsTr("Starting %1…").arg(entry.name) : entry.genericName
    ListView.onPooled: pooled = true
    ListView.onReused: pooled = false
    Controls.ShellControlState {
        id: visual
        style: root.style
        emphasis: Theme.Interaction.selectorOptionEmphasis
        enabled: root.enabled
        // Keep the launch candidate visible while search owns text focus.
        selected: root.selected && root.candidateVisible
        // Scrollable candidates are keyboard-owned; pointer movement must not add a second highlight.
        hovered: false
        pressed: pointer.pressed
        focused: root.selected && root.keyboardCandidate
    }
    Controls.ShellControlBackground {
        objectName: "appEntryBackground"
        anchors.fill: parent
        controlState: visual
        border.color: Config.AppLauncher.showRowOutlines || visual.focused ? visual.border : "transparent"
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.style.controlPaddingX
        anchors.rightMargin: root.style.controlPaddingX
        anchors.topMargin: Config.AppLauncher.rowPaddingY
        anchors.bottomMargin: Config.AppLauncher.rowPaddingY
        spacing: Config.AppLauncher.rowContentSpacing
        Image {
            objectName: "appEntryIcon"
            visible: root.showIcon
            Layout.preferredWidth: Config.AppLauncher.iconSize
            Layout.preferredHeight: Config.AppLauncher.iconSize
            source: visible ? Quickshell.iconPath(root.entry.icon, Config.AppLauncher.defaultIcon) : ""
            sourceSize.width: Config.AppLauncher.iconSize
            sourceSize.height: Config.AppLauncher.iconSize
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            Accessible.ignored: true
        }
        Text {
            objectName: "appEntryLabel"
            Layout.fillWidth: true
            text: root.entry.name
            color: visual.foreground
            font.family: root.style.uiFamily
            font.pointSize: root.style.bodyPointSize
            font.weight: root.style.bodyWeight
            elide: Text.ElideRight
        }
        // Keep this slot in the layout even when its indicator is hidden.
        Item {
            Layout.preferredWidth: Config.AppLauncher.launchIndicatorSize
            Layout.preferredHeight: Config.AppLauncher.launchIndicatorSize
            BusyIndicator {
                id: progress
                objectName: "appLaunchIndicator"
                anchors.fill: parent
                visible: root.launching
                running: root.launching
                padding: 0
                focusPolicy: Qt.NoFocus
                Accessible.name: qsTr("Starting %1…").arg(root.entry.name)
                contentItem: Rectangle {
                    id: dot
                    radius: width / 2
                    color: root.style.controls.text
                    antialiasing: true
                    opacity: Theme.Motion.launchPulseMaximumOpacity
                    Accessible.ignored: true
                }
                SequentialAnimation {
                    id: pulse
                    running: Theme.Motion.active && progress.visible && !root.pooled
                        && (!root.ListView.view || (root.y + root.height > root.ListView.view.contentY
                            && root.y < root.ListView.view.contentY + root.ListView.view.height))
                    loops: Animation.Infinite
                    onStopped: dot.opacity = Qt.binding(() => Theme.Motion.launchPulseMaximumOpacity)
                    OpacityAnimator {
                        target: dot
                        from: Theme.Motion.launchPulseMaximumOpacity
                        to: Theme.Motion.launchPulseMinimumOpacity
                        duration: Theme.Motion.launchPulseDuration
                        easing.type: Theme.Motion.launchPulseEasing
                    }
                    OpacityAnimator {
                        target: dot
                        from: Theme.Motion.launchPulseMinimumOpacity
                        to: Theme.Motion.launchPulseMaximumOpacity
                        duration: Theme.Motion.launchPulseDuration
                        easing.type: Theme.Motion.launchPulseEasing
                    }
                }
            }
        }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.inputState.pointerUsed()
        onClicked: { root.chosen(); root.activated() }
    }
    Controls.PointerTracker { inputState: root.inputState; enabled: root.enabled }
    Accessible.onPressAction: { root.chosen(); root.activated() }
}

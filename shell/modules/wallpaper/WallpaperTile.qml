import QtQuick
import QtQuick.Layouts

import "../../theme" as Theme
import "../../config" as ShellConfig
import "../../components" as Controls

Item {
    id: root

    required property var wallpaper
    required property bool selected
    required property bool current
    required property bool keyboardCandidate
    required property var style
    required property Controls.InputState inputState

    // Whether the pointer hover is being shown (the pointer is the active input and over the tile).
    readonly property bool hoverShown: visual.pointerHover
    signal chosen()
    signal activated()

    implicitWidth: ShellConfig.WallpaperPicker.tileWidth
    implicitHeight: ShellConfig.WallpaperPicker.tileHeight
    // The grid owns keyboard focus; tiles never enter the native Tab chain.
    activeFocusOnTab: false
    // Qt may focus currentItem implicitly; only the grid owns that focus.
    onFocusChanged: { if (focus) focus = false }
    Accessible.role: Accessible.Button
    Accessible.name: wallpaper.name
    Accessible.description: root.current ? qsTr("Currently applied wallpaper") : qsTr("Choose wallpaper")

    Controls.ShellControlState {
        id: visual
        style: root.style
        emphasis: Theme.Interaction.wallpaperTileEmphasis
        enabled: root.enabled
        // The keyboard owns the selection; the pointer only hovers (a different colour) and never
        // selects until it clicks. The shared input state drops hover while the keyboard is in use.
        hovered: root.inputState.pointerActive && pointer.containsMouse
        pressed: pointer.pressed
        selected: root.selected && root.keyboardCandidate
        focused: root.selected && root.keyboardCandidate
        current: root.current
    }

    Controls.ShellControlBackground {
        anchors.fill: parent
        controlState: visual

        Image {
            id: preview

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: ShellConfig.WallpaperPicker.tileInset
            }
            height: ShellConfig.WallpaperPicker.previewDisplayHeight
            source: root.wallpaper.path
            sourceSize.width: ShellConfig.WallpaperPicker.previewWidth
            sourceSize.height: ShellConfig.WallpaperPicker.previewHeight
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            cache: true
            Accessible.ignored: true
            Text {
                anchors.centerIn: parent
                visible: preview.status === Image.Error
                text: qsTr("Preview unavailable")
                color: root.style.textMuted
                font.pointSize: root.style.captionPointSize
            }
        }

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: ShellConfig.WallpaperPicker.tileInset
            }
            spacing: ShellConfig.WallpaperPicker.tileLabelGap
            Text {
                objectName: "wallpaperName"
                Layout.fillWidth: true
                text: root.wallpaper.name
                color: visual.foreground
                font.family: root.style.uiFamily
                font.pointSize: root.style.captionPointSize
                font.weight: root.style.bodyWeight
                elide: Text.ElideMiddle
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: captionMetrics.height
                spacing: ShellConfig.WallpaperPicker.tileInset
                Rectangle {
                    visible: root.current
                    Layout.preferredWidth: ShellConfig.WallpaperPicker.statusMarkerSize
                    Layout.preferredHeight: ShellConfig.WallpaperPicker.statusMarkerSize
                    color: visual.markerColor
                    Accessible.ignored: true
                }
                Text {
                    visible: root.current
                    text: qsTr("In use")
                    color: visual.mutedForeground
                    font.pointSize: root.style.captionPointSize
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    FontMetrics {
        id: captionMetrics
        font.family: root.style.uiFamily
        font.pointSize: root.style.captionPointSize
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.inputState.pointerUsed()
        onClicked: root.chosen()
    }

    Controls.PointerTracker {
        inputState: root.inputState
        enabled: root.enabled
    }

    Accessible.onPressAction: root.activated()
}

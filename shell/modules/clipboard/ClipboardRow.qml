import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../theme" as Theme
import "../../config" as Config

// One history entry: a short kind badge and one line of what was copied.
Item {
    id: root
    required property var entry
    required property var style
    required property Controls.InputState inputState
    required property bool selected
    required property bool candidateVisible
    required property bool keyboardCandidate
    objectName: "clipboardEntryRow"
    readonly property string badge: {
        switch (entry.kind) {
        case "file": return qsTr("File")
        case "image": return qsTr("Image")
        case "binary": return qsTr("Data")
        default: return qsTr("Text")
        }
    }
    // What the row says. Text and file entries show the copied text itself; pictures and other
    // binary data show what the preview line states about them.
    readonly property string label: {
        const details = [entry.type, entry.width && entry.height ? entry.width + "×" + entry.height : null, entry.size]
            .filter(part => part)
        if (entry.kind === "image") return qsTr("Picture") + (details.length ? " · " + details.join(" · ") : "")
        if (entry.kind === "binary") return qsTr("Binary data") + (details.length ? " · " + details.join(" · ") : "")
        return entry.text
    }
    readonly property bool hoverShown: visual.pointerHover
    signal chosen()
    signal activated()
    signal previewRequested()
    activeFocusOnTab: false
    onFocusChanged: { if (focus) focus = false }
    implicitHeight: Config.Clipboard.rowHeight
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: badge
    Controls.ShellControlState {
        id: visual
        style: root.style
        emphasis: Theme.Interaction.selectorOptionEmphasis
        enabled: root.enabled
        selected: root.selected && root.candidateVisible
        hovered: root.inputState.pointerActive && pointer.containsMouse
        pressed: pointer.pressed
        focused: root.selected && root.keyboardCandidate
    }
    Controls.ShellControlBackground {
        anchors.fill: parent
        controlState: visual
        border.color: visual.focused ? visual.border : "transparent"
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.style.controlPaddingX
        anchors.rightMargin: root.style.controlPaddingX
        anchors.topMargin: Config.Clipboard.rowPaddingY
        anchors.bottomMargin: Config.Clipboard.rowPaddingY
        spacing: Config.Clipboard.rowContentSpacing
        Text {
            objectName: "clipboardEntryBadge"
            Layout.preferredWidth: Config.Clipboard.badgeSize * 2
            text: root.badge
            color: root.style.textMuted
            font.family: root.style.uiFamily
            font.pointSize: root.style.bodyPointSize
            elide: Text.ElideRight
            Accessible.ignored: true
        }
        Text {
            objectName: "clipboardEntryLabel"
            Layout.fillWidth: true
            text: root.label
            textFormat: Text.PlainText
            maximumLineCount: 1
            color: visual.foreground
            font.family: root.style.uiFamily
            font.pointSize: root.style.bodyPointSize
            font.weight: root.style.bodyWeight
            elide: Text.ElideRight
        }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: root.inputState.pointerUsed()
        onClicked: function(mouse) {
            root.chosen()
            if (mouse.button === Qt.RightButton) root.previewRequested()
            else root.activated()
        }
    }
    Controls.PointerTracker { inputState: root.inputState; enabled: root.enabled }
    Accessible.onPressAction: { root.chosen(); root.activated() }
}

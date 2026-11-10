pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme
import "NotifMarkup.js" as Markup

// One notification: shared by the popup (read-only) and the drawer (with actions).
ColumnLayout {
    id: root
    required property var entry
    required property var style
    property var inputState: null
    property bool showActions: false
    // Drawer only: the delete button and the image placeholder. Popups have neither.
    property bool interactive: false
    signal actionInvoked(string identifier)
    signal deleteRequested()
    signal readToggled()
    signal imageRequested()
    spacing: style.spacingTight
    // Redacted text is never created, so nothing can leak through size or a hidden Text.
    readonly property bool redacted: NotifCenter.redact && root.entry.reveal !== true
    FontMetrics { id: metrics }
    readonly property color spoilerTint: Qt.alpha(style.text, 0.35)
    readonly property bool unread: !entry.read
    // The urgency colour: what the dot, and a critical card's border, are drawn in.
    readonly property color urgencyColor: entry.urgency === "critical" ? style.negative
        : entry.urgency === "low" ? style.textMuted : style.accent
    // Read cards recede; unread ones are drawn in the full text colour.
    readonly property color bodyColor: unread ? style.text : style.textMuted

    RowLayout {
        Layout.fillWidth: true
        spacing: root.style.spacingTight
        Rectangle {
            visible: root.unread
            Layout.preferredWidth: Config.Notifications.unreadDotSize
            Layout.preferredHeight: Config.Notifications.unreadDotSize
            radius: width / 2
            color: root.urgencyColor
        }
        Text {
            Layout.fillWidth: true
            text: root.entry.appName + (root.entry.category ? "  ·  " + root.entry.category.split(".")[0] : "")
                + (root.entry.tag ? "  ·  " + root.entry.tag : "")
            color: root.style.textMuted
            elide: Text.ElideRight
        }
        // Created only in the drawer: popups have no controls.
        Loader {
            active: root.interactive
            visible: active
            Layout.preferredWidth: Config.Notifications.iconButtonSize
            Layout.preferredHeight: Config.Notifications.iconButtonSize
            sourceComponent: Controls.ShellIconButton {
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                glyph: "check"
                label: root.unread ? qsTr("Mark as read") : qsTr("Mark as unread")
                iconSize: Config.Notifications.iconGlyphSize
                selected: !root.unread
                onClicked: root.readToggled()
            }
        }
        Loader {
            active: root.interactive
            visible: active
            Layout.preferredWidth: Config.Notifications.iconButtonSize
            Layout.preferredHeight: Config.Notifications.iconButtonSize
            sourceComponent: Controls.ShellIconButton {
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                glyph: "close"
                label: qsTr("Delete notification")
                iconSize: Config.Notifications.iconGlyphSize
                onClicked: root.deleteRequested()
            }
        }
    }
    NotifSpoiler {
        Layout.fillWidth: true
        Layout.preferredHeight: metrics.height
        visible: root.redacted
        tint: root.spoilerTint
    }
    NotifSpoiler {
        Layout.fillWidth: true
        Layout.preferredHeight: metrics.height * 2
        visible: root.redacted && root.entry.body !== ""
        tint: root.spoilerTint
    }
    Text {
        Layout.fillWidth: true
        visible: !root.redacted
        text: root.redacted ? "" : root.entry.summary
        color: root.style.text
        font.bold: root.unread
        wrapMode: Text.Wrap
        maximumLineCount: Config.Notifications.summaryMaxLines
        elide: Text.ElideRight
    }
    Text {
        Layout.fillWidth: true
        visible: !root.redacted && text !== ""
        text: root.redacted ? "" : Markup.toStyled(root.entry.body)
        color: root.bodyColor
        linkColor: root.style.accent
        textFormat: Text.StyledText
        onLinkActivated: link => { if (Markup.openable(link)) Qt.openUrlExternally(link) }
        wrapMode: Text.Wrap
        maximumLineCount: Config.Notifications.bodyMaxLines
        elide: Text.ElideRight
    }
    // An image never loads by itself: a fixed-size button stands in until the owner asks for it.
    Loader {
        active: root.interactive && !root.redacted && root.entry.image !== "" && !root.entry.imageLoaded
        visible: active
        Layout.fillWidth: true
        Layout.preferredHeight: Config.Notifications.imageButtonHeight
        sourceComponent: Controls.ShellButton {
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            text: qsTr("Load image")
            onClicked: root.imageRequested()
        }
    }
    Item {
        visible: root.interactive && !root.redacted && root.entry.image !== "" && root.entry.imageLoaded
        Layout.preferredWidth: Config.Notifications.imageSlotSize
        Layout.preferredHeight: Config.Notifications.imageSlotSize
        Image {
            anchors.fill: parent
            // Created only after the owner asked, so no decoding happens before.
            source: parent.visible ? root.entry.image : ""
            sourceSize: Qt.size(Config.Notifications.imageSlotSize, Config.Notifications.imageSlotSize)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
        }
    }
    Rectangle {
        Layout.fillWidth: true
        visible: root.entry.progress >= 0
        implicitHeight: 4
        radius: 2
        color: root.style.surfaceVariant
        Rectangle {
            width: parent.width * root.entry.progress / 100
            height: parent.height
            radius: 2
            color: root.style.accent
        }
    }
    Flow {
        Layout.fillWidth: true
        visible: !root.redacted && root.showActions && NotifCenter.buttonActions(root.entry).length > 0
        spacing: root.style.spacingTight
        Repeater {
            model: root.showActions && !root.redacted && !root.entry.actionIcons ? NotifCenter.buttonActions(root.entry) : []
            Controls.ShellButton {
                required property var modelData
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                text: modelData.text
                onClicked: root.actionInvoked(modelData.identifier)
            }
        }
        // action-icons: the identifier is an icon name, and the text only names it for accessibility.
        Repeater {
            model: root.showActions && !root.redacted && root.entry.actionIcons ? NotifCenter.buttonActions(root.entry) : []
            Controls.ShellButton {
                id: iconAction
                required property var modelData
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: modelData.text
                leftPadding: 0
                rightPadding: 0
                implicitWidth: Config.Notifications.iconButtonSize
                contentItem: Image {
                    source: "image://icon/" + iconAction.modelData.identifier
                    sourceSize: Qt.size(Config.Notifications.iconGlyphSize, Config.Notifications.iconGlyphSize)
                    fillMode: Image.PreserveAspectFit
                }
                onClicked: root.actionInvoked(modelData.identifier)
            }
        }
    }
}

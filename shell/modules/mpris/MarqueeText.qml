import QtQuick
import QtQuick.Controls.Basic
import "../../config" as Config
import "../../theme" as Theme

// One line of text of a fixed height. When it is wider than its space it scrolls to the end and
// back, like an old car player, so the layout never changes size with the text. With motion off
// (or while not running) it is cut with an ellipsis instead. The animation runs only while
// `running` and the text overflows.
Item {
    id: root
    property string text: ""
    required property color color
    property font font
    property bool running: true
    readonly property real overflow: Math.max(0, metrics.advanceWidth - width)
    readonly property bool animated: running && overflow > 0 && Theme.Motion.active
    implicitHeight: metrics.height
    clip: true

    TextMetrics { id: metrics; font: root.font; text: root.text }

    Text {
        id: label
        objectName: "marqueeLabel"
        text: root.text
        textFormat: Text.PlainText
        font: root.font
        color: root.color
        elide: root.animated ? Text.ElideNone : Text.ElideRight
        width: root.animated ? metrics.advanceWidth : root.width
        height: root.height
        verticalAlignment: Text.AlignVCenter
    }

    SequentialAnimation {
        id: scroll
        running: root.animated
        loops: Animation.Infinite
        PauseAnimation { duration: Config.Mpris.marqueePauseMs }
        NumberAnimation { target: label; property: "x"; from: 0; to: -root.overflow; duration: Math.max(1, root.overflow / Config.Mpris.marqueeSpeed * 1000) }
        PauseAnimation { duration: Config.Mpris.marqueePauseMs }
        NumberAnimation { target: label; property: "x"; from: -root.overflow; to: 0; duration: Math.max(1, root.overflow / Config.Mpris.marqueeSpeed * 1000) }
        onRunningChanged: if (!running) label.x = 0
    }
    onTextChanged: { scroll.restart(); label.x = 0 }
}

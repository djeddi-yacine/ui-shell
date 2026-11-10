import QtQuick
import "../../config" as Config

// Moving noise that hides one block of text. Size never depends on the hidden text.
Item {
    id: root
    required property color tint
    property url shaderSource: Qt.resolvedUrl("shaders/spoiler.frag.qsb")
    property real time: 0

    NumberAnimation on time {
        from: 0
        to: 1000
        duration: 1000000 / Config.Notifications.spoilerSpeed
        loops: Animation.Infinite
        running: root.visible && effect.status !== ShaderEffect.Error
    }
    // Shown when the compiled shader is missing, so redaction still hides the area.
    Rectangle {
        anchors.fill: parent
        visible: effect.status === ShaderEffect.Error
        color: root.tint
        radius: 2
    }
    ShaderEffect {
        id: effect
        anchors.fill: parent
        visible: status !== ShaderEffect.Error
        property real time: root.time
        property real ratio: root.width / Math.max(1, root.height)
        property color tint: root.tint
        fragmentShader: root.shaderSource
    }
}

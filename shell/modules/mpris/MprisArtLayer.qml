import QtQuick
import "../../config" as Config

// One picture of the art backdrop. The backdrop decides when it fades; this only holds the
// picture and animates its opacity. The picture is always a local file made by the art script,
// decoded at a capped size so an 8000 px cover cannot use hundreds of megabytes.
Image {
    id: root
    property string path: ""
    property string pictureKind: ""
    property int fadeMs: 0
    // The picture has loaded and can be shown.
    signal loaded()
    // A fade has run to its end.
    signal faded()
    // A file that cannot be loaded (pruned or deleted since it was made).
    signal lost(string path)
    anchors.fill: parent
    source: path.length > 0 ? "file://" + path : ""
    sourceSize: Qt.size(Config.Mpris.artSourceSize, Config.Mpris.artSourceSize)
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    smooth: pictureKind === "blurhash"
    opacity: 0
    visible: opacity > 0

    // Fade to `value`. The time is in proportion to the distance still to go, so a fade that
    // starts part way keeps the same speed; with no fade time it just jumps.
    function fadeTo(value) {
        fade.stop()
        if (fadeMs <= 0 || opacity === value) { opacity = value; faded(); return }
        fade.to = value
        fade.duration = Math.round(fadeMs * Math.abs(value - opacity))
        fade.start()
    }
    function snapTo(value) { fade.stop(); opacity = value }
    NumberAnimation {
        id: fade
        target: root
        property: "opacity"
        easing.type: Easing.InOutQuad
        onFinished: root.faded()
    }
    onStatusChanged: {
        if (status === Image.Ready) loaded()
        else if (status === Image.Error && path.length > 0) lost(path)
    }
}

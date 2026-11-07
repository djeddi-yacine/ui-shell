import QtQuick
import QtQuick.Effects

// A picture from shell/icons (filled white), tinted with a theme colour so it follows the theme.
// It is rendered at exactly its size in device pixels and, when `centered`, placed on whole
// pixels, so its edges stay sharp (a picture drawn larger and scaled down, or placed half a pixel
// off, goes soft). The tint needs a GPU renderer: the offscreen tests draw it untinted, so they
// check `name`.
Image {
    id: root
    // The file name in shell/icons, without the extension.
    required property string name
    required property color color
    property real size: 16
    // Centre in the parent on whole pixels.
    property bool centered: false
    readonly property real pixelRatio: Screen.devicePixelRatio
    width: size
    height: size
    source: Qt.resolvedUrl("../../icons/" + name + ".svg")
    sourceSize: Qt.size(Math.round(size * pixelRatio), Math.round(size * pixelRatio))
    fillMode: Image.PreserveAspectFit
    mipmap: false
    layer.enabled: true
    layer.effect: MultiEffect { colorization: 1; colorizationColor: root.color }
    Binding on x { when: root.centered && root.parent; value: Math.round((root.parent.width - root.width) / 2) }
    Binding on y { when: root.centered && root.parent; value: Math.round((root.parent.height - root.height) / 2) }
}

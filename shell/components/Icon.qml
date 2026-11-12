import QtQuick

// A picture from shell/icons: a generated QML shape (tools/scripts/generate-icons turns shell/svg/*.svg
// into them), drawn in `color` so it follows the theme. It is vector all the way, so it needs no
// effect or GPU-only tint, and it is placed on whole pixels when `centered` so its strokes stay crisp.
Item {
    id: root
    // The SVG's file name in shell/svg, without the extension.
    required property string name
    required property color color
    property real size: 16
    // Centre in the parent on whole pixels.
    property bool centered: false
    readonly property bool ready: loader.status === Loader.Ready
    width: size
    height: size

    Loader {
        id: loader
        anchors.fill: parent
        source: Qt.resolvedUrl("../icons/" + root.name.split("-").map(p => p.charAt(0).toUpperCase() + p.slice(1)).join("") + ".qml")
    }
    Binding { target: loader.item; property: "color"; value: root.color; when: root.ready }
    Binding on x { when: root.centered && root.parent; value: Math.round((root.parent.width - root.width) / 2) }
    Binding on y { when: root.centered && root.parent; value: Math.round((root.parent.height - root.height) / 2) }
}

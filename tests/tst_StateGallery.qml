import QtQuick
import QtTest
import "../shell/theme" as Theme
import "theme-fixtures" as Fixtures

// Renders every imported palette through the real ControlState and saves a
// PNG contact sheet (rows: emphasis x state) for human review of the colour
// system: build/tests/gallery/state-gallery.png in the artifacts directory.
Item {
    id: root
    width: 10 * 190 + 20
    height: 2 * (14 * 34 + 40) + 20
    Fixtures.ImportedPalettes { id: fixtures }
    readonly property var states: ["normal", "hover", "focus", "select", "current", "pressed", "disabled"]

    Flow {
        x: 10; y: 10; spacing: 10; width: root.width - 20
        Repeater {
            model: fixtures.items
            Rectangle {
                id: card
                required property var modelData
                width: 180
                height: 14 * 34 + 40
                color: modelData.background
                readonly property Theme.ControlColors colors: Theme.ControlColors { palette: card.modelData }
                Column {
                    x: 6; y: 6; spacing: 4
                    Text { text: card.modelData.tag; color: card.colors.text; font.pixelSize: 12 }
                    Repeater {
                        model: ["outline", "solid"]
                        Column {
                            id: block
                            required property string modelData
                            spacing: 4
                            Repeater {
                                model: root.states
                                Rectangle {
                                    id: cell
                                    required property string modelData
                                    Theme.ControlState {
                                        id: visual
                                        colors: card.colors
                                        emphasis: block.modelData
                                        enabled: cell.modelData !== "disabled"
                                        hovered: cell.modelData === "hover"
                                        focused: cell.modelData === "focus"
                                        selected: cell.modelData === "select"
                                        current: cell.modelData === "current"
                                        pressed: cell.modelData === "pressed"
                                    }
                                    width: 168; height: 30
                                    color: visual.fill
                                    border.width: 2
                                    border.color: visual.border
                                    Text {
                                        anchors.left: parent.left; anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: block.modelData + " " + cell.modelData
                                        color: visual.foreground
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        anchors.right: parent.right; anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "muted"
                                        color: visual.mutedForeground
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    TestCase {
        name: "StateGallery"
        when: windowShown
        function test_saveContactSheet() {
            wait(200)
            const path = "/artifacts/build/tests/gallery/state-gallery.png"
            let saved = false
            verify(root.grabToImage(result => { saved = result.saveToFile(path) }), "grab started")
            tryVerify(() => saved, 5000, "gallery saved to " + path)
        }
    }
}

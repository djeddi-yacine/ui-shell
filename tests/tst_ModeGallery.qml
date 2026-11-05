import QtQuick
import QtTest
import "../shell/theme" as Theme
import "theme-fixtures" as Fixtures

// Contact sheet of the control modes: three palettes x every mode x outline and
// solid states, saved as mode-gallery.png for human review.
Item {
    id: root
    width: 6 * 150 + 20
    height: 3 * (12 * 28 + 36) + 20
    Fixtures.ImportedPalettes { id: fixtures }
    readonly property var picks: [0, 1, 8]
    readonly property var rows: [["outline", "normal"], ["outline", "hover"], ["outline", "focus"], ["outline", "select"],
        ["outline", "current"], ["outline", "pressed"], ["outline", "disabled"], ["solid", "normal"], ["solid", "hover"],
        ["solid", "focus"], ["solid", "pressed"], ["flat", "select"]]

    Flow {
        x: 10; y: 10; spacing: 8; width: root.width - 20
        Repeater {
            model: root.picks.length * Theme.ControlTuning.modes.length
            Rectangle {
                id: card
                required property int index
                readonly property var palette: fixtures.items[root.picks[Math.floor(index / Theme.ControlTuning.modes.length)]]
                readonly property var mode: Theme.ControlTuning.modes[index % Theme.ControlTuning.modes.length]
                width: 142; height: 12 * 28 + 28
                color: palette.background
                // Each card gets its own model: unsaved preset values via per-style tuning.
                readonly property Theme.ControlColors colors: Theme.ControlColors {
                    palette: card.palette
                    tuning: card.mode.values
                }
                Column {
                    x: 4; y: 4; spacing: 2
                    Text { text: card.palette.tag.split("-")[0] + " · " + card.mode.key; color: card.colors.text; font.pixelSize: 11 }
                    Repeater {
                        model: root.rows
                        Rectangle {
                            id: cell
                            required property var modelData
                            Theme.ControlState {
                                id: visual
                                colors: card.colors
                                behavior: card.mode.behavior
                                emphasis: cell.modelData[0]
                                enabled: cell.modelData[1] !== "disabled"
                                hovered: cell.modelData[1] === "hover"
                                focused: cell.modelData[1] === "focus"
                                selected: cell.modelData[1] === "select"
                                current: cell.modelData[1] === "current"
                                pressed: cell.modelData[1] === "pressed"
                            }
                            width: 134; height: 24
                            color: visual.fill
                            border.width: 1
                            border.color: visual.border
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: cell.modelData[0] + " " + cell.modelData[1]
                                color: visual.foreground
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
    TestCase {
        name: "ModeGallery"
        when: windowShown
        function test_saveSheet() {
            wait(200)
            let saved = false
            verify(root.grabToImage(result => { saved = result.saveToFile("/artifacts/build/tests/gallery/mode-gallery.png") }))
            tryVerify(() => saved, 5000)
        }
    }
}

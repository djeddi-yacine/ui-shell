import QtQuick
import QtTest

import "../shell/tests/wallpaper" as Wallpaper
import "../shell/components" as Controls
import "../shell/theme" as Theme

Item {
    id: root
    width: 520
    height: 240

    property int candidateIndex: 0
    property bool ownerActive: false
    Keys.onPressed: event => {
        tileInput.keyboardUsed()
        if (event.key === Qt.Key_Right) {
            root.candidateIndex = Math.min(root.wallpapers.length - 1, root.candidateIndex + 1)
            root.ownerActive = true
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Theme.Style.background
    }

    QtObject {
        id: firstWallpaper
        readonly property string name: "First wallpaper"
        readonly property string path: ""
    }

    QtObject {
        id: secondWallpaper
        readonly property string name: "Second wallpaper"
        readonly property string path: ""
    }

    property var wallpapers: [firstWallpaper, secondWallpaper]

    Controls.InputState {
        id: tileInput
        pointerActive: false
    }

    Controls.PointerTracker {
        inputState: tileInput
    }

    Component {
        id: firstTileComponent
        Wallpaper.WallpaperTile {
            x: 20
            width: 180
            height: 168
            wallpaper: firstWallpaper
            selected: root.candidateIndex === 0
            current: false
            keyboardCandidate: root.ownerActive
            style: Theme.Style
            inputState: tileInput
            onChosen: {
                root.candidateIndex = 0
                root.ownerActive = true
                root.forceActiveFocus()
            }
        }
    }

    Component {
        id: secondTileComponent
        Wallpaper.WallpaperTile {
            x: 260
            width: 180
            height: 168
            wallpaper: secondWallpaper
            selected: root.candidateIndex === 1
            current: true
            keyboardCandidate: root.ownerActive
            style: Theme.Style
            inputState: tileInput
            onChosen: {
                root.candidateIndex = 1
                root.ownerActive = true
                root.forceActiveFocus()
            }
        }
    }

    Component {
        id: ownerGridComponent
        GridView {
            id: ownerGrid
            y: root.height - height
            width: 200
            height: 100
            cellWidth: 100
            cellHeight: 100
            model: root.wallpapers
            activeFocusOnTab: true
            onActiveFocusChanged: root.ownerActive = activeFocus
            keyNavigationEnabled: false
            currentIndex: root.candidateIndex
            delegate: Wallpaper.WallpaperTile {
                required property int index
                required property var modelData
                width: ownerGrid.cellWidth
                height: ownerGrid.cellHeight
                wallpaper: modelData
                selected: index === root.candidateIndex
                current: index === 1
                keyboardCandidate: ownerGrid.activeFocus
                style: Theme.Style
                inputState: tileInput
                onChosen: {
                    root.candidateIndex = index
                    ownerGrid.forceActiveFocus()
                }
            }
            Keys.onReturnPressed: event => {
                if (currentItem)
                    currentItem.activated()
                event.accepted = true
            }
        }
    }

    Component {
        id: externalTabComponent
        Item {
            x: 460
            width: 40
            height: 40
            activeFocusOnTab: true
        }
    }

    TestCase {
        name: "WallpaperTile"
        when: windowShown

        SignalSpy {
            id: firstChosenSpy
            signalName: "chosen"
        }
        SignalSpy {
            id: secondChosenSpy
            signalName: "chosen"
        }
        SignalSpy {
            id: activatedSpy
            signalName: "activated"
        }

        function init() {
            root.candidateIndex = 0
            root.ownerActive = false
            mouseMove(root, root.width - 8, root.height - 8)
            tileInput.keyboardUsed()
        }

        function colorsNear(actual, expected) {
            return Math.abs(actual.r * 255 - expected.r * 255) <= 2
                && Math.abs(actual.g * 255 - expected.g * 255) <= 2
                && Math.abs(actual.b * 255 - expected.b * 255) <= 2
        }

        function test_itemTypographyDoesNotChangeWithState() {
            const tile = createTemporaryObject(firstTileComponent, root)
            verify(!!tile, "Component exists")
            const label = findChild(tile, "wallpaperName")
            verify(!!label, "Wallpaper name exists")
            compare(label.font.weight, Theme.Style.bodyWeight)
            root.candidateIndex = 1
            tryCompare(tile, "selected", false)
            compare(label.font.weight, Theme.Style.bodyWeight)
            tile.current = true
            compare(label.font.weight, Theme.Style.bodyWeight)
            mouseMove(tile, tile.width / 2, tile.height / 2)
            mouseMove(tile, tile.width / 2 + 1, tile.height / 2)
            tryCompare(tileInput, "pointerActive", true)
            compare(label.font.weight, Theme.Style.bodyWeight)
            root.ownerActive = true
            tryCompare(tile, "keyboardCandidate", true)
            compare(label.font.weight, Theme.Style.bodyWeight)
            root.ownerActive = false
            tryCompare(tile, "selected", false)
            compare(label.font.weight, Theme.Style.bodyWeight)
        }

        function test_mouseChoosesOnceAndParentOwnsFocus() {
            const first = createTemporaryObject(firstTileComponent, root)
            verify(!!first, "Component exists")
            firstChosenSpy.target = first
            firstChosenSpy.clear()

            mouseClick(first, first.width / 2, first.height / 2)

            tryCompare(firstChosenSpy, "count", 1)
            tryCompare(first, "activeFocus", false)
            tryCompare(root, "activeFocus", true)
            tryCompare(root, "ownerActive", true)
            tryCompare(root, "candidateIndex", 0)
            const label = findChild(first, "wallpaperName")
            verify(colorsNear(label.color, Theme.Style.controls.selectionText), "pointer click did not select the tile")
        }

        function test_tabLeavesAndReturnsToOwnerWithoutChangingCandidate() {
            const first = createTemporaryObject(firstTileComponent, root)
            verify(!!first, "Component exists")
            const second = createTemporaryObject(secondTileComponent, root)
            verify(!!second, "Component exists")
            const firstLabel = findChild(first, "wallpaperName")
            const secondLabel = findChild(second, "wallpaperName")
            firstChosenSpy.target = first
            firstChosenSpy.clear()
            secondChosenSpy.target = second
            secondChosenSpy.clear()

            const owner = createTemporaryObject(ownerGridComponent, root)
            verify(!!owner, "Grid owner exists")
            const externalTab = createTemporaryObject(externalTabComponent, root)
            verify(!!externalTab, "External Tab control exists")
            owner.KeyNavigation.tab = externalTab
            externalTab.KeyNavigation.backtab = owner

            root.ownerActive = false
            root.forceActiveFocus()
            owner.forceActiveFocus()
            keyClick(Qt.Key_Tab)
            tryCompare(externalTab, "activeFocus", true)
            compare(root.candidateIndex, 0)
            compare(first.activeFocus, false)
            compare(second.activeFocus, false)
            compare(firstChosenSpy.count, 0)
            compare(secondChosenSpy.count, 0)
            compare(first.keyboardCandidate, false)

            keyClick(Qt.Key_Backtab)
            tryCompare(owner, "activeFocus", true)
            compare(root.candidateIndex, 0)
            compare(first.activeFocus, false)
            compare(second.activeFocus, false)
            compare(first.keyboardCandidate, true)
            verify(colorsNear(firstLabel.color, Theme.Style.controls.selectionText), "returning to the grid lost its candidate")

            root.candidateIndex = 1
            root.ownerActive = true
            verify(colorsNear(firstLabel.color, Theme.Style.controls.text), "old wallpaper candidate remained selected")
            verify(colorsNear(secondLabel.color, Theme.Style.controls.selectionText), "new wallpaper candidate was not selected")

            compare(first.x, 20)
            compare(second.x, 260)
            compare(first.width, 180)
            compare(second.width, 180)
        }

        function test_pointerMovementKeepsSelectionKeyboardOwned() {
            root.ownerActive = true
            root.forceActiveFocus()
            const first = createTemporaryObject(firstTileComponent, root)
            const second = createTemporaryObject(secondTileComponent, root)
            verify(!!first, "First tile exists")
            verify(!!second, "Component exists")
            const firstLabel = findChild(first, "wallpaperName")
            const secondLabel = findChild(second, "wallpaperName")
            verify(colorsNear(firstLabel.color, Theme.Style.controls.selectionText), "keyboard candidate color missing")
            verify(colorsNear(secondLabel.color, Theme.Style.controls.currentText), "current wallpaper color missing")
            mouseMove(root, second.x + second.width / 2, second.y + second.height / 2)
            mouseMove(root, second.x + second.width / 2 + 1, second.y + second.height / 2)
            tryCompare(tileInput, "pointerActive", true)
            compare(root.candidateIndex, 0)
            verify(colorsNear(firstLabel.color, Theme.Style.controls.selectionText), "pointer movement displaced keyboard candidate")
            verify(colorsNear(secondLabel.color, Theme.Style.controls.currentText), "pointer movement changed current wallpaper state")

            keyClick(Qt.Key_Right)
            tryCompare(tileInput, "pointerActive", false)
            compare(root.candidateIndex, 1)
            verify(colorsNear(firstLabel.color, Theme.Style.controls.text), "previous candidate remained selected")
            verify(colorsNear(secondLabel.color, Theme.Style.controls.selectionText), "arrow key did not advance selection")
        }

        function test_enterActivatesOnce() {
            const first = createTemporaryObject(firstTileComponent, root)
            verify(!!first, "Component exists")
            activatedSpy.target = first
            activatedSpy.clear()
            const owner = createTemporaryObject(ownerGridComponent, root)
            verify(!!owner, "Grid owner exists")
            activatedSpy.target = owner.currentItem
            activatedSpy.clear()
            owner.forceActiveFocus()
            keyClick(Qt.Key_Return)

            tryCompare(activatedSpy, "count", 1)
        }
    }
}

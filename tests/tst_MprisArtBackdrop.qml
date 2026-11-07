import QtQuick
import QtQuick.Window
import QtTest
import "../shell/tests/mpris" as Shell
import "../shell/theme" as Theme

// The art backdrop's fade: a new picture fades in over the old one, the old one stays opaque
// until the new one is complete (the surface never shows through), and no art fades out.
Item {
    id: root
    width: 200
    height: 200
    readonly property string red: Qt.resolvedUrl("mpris/pixel-red.png").toString().replace("file://", "")
    readonly property string blue: Qt.resolvedUrl("mpris/pixel-blue.png").toString().replace("file://", "")
    Component {
        id: backdropComponent
        Shell.MprisArtBackdrop {
            anchors.fill: parent
            style: Theme.Style
            art: ({ state: "none", kind: "", path: "" })
        }
    }
    TestCase {
        name: "MprisArtBackdrop"
        when: windowShown

        function make() { return createTemporaryObject(backdropComponent, root) }
        function layers(b) { return [b.front, b.other(b.front)] }
        function covered(b) { return Math.max(layers(b)[0].opacity, layers(b)[1].opacity) }

        function test_nothingShowsWithoutArt() {
            const b = make()
            compare(covered(b), 0)
        }
        function test_aNewPictureFadesInAndEndsFullyOpaque() {
            const b = make()
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            compare(b.other(b.front).opacity, 0)
        }
        function test_aChangeNeverLetsTheSurfaceShowThrough() {
            const b = make()
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            const first = b.front
            b.art = { state: "ready", kind: "cover", path: root.blue }
            let lowest = 1
            for (let i = 0; i < 40; i++) { lowest = Math.min(lowest, covered(b)); wait(15) }
            compare(lowest, 1, "the old picture must stay opaque until the new one is in")
            tryCompare(b.front, "opacity", 1, 3000)
            verify(b.front !== first)
            tryCompare(first, "opacity", 0, 3000)
            compare(first.path, "")
        }
        function test_noArtFadesTheOldPictureOutAndReleasesIt() {
            const b = make()
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            const shown = b.front
            b.art = { state: "none", kind: "", path: "" }
            tryCompare(shown, "opacity", 0, 3000)
            tryCompare(shown, "path", "", 3000)
        }
        function test_theSamePictureAgainDoesNotFlicker() {
            const b = make()
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            b.art = { state: "none", kind: "", path: "" }
            wait(40)
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            compare(b.front.path, root.red)
        }
        function test_aPictureThatCannotBeLoadedIsReported() {
            const b = make()
            const lost = []
            b.pictureLost.connect(path => lost.push(path))
            b.art = { state: "ready", kind: "cover", path: "/no/such/picture.png" }
            tryVerify(() => lost.length > 0, 3000)
            compare(lost[0], "/no/such/picture.png")
        }
        function test_theDimLayerIsPermanentAndStrong() {
            const b = make()
            const dim = findChild(b, "dim")
            // There before any art, with art, while art changes, and after it is gone.
            compare(dim.opacity, 1)
            verify(dim.visible && dim.color.a > 0.5, "the dim layer must be strong enough to dim the art")
            b.art = { state: "ready", kind: "cover", path: root.red }
            for (let i = 0; i < 10; i++) { compare(dim.opacity, 1); wait(15) }
            b.art = { state: "ready", kind: "cover", path: root.blue }
            for (let i = 0; i < 10; i++) { compare(dim.opacity, 1); wait(15) }
            b.art = { state: "none", kind: "", path: "" }
            for (let i = 0; i < 10; i++) { compare(dim.opacity, 1); wait(15) }
        }
        function test_theDimLayerIsAboveBothPicturesWhateverTheirOrder() {
            const b = make()
            const dim = findChild(b, "dim")
            b.art = { state: "ready", kind: "cover", path: root.red }
            tryCompare(b.front, "opacity", 1, 3000)
            b.art = { state: "ready", kind: "cover", path: root.blue }
            tryCompare(b.front, "opacity", 1, 3000)
            verify(dim.z > b.front.z && dim.z > b.other(b.front).z, "the dim must paint above the pictures")
        }
    }
}

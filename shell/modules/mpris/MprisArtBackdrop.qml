import QtQuick
import "../../config" as Config
import "../../theme" as Theme

// The art behind the title: a local picture under a scrim that keeps the text readable, or
// nothing at all (the card's own surface shows) when there is no art.
//
// Changes fade smoothly. Two layers alternate. A new picture waits, invisible, until it has
// loaded, then fades in ON TOP of the old one, which stays fully opaque underneath until the new
// one is complete; only then is the old one dropped. So the card's own surface never shows
// through in the middle of a change. With no art the picture fades out onto the surface. With
// motion off everything just changes.
Item {
    id: root
    required property var art
    required property var style
    // A picture that could not be loaded; the adapter forgets it and makes it again.
    signal pictureLost(string path)
    readonly property string wanted: art.state === "ready" && art.path.length > 0 ? art.path : ""
    readonly property int fadeMs: Theme.Motion.active ? Config.Mpris.artFadeMs : 0
    // The layer that shows (or is about to show) `wanted`, and the one waiting to fade in.
    property var front: layerA
    property var pending: null

    function other(layer) { return layer === layerA ? layerB : layerA }
    function show() {
        const old = front
        pending = null
        if (wanted.length === 0) {
            // No art: fade what is shown out onto the surface.
            other(old).snapTo(0)
            old.fadeTo(0)
            return
        }
        if (old.path === wanted) {
            // The same picture again (for example while it was fading out): bring it back.
            other(old).snapTo(0)
            old.fadeTo(1)
            return
        }
        const next = other(old)
        next.snapTo(0)
        next.path = wanted
        next.pictureKind = art.kind
        next.z = 2
        old.z = 1
        front = next
        pending = next
        if (next.status === Image.Ready) reveal(next)
    }
    function reveal(layer) {
        if (pending !== layer) return
        pending = null
        layer.fadeTo(1)
    }
    // A layer finished fading: when the front one is fully in, the old one underneath is dropped;
    // when the front one is fully out, its picture is released.
    function settled(layer) {
        if (layer !== front) return
        if (layer.opacity === 1) { const under = other(layer); under.snapTo(0); under.path = "" }
        else if (layer.opacity === 0 && wanted.length === 0) layer.path = ""
    }
    onWantedChanged: show()
    Component.onCompleted: if (wanted.length > 0) show()

    MprisArtLayer {
        id: layerA
        fadeMs: root.fadeMs
        onLoaded: root.reveal(layerA)
        onFaded: root.settled(layerA)
        onLost: path => root.pictureLost(path)
    }
    MprisArtLayer {
        id: layerB
        fadeMs: root.fadeMs
        onLoaded: root.reveal(layerB)
        onFaded: root.settled(layerB)
        onLost: path => root.pictureLost(path)
    }
    // The dim layer over the art. It is permanent: always there at the same strength, with or
    // without a picture and while pictures change, so the card's brightness never jumps and a
    // strongly coloured cover is never shown at full brightness against the controls. Its strength
    // is `Config.Mpris.artScrimOpacity`.
    Rectangle {
        objectName: "dim"
        anchors.fill: parent
        // Above both pictures, whatever their z (they swap 1 and 2 while a change fades).
        z: 10
        color: root.style.scrimColor(Config.Mpris.artScrimOpacity)
    }
}

import QtQuick
import QtQuick.Window
import QtTest
import "mpris" as Fake
import "../shell/tests/mpris" as Shell
import "../shell/components" as Controls
import "../shell/theme" as Theme

// What the media card shows and what its keys do, with fake players and the real selection.
Item {
    id: root
    width: 520
    height: 560
    Controls.InputState { id: input; pointerActive: false }
    Component { id: playerComponent; Fake.FakePlayer {} }
    Component { id: sourceComponent; Fake.FakeSource {} }
    Component { id: selectionComponent; Shell.MediaSelection {} }
    Component {
        id: cardComponent
        Shell.MprisCard {
            width: 460
            style: Theme.Style
            inputState: input
            seekStep: 10
            art: ({ state: "none", kind: "", path: "" })
        }
    }
    TestCase {
        name: "MprisCard"
        when: windowShown
        function init() { root.Window.window.requestActivate(); tryCompare(root.Window.window, "active", true) }

        function player(entry, props) {
            return createTemporaryObject(playerComponent, root, Object.assign({ desktopEntry: entry, identity: entry, isPlaying: true }, props || {}))
        }
        function make(players) {
            const source = createTemporaryObject(sourceComponent, root, { players: players })
            const selection = createTemporaryObject(selectionComponent, root, { source: source })
            const card = createTemporaryObject(cardComponent, root, { selection: selection })
            verify(!!card)
            card.forceActiveFocus()
            return { source: source, selection: selection, card: card }
        }
        function texts(item, out) {
            if (item.text !== undefined && item.visible) out.push(String(item.text))
            for (let i = 0; i < item.children.length; i++) texts(item.children[i], out)
            return out
        }
        function shown(card) { return texts(card, []).join("|") }

        function test_nothingPlayingWithNoPlayer() {
            const t = make([])
            verify(shown(t.card).includes("Nothing playing"))
            compare(findChild(t.card, "seekRow").opacity, 0)
        }
        function test_titleFallsBackToTheIdentityAndAnEmptyArtistIsHidden() {
            const t = make([player("mpd", { trackTitle: "", trackArtist: "", identity: "Music Player Daemon" })])
            verify(shown(t.card).includes("Music Player Daemon"))
            verify(!shown(t.card).includes("An artist"))
        }
        function test_aTitleAndArtistAreShownAsPlainText() {
            const t = make([player("mpd", { trackTitle: "<b>Bold</b>", trackArtist: "Someone" })])
            verify(shown(t.card).includes("<b>Bold</b>"))
            verify(shown(t.card).includes("Someone"))
        }
        function test_aStreamHasALiveBarAndNoSlider() {
            const t = make([player("mpd", { lengthSupported: false })])
            compare(findChild(t.card, "seekSlider").visible, false)
            compare(findChild(t.card, "liveBar").visible, true)
            compare(findChild(t.card, "seekRow").opacity, 1)
            verify(shown(t.card).includes("LIVE"))
        }
        function test_aTrackHasASliderAndNoLiveBar() {
            const t = make([player("mpd")])
            compare(findChild(t.card, "seekSlider").visible, true)
            compare(findChild(t.card, "liveBar").visible, false)
            verify(!shown(t.card).includes("LIVE"))
        }
        function test_aStreamThatCannotReportItsPositionShowsNoTime() {
            const t = make([player("mpd", { lengthSupported: false, positionSupported: false })])
            verify(!shown(t.card).includes("0:30"))
        }
        function test_seekBarShownAndDisabledWhenTheCapabilityIsMissing() {
            const t = make([player("mpd", { canSeek: false })])
            compare(findChild(t.card, "seekRow").opacity, 1)
            compare(findChild(t.card, "seekSlider").enabled, false)
        }
        function test_spacePlaysAndPauses() {
            const p = player("mpd")
            const t = make([p])
            keyClick(Qt.Key_Space)
            compare(p.toggleCalls, 1)
        }
        function test_spaceOnAFocusedButtonPlaysAndDoesNotAlsoClickIt() {
            const p = player("mpd")
            const t = make([p])
            findChild(t.card, "nextButton").forceActiveFocus()
            keyClick(Qt.Key_Space)
            compare(p.toggleCalls, 1)
            compare(p.nextCalls, 0)
        }
        function test_nAndPSkip() {
            const p = player("mpd")
            const t = make([p])
            keyClick(Qt.Key_N)
            keyClick(Qt.Key_P)
            compare(p.nextCalls, 1)
            compare(p.previousCalls, 1)
        }
        function test_arrowsSeekByTheStepAndDoNothingWhenSeekingIsNotAllowed() {
            const p = player("mpd")
            const t = make([p])
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Left)
            compare(p.seeks.length, 2)
            compare(p.seeks[0], 10)
            compare(p.seeks[1], -10)
            p.canSeek = false
            keyClick(Qt.Key_Right)
            compare(p.seeks.length, 2)
        }
        function test_kPinsAndUnpins() {
            const t = make([player("mpd")])
            compare(t.selection.pinState, "none")
            compare(findChild(t.card, "pinButton").selected, false)
            keyClick(Qt.Key_K)
            compare(t.selection.pinState, "active")
            compare(findChild(t.card, "pinButton").selected, true)
            compare(t.card.pinLabel, "Unpin the player")
            keyClick(Qt.Key_K)
            compare(t.selection.pinState, "none")
            compare(t.card.pinLabel, "Pin this player")
        }
        function test_aPinWhoseNPlayerIsGoneIsStillShown() {
            const a = player("a"), b = player("b")
            const t = make([a, b])
            keyClick(Qt.Key_K)
            const key = t.selection.pinKey
            t.source.players = key === "a" ? [b] : [a]
            compare(t.selection.pinState, "absent")
            verify(t.card.pinLabel.includes("not running"))
        }
        function test_upAndDownShowTheOtherPlayers() {
            const a = player("a", { isPlaying: false }), b = player("b", { isPlaying: true })
            const t = make([a, b])
            compare(t.selection.current, b)
            keyClick(Qt.Key_Down)
            compare(t.selection.current, a)
            keyClick(Qt.Key_Up)
            compare(t.selection.current, b)
        }
        function test_theSelectorSwitchesPlayersAndIsOffWithOnePlayer() {
            const a = player("a", { isPlaying: false }), b = player("b", { isPlaying: true })
            const t = make([a])
            compare(findChild(t.card, "playerPreviousButton").enabled, false)
            compare(findChild(t.card, "playerNextButton").enabled, false)
            t.source.players = [a, b]
            compare(findChild(t.card, "playerNextButton").enabled, true)
            compare(t.selection.current, b)
            wait(100)
            mouseClick(findChild(t.card, "playerNextButton"))
            compare(t.selection.pinState, "active")
            compare(t.selection.current, a)
            mouseClick(findChild(t.card, "playerPreviousButton"))
            compare(t.selection.current, b)
        }
        function test_oneSquareForEachPlayerAndTheShownOneIsFilled() {
            const a = player("a", { isPlaying: false }), b = player("b", { isPlaying: true })
            const t = make([a, b])
            const dots = findChild(t.card, "playerDots").children.filter(item => item.shownNow !== undefined)
            compare(dots.length, 2)
            compare(dots.filter(dot => dot.shownNow).length, 1)
        }
        function test_theCardNeverChangesSizeWithThePlayerOrTheText() {
            const t = make([])
            const empty = t.card.height
            t.source.players = [player("a", { trackTitle: "A very long title that cannot fit in one line of the card at all, however wide it is" })]
            compare(t.card.height, empty)
            t.source.players = [player("a", { lengthSupported: false, trackArtist: "" }), player("b")]
            compare(t.card.height, empty)
        }
        function test_theHeaderShowsTheCassette() {
            const t = make([player("mpd")])
            compare(findChild(t.card, "cassetteIcon").name, "tape-music-cassette")
        }
        function test_controlChordsAreLeftToThePanel() {
            const p = player("mpd")
            const t = make([p])
            keyClick(Qt.Key_N, Qt.ControlModifier)
            compare(p.nextCalls, 0)
        }
    }
}

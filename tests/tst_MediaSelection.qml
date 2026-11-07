import QtQuick
import QtTest
import "mpris" as Fake
import "../shell/tests/mpris" as Shell

// Which player the shell controls: the pin, then the playing player that started last, then the
// last player that played; the capability checks; how the pin behaves when its player leaves.
Item {
    id: root
    Component { id: playerComponent; Fake.FakePlayer {} }
    Component { id: sourceComponent; Fake.FakeSource {} }
    Component { id: selectionComponent; Shell.MediaSelection {} }
    TestCase {
        name: "MediaSelection"

        function player(entry, props) {
            return createTemporaryObject(playerComponent, root, Object.assign({ desktopEntry: entry, identity: entry }, props || {}))
        }
        function make(players) {
            const source = createTemporaryObject(sourceComponent, root, { players: players })
            const selection = createTemporaryObject(selectionComponent, root, { source: source })
            return { source: source, selection: selection }
        }

        function test_noPlayers() {
            const t = make([])
            compare(t.selection.current, null)
            compare(t.selection.playerCount, 0)
            compare(t.selection.pinState, "none")
        }
        function test_keyIsTheDesktopEntryThenTheIdentity() {
            const t = make([])
            compare(t.selection.keyOf({ desktopEntry: "FireFox", identity: "Other" }), "firefox")
            compare(t.selection.keyOf({ desktopEntry: "", identity: "Music Player Daemon" }), "music player daemon")
        }
        function test_aPlayingPlayerBeatsAPausedOne() {
            const a = player("a"), b = player("b", { isPlaying: true })
            const t = make([a, b])
            compare(t.selection.current, b)
        }
        function test_theLatestToStartWins() {
            const a = player("a", { isPlaying: true }), b = player("b")
            const t = make([a, b])
            compare(t.selection.current, a)
            b.isPlaying = true
            compare(t.selection.current, b)
            a.isPlaying = false
            a.isPlaying = true
            compare(t.selection.current, a)
        }
        function test_playersAlreadyPlayingAreNumberedInKeyOrderOnce() {
            const a = player("a", { isPlaying: true }), b = player("b", { isPlaying: true })
            const t = make([b, a])
            compare(t.selection.current, b)
        }
        function test_theLastPlayerThatPlayedIsKeptWhenNothingPlays() {
            const a = player("a"), b = player("b")
            const t = make([a, b])
            compare(t.selection.current, null)
            a.isPlaying = true
            a.isPlaying = false
            compare(t.selection.current, a)
        }
        function test_aPinWinsOverAPlayingPlayer() {
            const a = player("a"), b = player("b", { isPlaying: true })
            const t = make([a, b])
            t.selection.pin("a")
            compare(t.selection.current, a)
            compare(t.selection.pinState, "active")
            t.selection.unpin()
            compare(t.selection.current, b)
            compare(t.selection.pinState, "none")
        }
        function test_thePinIsKeptWhileItsPlayerIsGoneAndReturns() {
            const a = player("a"), b = player("b", { isPlaying: true })
            const t = make([a, b])
            t.selection.pin("a")
            t.source.players = [b]
            compare(t.selection.pinState, "absent")
            compare(t.selection.current, b)
            t.source.players = [a, b]
            compare(t.selection.pinState, "active")
            compare(t.selection.current, a)
        }
        function test_showPlayerPinsTheNextOneAndWraps() {
            const a = player("a", { isPlaying: true }), b = player("b"), c = player("c")
            const t = make([c, a, b])
            t.selection.showPlayer(1)
            compare(t.selection.current, b)
            t.selection.showPlayer(1)
            compare(t.selection.current, c)
            t.selection.showPlayer(1)
            compare(t.selection.current, a)
            t.selection.showPlayer(-1)
            compare(t.selection.current, c)
        }
        function test_showPlayerDoesNothingWithOnePlayer() {
            const a = player("a", { isPlaying: true })
            const t = make([a])
            t.selection.showPlayer(1)
            compare(t.selection.pinState, "none")
        }
        function test_actionsActOnTheCurrentPlayerOnlyWhenItCan() {
            const a = player("a", { isPlaying: true, canGoNext: false, canSeek: false })
            const t = make([a])
            t.selection.next()
            compare(a.nextCalls, 0)
            t.selection.previous()
            compare(a.previousCalls, 1)
            t.selection.seekBy(10)
            compare(a.seeks.length, 0)
            a.canSeek = true
            t.selection.seekBy(10)
            compare(a.seeks[0], 10)
            t.selection.playPause()
            compare(a.toggleCalls, 1)
            t.selection.pause()
            compare(a.pauseCalls, 1)
        }
        function test_actionsWithNoPlayerDoNothing() {
            const t = make([])
            t.selection.playPause()
            t.selection.next()
            t.selection.seekBy(5)
            compare(t.selection.current, null)
        }
        function test_twoWindowsOfOneAppAreOneEntryAndThePlayingOneIsShown() {
            const a = player("firefox", { dbusName: "x.1" }), b = player("firefox", { dbusName: "x.2", isPlaying: true }), c = player("mpd")
            const t = make([a, b, c])
            compare(t.selection.playerCount, 2)
            compare(t.selection.current, b)
            t.selection.pin("firefox")
            compare(t.selection.current, b)
            b.isPlaying = false
            compare(t.selection.current.desktopEntry, "firefox")
        }
        function test_aPlayerWithNoDesktopEntryOrIdentityIsKeyedByItsBusName() {
            const a = player("", { identity: "", dbusName: "org.mpris.MediaPlayer2.thing", isPlaying: true })
            const t = make([a])
            compare(t.selection.keyOf(a), "org.mpris.mediaplayer2.thing")
            t.selection.pin(t.selection.keyOf(a))
            compare(t.selection.pinState, "active")
        }
        function test_entriesThatAreNotPlayersAreIgnored() {
            const a = player("a", { isPlaying: true })
            const t = make([a, null, undefined, 5])
            compare(t.selection.playerCount, 1)
            compare(t.selection.current, a)
        }
        function test_aBadPinKeyIsIgnored() {
            const a = player("a", { isPlaying: true })
            const t = make([a])
            t.selection.pin("")
            t.selection.pin(undefined)
            t.selection.pin(42)
            compare(t.selection.pinState, "none")
        }
        function test_aPlayerThatQuitCannotBreakAnAction() {
            const a = player("a", { isPlaying: true, broken: true })
            const t = make([a])
            t.selection.playPause()
            t.selection.pause()
            t.selection.next()
            t.selection.previous()
            t.selection.seekBy(10)
            compare(a.toggleCalls, 0)
            compare(t.selection.current, a)
        }
        function test_seekByIgnoresValuesThatAreNotUsableNumbers() {
            const a = player("a", { isPlaying: true })
            const t = make([a])
            t.selection.seekBy(0)
            t.selection.seekBy(NaN)
            t.selection.seekBy(Infinity)
            t.selection.seekBy("10")
            compare(a.seeks.length, 0)
        }
        function test_aNewPlayingPlayerChangesCurrentExactlyOnce() {
            const a = player("a", { isPlaying: true }), b = player("b")
            const t = make([a, b])
            const seen = []
            t.selection.currentChanged.connect(() => seen.push(t.selection.current.desktopEntry))
            const c = player("c", { isPlaying: true }), d = player("d", { isPlaying: true })
            t.source.players = [a, b, c, d]
            compare(seen.length, 1)
            compare(t.selection.current, d)
        }
        function test_aPlayerGoneAndBackKeepsItsPlaceInTheOrder() {
            const a = player("a", { isPlaying: true }), b = player("b", { isPlaying: true })
            const t = make([a, b])
            compare(t.selection.current, b)
            t.source.players = [a]
            compare(t.selection.current, a)
            t.source.players = [a, b]
            compare(t.selection.current, b)
        }
        function test_showPlayerNavigatesDistinctEntries() {
            const a = player("a", { dbusName: "x.1" }), a2 = player("a", { dbusName: "x.2" }), b = player("b")
            const t = make([a, a2, b])
            compare(t.selection.playerCount, 2)
            t.selection.showPlayer(1)
            compare(t.selection.pinKey, "a")
            t.selection.showPlayer(1)
            compare(t.selection.pinKey, "b")
            t.selection.showPlayer(1)
            compare(t.selection.pinKey, "a")
        }
        function test_thereIsOnlyOnePinAndPinningAnotherReplacesIt() {
            const a = player("a", { isPlaying: true }), b = player("b")
            const t = make([a, b])
            t.selection.pin("a")
            t.selection.pin("b")
            compare(t.selection.pinKey, "b")
            compare(t.selection.current, b)
            // The media keys act on the pinned player, not on the one that is playing.
            t.selection.playPause()
            compare(b.toggleCalls, 1)
            compare(a.toggleCalls, 0)
            t.selection.pause()
            compare(b.pauseCalls, 1)
            t.selection.unpin()
            compare(t.selection.current, a)
        }
    }
}

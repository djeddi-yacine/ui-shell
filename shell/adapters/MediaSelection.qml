import QtQuick
import QtQml.Models

// Which player the shell controls. One owner: the bar icon, the panel and the media keys all
// read `current` and call the actions here, so they can never disagree.
//
// It works on `source.players` (an array of player objects) and imports nothing relative, so a
// test can give it fake players. Order of preference: the pinned player, a playing player (the
// one that started most recently), the last player that played, none.
//
// Players are told apart by `keyOf`: the desktop entry, else the identity, else the bus name.
// Players that share a key (two windows of one app) count as one entry, and the one that is
// playing (the latest to start) is the one shown, so a pin by key is never ambiguous.
//
// State changes are atomic: `current` is a pure function of the player list, the numbers
// and the pin, and a player that is new and already playing is ranked as if it had been
// numbered, so `current` never shows a wrong player between a change and the bookkeeping.
QtObject {
    id: root
    required property var source
    // Entries that are not objects are dropped: nothing below has to guard against them.
    readonly property var players: (source.players ?? []).filter(player => player !== null && player !== undefined && typeof player === "object")
    // The pin lives in memory only. The key survives a browser restart; the bus name does not.
    property string pinKey: ""
    // key -> number of the moment the player last started playing.
    property var order: ({})
    // key -> true once the player has been seen (so it is numbered once on first sight).
    property var seen: ({})
    property int counter: 0

    function keyOf(player) {
        return (player.desktopEntry ?? "").toLowerCase() || (player.identity ?? "").toLowerCase() || (player.dbusName ?? "").toLowerCase()
    }
    function sorted() {
        return players.slice().sort((a, b) => {
            const ka = keyOf(a), kb = keyOf(b)
            if (ka !== kb) return ka < kb ? -1 : 1
            const da = a.dbusName ?? "", db = b.dbusName ?? ""
            return da < db ? -1 : da > db ? 1 : 0
        })
    }
    // Every present player with its number. A player that is playing and has not been numbered
    // yet gets the number it is about to get (above all existing ones, in key order).
    function ranked() {
        let provisional = 0
        return sorted().map(player => {
            const key = keyOf(player)
            let number = order[key] ?? 0
            if (number === 0 && seen[key] !== true && player.isPlaying) { provisional += 1; number = 1e9 + provisional }
            return { player: player, key: key, number: number }
        })
    }
    function top(entries) {
        let best = null
        for (const entry of entries) if (best === null || entry.number > best.number) best = entry
        return best
    }
    function choose(entries) {
        if (pinKey.length > 0) {
            const pinned = top(entries.filter(entry => entry.key === pinKey && entry.player.isPlaying)) ?? top(entries.filter(entry => entry.key === pinKey))
            if (pinned) return pinned.player
        }
        const playing = top(entries.filter(entry => entry.player.isPlaying))
        if (playing) return playing.player
        const played = top(entries.filter(entry => entry.number > 0))
        return played ? played.player : null
    }
    readonly property var entries: ranked()
    readonly property var current: choose(entries)
    // One entry per key: what a player switcher lists, in key order.
    readonly property var listed: {
        const groups = []
        for (const entry of entries) {
            if (groups.length > 0 && groups[groups.length - 1].key === entry.key) groups[groups.length - 1].members.push(entry)
            else groups.push({ key: entry.key, members: [entry] })
        }
        return groups.map(group => (top(group.members.filter(entry => entry.player.isPlaying)) ?? top(group.members) ?? group.members[0]).player)
    }
    readonly property int playerCount: listed.length
    readonly property string pinState: {
        if (pinKey.length === 0) return "none"
        for (const entry of entries) if (entry.key === pinKey) return "active"
        return "absent"
    }

    // A player started playing: give it the next number. One assignment, so no reader sees half of it.
    function started(player) {
        const key = keyOf(player)
        counter += 1
        const next = Object.assign({}, order)
        next[key] = counter
        order = next
    }
    // A player already playing when it is first seen is numbered once, in key order; after that
    // only the order of events matters, never the position in the list. The numbers are
    // computed first and stored in one step each, the numbers before the "seen" marks.
    function sync() {
        const fresh = sorted().filter(player => seen[keyOf(player)] !== true)
        if (fresh.length === 0) return
        const nextOrder = Object.assign({}, order)
        const nextSeen = Object.assign({}, seen)
        let nextCounter = counter
        for (const player of fresh) {
            const key = keyOf(player)
            if (nextSeen[key] === true) continue
            nextSeen[key] = true
            if (player.isPlaying) { nextCounter += 1; nextOrder[key] = nextCounter }
        }
        counter = nextCounter
        order = nextOrder
        seen = nextSeen
    }
    onPlayersChanged: sync()
    Component.onCompleted: sync()

    // One watcher per player: it notices when that player starts playing.
    property Instantiator watchers: Instantiator {
        model: root.players
        delegate: QtObject {
            id: watcher
            required property var modelData
            property Connections link: Connections {
                target: watcher.modelData
                function onIsPlayingChanged() { if (watcher.modelData.isPlaying) root.started(watcher.modelData) }
            }
        }
    }

    function pin(key) { if (typeof key === "string" && key.length > 0) pinKey = key }
    function unpin() { pinKey = "" }
    // Pin the player `delta` places away in the list of players (ordered by key), wrapping at
    // the ends. Nothing happens with one player or none.
    function showPlayer(delta) {
        const list = listed
        if (list.length < 2) return
        const here = current ? list.findIndex(player => keyOf(player) === keyOf(current)) : -1
        const index = here < 0 ? (delta > 0 ? 0 : list.length - 1)
            : (here + (delta > 0 ? 1 : -1) + list.length) % list.length
        pin(keyOf(list[index]))
    }

    // Each action reads `current` once and checks the player's own capability first, so Quickshell
    // never logs a warning. A player can disappear between the check and the call (Quickshell
    // deletes its object when the player quits), so a failing call is dropped: the list updates on
    // its own, and nothing else depends on the call.
    function act(capability, call) {
        const player = current
        if (!player) return
        try { if (player[capability]) call(player) } catch (failure) { }
    }
    function playPause() { act("canTogglePlaying", player => player.togglePlaying()) }
    function pause() { act("canPause", player => player.pause()) }
    function next() { act("canGoNext", player => player.next()) }
    function previous() { act("canGoPrevious", player => player.previous()) }
    function seekBy(seconds) {
        if (typeof seconds !== "number" || !isFinite(seconds) || seconds === 0) return
        act("canSeek", player => { if (player.positionSupported) player.seek(seconds) })
    }
}

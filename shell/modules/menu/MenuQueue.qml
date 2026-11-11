import QtQuick

// Which request the menu shows. Requests wait in arrival order; they are grouped by the app that
// sent them, one tab per app. The visible request is the oldest one of the current app. Pure
// bookkeeping: no files, no processes, no windows.
QtObject {
    id: root

    // Every waiting request as { id, app, pid, prompt, lines }, oldest first (`pid` is the asking client's, 0 when none).
    property var entries: []
    // The app whose requests are shown; "" while nothing waits.
    property string current: ""

    // The apps with something waiting, as { name, count }, in the order of their first request.
    readonly property var apps: {
        const found = []
        for (const entry of root.entries) {
            const known = found.find(app => app.name === entry.app)
            if (known) known.count += 1
            else found.push({ name: entry.app, count: 1 })
        }
        return found
    }
    // The request to show, or null.
    readonly property var visible: root.entries.find(entry => entry.app === root.current) ?? null
    readonly property bool empty: root.entries.length === 0
    // The card is mapped while a request waits. After the last answer the window plays its leave
    // animation; a request that arrives meanwhile brings the card back.
    readonly property bool open: !root.empty

    function add(entry) {
        if (root.entries.some(known => known.id === entry.id)) return
        root.entries = root.entries.concat([entry])
        if (root.current === "") root.current = entry.app
    }

    // Takes a request out (answered, cancelled or its caller gone). The shown app moves on only when
    // its last request left; it then takes the next app in order, or "" when none is left.
    function remove(id) {
        const left = root.entries.filter(entry => entry.id !== id)
        if (left.length === root.entries.length) return
        root.entries = left
        if (!left.some(entry => entry.app === root.current)) root.current = left.length > 0 ? left[0].app : ""
    }

    // Moves to the next (+1) or previous (-1) app, wrapping round.
    function cycle(step) {
        const names = root.apps.map(app => app.name)
        if (names.length < 2) return
        const at = names.indexOf(root.current)
        root.current = names[((at + step) % names.length + names.length) % names.length]
    }
}

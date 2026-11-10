pragma Singleton
import QtQuick
import "../../config" as Config

// Notification logic: history, unread count, the one visible popup, DND, timeouts.
// No UI. Every decision lives here; sources only deliver entries.
Item {
    id: root
    // Newest first, no cap, cleared by hand.
    // The notification source (NotifSource in the shell, a fake in tests); set once by shell.qml.
    property var source: null
    // A NotifRules instance, or null for none; set once by shell.qml.
    property var rules: null
    property var entries: []
    property bool dnd: false
    // Set by a binding in shell.qml while a recording runs.
    property bool redact: false
    // Set by a binding in shell.qml.
    property bool fullscreen: false
    // The entry shown as a popup, or null.
    property var popup: null
    property bool popupHovered: false
    property int nextInternalId: -1
    // Milliseconds left on the popup timer, kept while the pointer holds it.
    property int popupRemaining: 0
    property double popupStartedAt: 0

    // Stack names the owner expanded in the drawer: { appName: true }. In memory only.
    property var expandedApps: ({})
    // One stack per app, ordered by the newest item; items newest first.
    readonly property var groups: {
        const order = []
        const byApp = {}
        for (const e of entries) {
            if (!byApp[e.appName]) { byApp[e.appName] = { appName: e.appName, items: [] }; order.push(byApp[e.appName]) }
            byApp[e.appName].items.push(e)
        }
        return order
    }

    readonly property int unread: entries.filter(e => !e.read).length
    readonly property int suppressed: entries.filter(e => e.hidden).length

    // path of the sound file to play
    signal soundRequested(string path)

    function timeoutFor(entry) {
        // Spec: a critical notification does not expire by itself; a sender's 0 means never; -1 leaves
        // the choice to the server, which picks by urgency.
        if (entry.urgency === "critical") return 0
        const t = entry.expireTimeout
        if (t === 0) return 0
        const fallback = entry.urgency === "low" ? Config.Notifications.lowTimeoutMs : Config.Notifications.normalTimeoutMs
        return t > 0 ? Math.min(t, Config.Notifications.maxTimeoutMs) : fallback
    }
    function indexOfId(id) {
        for (let i = 0; i < entries.length; i++) if (entries[i].id === id) return i
        return -1
    }
    // Internal modules post here; same policy as D-Bus entries.
    function post(summary, body, urgency) {
        ingest({ id: 0, appName: "ui-shell", appId: "", summary: summary, body: body ?? "", icon: "", image: "",
            urgency: urgency ?? "normal", expireTimeout: 0, actions: [], progress: -1, origin: "internal", generation: 0 })
    }
    function ingest(entry) {
        const e = Object.assign({ imageLoaded: false, read: false, hidden: false, muted: false, tag: "", generation: 0, time: Date.now() }, entry)
        if (e.origin === "internal") e.id = nextInternalId--
        const held = indexOfId(e.id)
        if (held >= 0) return e.generation ? undefined : update(e)
        // A replayed notification from before a reload: keep it in history, quietly.
        if (e.generation) {
            e.read = true
            entries = [e].concat(entries)
            return
        }
        const rule = rules ? rules.match(e) : null
        if (rule) {
            e.hidden = rule.hide === true
            e.muted = rule.mute === true || e.hidden
            e.tag = "rule: " + rule.name
            if (rule.sound) e.sound = rule.sound
            // A rule may exempt a notification from the recording blur (its text is safe to show).
            if (rule.reveal === true) e.reveal = true
        }
        const quiet = dnd || e.hidden || fullscreen
        // Spec: a transient notification is only a popup; it never reaches the history.
        if (e.transient) {
            if (quiet) { if (source) source.dismiss(e.id) }
            else show(e)
        } else {
            entries = [e].concat(entries)
            if (!dnd && !e.hidden && !fullscreen) show(e)
        }
        if (!dnd && !e.hidden && !e.muted) {
            const path = soundFor(e)
            if (path !== "") soundRequested(path)
        }
    }
    // The sound for a notification: a rule's, then the sender's sound-file or sound-name hint
    // (nothing when it sets suppress-sound), then the configured default.
    function soundFor(e) {
        if (e.sound) return e.sound
        if (e.suppressSound) return ""
        if (e.soundFile) return e.soundFile.startsWith("file://") ? decodeURIComponent(e.soundFile.slice(7)) : e.soundFile
        if (e.soundName) return e.soundName
        return Config.Notifications.soundEnabled && Config.Notifications.soundFile.startsWith("/") ? Config.Notifications.soundFile : ""
    }
    function update(entry) {
        const i = indexOfId(entry.id)
        if (i < 0) return ingest(entry)
        const merged = Object.assign({}, entries[i], entry, { read: entries[i].read, time: entries[i].time, imageLoaded: entries[i].imageLoaded === true })
        const copy = entries.slice()
        copy[i] = merged
        entries = copy
        if (popup && popup.id === merged.id) {
            popup = merged
            popupRemaining = timeoutFor(merged)
            popupStartedAt = Date.now()
            popupTimer.stop()
            if (popupRemaining > 0) {
                popupTimer.interval = popupRemaining
                if (!popupHovered) popupTimer.restart()
            }
        }
    }
    function show(e) {
        popup = e
        popupRemaining = timeoutFor(e)
        popupStartedAt = Date.now()
        popupTimer.stop()
        if (popupRemaining > 0) {
            popupTimer.interval = popupRemaining
            popupTimer.restart()
        }
    }
    function dismissPopup() {
        popupTimer.stop()
        if (popup && popup.transient && source) source.dismiss(popup.id)
        popup = null
    }
    onPopupHoveredChanged: {
        if (popup === null || popupRemaining === 0) return
        if (popupHovered) {
            popupRemaining = Math.max(1, popupRemaining - (Date.now() - popupStartedAt))
        } else {
            popupStartedAt = Date.now()
            popupTimer.interval = popupRemaining
            popupTimer.restart()
        }
    }
    // Read state is the owner's: nothing marks a notification read by itself except acting on it.
    function setRead(id, value) {
        const i = indexOfId(id)
        if (i < 0 || entries[i].read === value) return
        const copy = entries.slice()
        copy[i] = Object.assign({}, copy[i], { read: value })
        entries = copy
    }
    function toggleRead(id) {
        const i = indexOfId(id)
        if (i >= 0) setRead(id, !entries[i].read)
    }
    function markGroupRead(app) { entries = entries.map(e => e.read || e.appName !== app ? e : Object.assign({}, e, { read: true })) }
    function markAllRead() { entries = entries.map(e => e.read ? e : Object.assign({}, e, { read: true })) }
    function isExpanded(app) { return expandedApps[app] === true }
    function toggleGroup(app) {
        const copy = Object.assign({}, expandedApps)
        if (copy[app]) delete copy[app]
        else copy[app] = true
        expandedApps = copy
    }
    // Items of a stack that are drawn: all when expanded, else only the newest few.
    function visibleItems(group) {
        return isExpanded(group.appName) ? group.items : group.items.slice(0, Config.Notifications.collapsedStackItems)
    }
    // Every drawn notification in on-screen order (stack by stack); the drawer's keyboard walks this.
    // Written as a loop: the QML JS engine has no Array.prototype.flatMap.
    function visibleEntries() {
        const out = []
        for (const g of groups) for (const e of visibleItems(g)) out.push(e)
        return out
    }
    // The owner asked for this one image to load; nothing loads on its own.
    function loadImage(id) {
        const i = indexOfId(id)
        if (i < 0 || entries[i].imageLoaded) return
        const copy = entries.slice()
        copy[i] = Object.assign({}, copy[i], { imageLoaded: true })
        entries = copy
    }
    function remove(filter) {
        for (const e of entries) if (filter(e) && source) source.dismiss(e.id)
        entries = entries.filter(e => !filter(e))
        if (popup && indexOfId(popup.id) < 0) dismissPopup()
    }
    function clear(id) { remove(e => e.id === id) }
    function clearGroup(app) { remove(e => e.appName === app) }
    function clearAll() { remove(e => true) }
    function setDnd(on) {
        dnd = on
        if (on) dismissPopup()
    }
    // Acting on a notification reads it. Spec: the server closes it afterwards unless the sender
    // set the resident hint.
    function invoke(id, action) {
        const e = lookup(id)
        if (!e || e.origin !== "dbus") return
        source?.invoke(id, action)
        if (e.resident === true) setRead(id, true)
        else if (e.transient) { if (popup && popup.id === id) dismissPopup() }
        else clear(id)
    }
    // An entry of the history, or the popup of a transient notification (which is not in it).
    function lookup(id) {
        const i = indexOfId(id)
        return i >= 0 ? entries[i] : (popup && popup.id === id ? popup : null)
    }
    function hasDefaultAction(entry) { return entry.origin === "dbus" && entry.actions.some(a => a.identifier === "default") }
    // The spec's "default" action: what clicking the notification does.
    function invokeDefault(id) {
        const e = lookup(id)
        if (e && hasDefaultAction(e)) invoke(id, "default")
    }
    // The actions drawn as buttons: the default action is the click, not a button.
    function buttonActions(entry) { return entry.actions.filter(a => a.identifier !== "default") }

    Timer {
        id: popupTimer
        repeat: false
        onTriggered: root.dismissPopup()
    }

    Connections {
        target: root.source
        function onReceived(entry) { root.ingest(entry) }
        function onUpdated(entry) { root.update(entry) }
        function onClosed(id) { if (root.popup && root.popup.id === id) root.dismissPopup() }
    }
}

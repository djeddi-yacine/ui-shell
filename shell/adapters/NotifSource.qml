pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The only file that imports Quickshell's notification module. It claims the D-Bus name and turns
// each notification into a plain entry; no Quickshell object leaves this file.
Singleton {
    id: root
    // Entry shape: id, appName, appId, summary, body (spec markup), icon, image, urgency
    // (low|normal|critical), expireTimeout (ms as sent: -1 = the server decides, 0 = never expires),
    // actions [{identifier, text}], actionIcons (identifiers are icon names), progress (0..100, -1 =
    // none), category, transient, resident, soundFile, soundName, suppressSound, origin "dbus",
    // generation.
    signal received(var entry)
    signal updated(var entry)
    signal closed(int id)

    property var live: ({})

    function invoke(id, identifier) {
        const n = live[id]
        if (!n) return
        for (const a of n.actions) if (a.identifier === identifier) { a.invoke(); return }
    }
    function dismiss(id) {
        const n = live[id]
        if (n) n.dismiss()
    }

    function urgencyName(u) {
        return u === NotificationUrgency.Low ? "low" : u === NotificationUrgency.Critical ? "critical" : "normal"
    }
    function toEntry(n) {
        const hints = n.hints ?? ({})
        const v = hints.value !== undefined ? Number(hints.value) : -1
        const actions = []
        for (const a of n.actions) actions.push({ identifier: a.identifier, text: a.text })
        return {
            id: n.id, appName: n.appName, appId: n.desktopEntry ?? "", summary: n.summary, body: n.body,
            icon: n.appIcon, image: n.image, urgency: urgencyName(n.urgency),
            expireTimeout: n.expireTimeout, actions: actions, actionIcons: n.hasActionIcons,
            category: n.category ?? "", transient: n.transient, resident: n.resident,
            soundFile: String(hints["sound-file"] ?? ""), soundName: String(hints["sound-name"] ?? ""),
            suppressSound: hints["suppress-sound"] === true,
            progress: isNaN(v) ? -1 : Math.max(-1, Math.min(100, v)),
            origin: "dbus", generation: n.lastGeneration ? 1 : 0
        }
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionIconsSupported: true
        inlineReplySupported: false
        persistenceSupported: true
        extraHints: ["value", "sound-file", "sound-name", "suppress-sound"]
        onNotification: n => {
            n.tracked = true
            const map = root.live
            map[n.id] = n
            root.live = map
            n.closed.connect(() => {
                const m = root.live
                delete m[n.id]
                root.live = m
                root.closed(n.id)
            })
            // A replaces_id or progress update changes the same object and emits no new
            // notification signal, so forward each property change as an update.
            const push = () => root.updated(root.toEntry(n))
            n.summaryChanged.connect(push)
            n.bodyChanged.connect(push)
            n.appIconChanged.connect(push)
            n.imageChanged.connect(push)
            n.urgencyChanged.connect(push)
            n.expireTimeoutChanged.connect(push)
            n.actionsChanged.connect(push)
            n.hintsChanged.connect(push)
            root.received(root.toEntry(n))
        }
    }
}

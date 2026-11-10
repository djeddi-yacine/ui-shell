import QtQuick
import QtTest
import "../shell/modules/notifications" as Notif
import "notifications" as Fakes

TestCase {
    id: tc
    Fakes.FakeSource { id: fake }
    name: "NotifCenter"

    function entry(id, urgency, extra) {
        return Object.assign({ id: id, appName: "app", appId: "", summary: "s", body: "b", icon: "", image: "",
            urgency: urgency ?? "normal", expireTimeout: -1, actions: [], progress: -1, origin: "dbus" }, extra ?? {})
    }
    function init() {
        Notif.NotifCenter.clearAll()
        Notif.NotifCenter.dnd = false
        Notif.NotifCenter.fullscreen = false
        Notif.NotifCenter.dismissPopup()
    }
    function test_newest_first_and_single_popup() {
        Notif.NotifCenter.ingest(entry(1))
        Notif.NotifCenter.ingest(entry(2))
        compare(Notif.NotifCenter.entries.map(e => e.id), [2, 1])
        compare(Notif.NotifCenter.popup.id, 2)
        compare(Notif.NotifCenter.unread, 2)
    }
    function test_replace_in_place() {
        Notif.NotifCenter.ingest(entry(1, "normal", { progress: 10 }))
        Notif.NotifCenter.ingest(entry(2))
        Notif.NotifCenter.update(entry(1, "normal", { progress: 80 }))
        compare(Notif.NotifCenter.entries.length, 2)
        compare(Notif.NotifCenter.entries[1].progress, 80)
    }
    function test_timeouts() {
        compare(Notif.NotifCenter.timeoutFor(entry(1, "low")), 2500)
        compare(Notif.NotifCenter.timeoutFor(entry(1, "normal")), 4000)
        // Spec: critical never expires by itself, and a sender's 0 means never.
        compare(Notif.NotifCenter.timeoutFor(entry(1, "critical")), 0)
        compare(Notif.NotifCenter.timeoutFor(entry(1, "normal", { expireTimeout: 0 })), 0)
        compare(Notif.NotifCenter.timeoutFor(entry(1, "normal", { expireTimeout: 999999 })), 15000)
        compare(Notif.NotifCenter.timeoutFor(entry(1, "normal", { expireTimeout: -1 })), 4000)
    }
    function test_dnd_keeps_history_hides_popup() {
        Notif.NotifCenter.setDnd(true)
        Notif.NotifCenter.ingest(entry(1))
        compare(Notif.NotifCenter.popup, null)
        compare(Notif.NotifCenter.entries.length, 1)
        compare(Notif.NotifCenter.unread, 1)
    }
    function test_fullscreen_no_popup_but_sound() {
        let sounds = 0
        Notif.NotifCenter.soundRequested.connect(() => sounds++)
        Notif.NotifCenter.fullscreen = true
        Notif.NotifCenter.ingest(entry(1, "normal", { sound: "/x/a.wav" }))
        compare(Notif.NotifCenter.popup, null)
        compare(sounds, 1)
    }
    function test_internal_ids_never_collide() {
        Notif.NotifCenter.ingest(entry(5, "normal", { origin: "internal" }))
        Notif.NotifCenter.ingest(entry(5, "normal", { origin: "internal" }))
        compare(Notif.NotifCenter.entries.length, 2)
        verify(Notif.NotifCenter.entries[0].id < 0)
    }
    function test_read_state_drives_unread() {
        Notif.NotifCenter.ingest(entry(1))
        compare(Notif.NotifCenter.unread, 1)
        Notif.NotifCenter.setRead(1, true)
        compare(Notif.NotifCenter.unread, 0)
        Notif.NotifCenter.toggleRead(1)
        compare(Notif.NotifCenter.unread, 1)
        Notif.NotifCenter.ingest(entry(2, "normal", { appName: "other" }))
        Notif.NotifCenter.markGroupRead("other")
        compare(Notif.NotifCenter.unread, 1)
        Notif.NotifCenter.markAllRead()
        compare(Notif.NotifCenter.unread, 0)
        Notif.NotifCenter.clear(1)
        compare(Notif.NotifCenter.entries.length, 1)
    }
    function test_post_goes_through_ingest() {
        Notif.NotifCenter.setDnd(true)
        Notif.NotifCenter.post("Saved", "shot.png")
        compare(Notif.NotifCenter.popup, null)
        compare(Notif.NotifCenter.entries[0].origin, "internal")
        compare(Notif.NotifCenter.entries[0].appName, "ui-shell")
    }
    function test_dedupe_generation() {
        Notif.NotifCenter.ingest(entry(1))
        Notif.NotifCenter.ingest(entry(1, "normal", { generation: 1 }))
        compare(Notif.NotifCenter.entries.length, 1)
        Notif.NotifCenter.ingest(entry(9, "normal", { generation: 1 }))
        compare(Notif.NotifCenter.entries.length, 2)
        compare(Notif.NotifCenter.entries[0].read, true)
        verify(Notif.NotifCenter.popup.id !== 9)
    }
    function test_transient_is_a_popup_only() {
        Notif.NotifCenter.ingest(entry(1, "normal", { transient: true }))
        compare(Notif.NotifCenter.entries.length, 0)
        compare(Notif.NotifCenter.popup.id, 1)
    }
    function test_sound_hints() {
        compare(Notif.NotifCenter.soundFor(entry(1, "normal", { soundFile: "file:///a%20b.oga" })), "/a b.oga")
        compare(Notif.NotifCenter.soundFor(entry(1, "normal", { soundName: "message-new-instant" })), "message-new-instant")
        compare(Notif.NotifCenter.soundFor(entry(1, "normal", { soundName: "x", suppressSound: true })), "")
    }
    function test_default_action_is_the_click_not_a_button() {
        const e = entry(1, "normal", { actions: [{ identifier: "default", text: "Open" }, { identifier: "reply", text: "Reply" }] })
        verify(Notif.NotifCenter.hasDefaultAction(e))
        compare(Notif.NotifCenter.buttonActions(e).map(a => a.identifier), ["reply"])
    }
    function test_hover_keeps_remaining() {
        Notif.NotifCenter.ingest(entry(1))
        Notif.NotifCenter.popupHovered = true
        verify(Notif.NotifCenter.popupRemaining > 0 && Notif.NotifCenter.popupRemaining <= 4000)
        Notif.NotifCenter.popupHovered = false
        verify(Notif.NotifCenter.popup !== null)
        Notif.NotifCenter.dismissPopup()
    }
    function test_source_signals_reach_center() {
        Notif.NotifCenter.source = fake
        fake.received(entry(7, "normal", { progress: 5 }))
        fake.updated(entry(7, "normal", { progress: 60 }))
        compare(Notif.NotifCenter.entries.length, 1)
        compare(Notif.NotifCenter.entries[0].progress, 60)
        Notif.NotifCenter.clear(7)
        compare(fake.dismissed, [7])
        Notif.NotifCenter.source = null
    }

    function test_groups_per_app_newest_first() {
        Notif.NotifCenter.ingest(entry(1, "normal", { appName: "a" }))
        Notif.NotifCenter.ingest(entry(2, "normal", { appName: "b" }))
        Notif.NotifCenter.ingest(entry(3, "normal", { appName: "a" }))
        compare(Notif.NotifCenter.groups.map(g => g.appName), ["a", "b"])
        compare(Notif.NotifCenter.groups[0].items.map(e => e.id), [3, 1])
    }
    function test_collapsed_stack_lists_only_the_newest_and_expands() {
        for (let i = 1; i <= 4; i++) Notif.NotifCenter.ingest(entry(i))
        const g = Notif.NotifCenter.groups[0]
        compare(Notif.NotifCenter.visibleItems(g).map(e => e.id), [4])
        Notif.NotifCenter.toggleGroup("app")
        compare(Notif.NotifCenter.visibleItems(Notif.NotifCenter.groups[0]).length, 4)
        Notif.NotifCenter.toggleGroup("app")
        compare(Notif.NotifCenter.visibleItems(Notif.NotifCenter.groups[0]).length, 1)
    }
    function test_delete_one_item_keeps_the_rest_of_the_stack() {
        for (let i = 1; i <= 3; i++) Notif.NotifCenter.ingest(entry(i))
        Notif.NotifCenter.clear(3)
        compare(Notif.NotifCenter.groups[0].items.map(e => e.id), [2, 1])
    }
    function test_image_loads_only_when_asked_and_survives_update() {
        Notif.NotifCenter.ingest(entry(1, "normal", { image: "file:///x.png" }))
        compare(Notif.NotifCenter.entries[0].imageLoaded, false)
        Notif.NotifCenter.loadImage(1)
        compare(Notif.NotifCenter.entries[0].imageLoaded, true)
        Notif.NotifCenter.update(entry(1, "normal", { image: "file:///y.png" }))
        compare(Notif.NotifCenter.entries[0].imageLoaded, true)
    }
    function test_visible_entries_follow_stack_order_and_expansion() {
        Notif.NotifCenter.ingest(entry(1, "normal", { appName: "a" }))
        Notif.NotifCenter.ingest(entry(2, "normal", { appName: "b" }))
        Notif.NotifCenter.ingest(entry(3, "normal", { appName: "a" }))
        Notif.NotifCenter.ingest(entry(4, "normal", { appName: "a" }))
        compare(Notif.NotifCenter.visibleEntries().map(e => e.id), [4, 2])
        Notif.NotifCenter.toggleGroup("a")
        compare(Notif.NotifCenter.visibleEntries().map(e => e.id), [4, 3, 1, 2])
        Notif.NotifCenter.toggleGroup("a")
    }
}

import QtQuick
import QtTest
import "../shell/config" as Config
import "../shell/modules/notifications" as Notif
import "../shell/modules/notifications/NotifMatch.js" as Matcher

TestCase {
    id: tc
    name: "NotifRules"

    QtObject {
        id: fakeRules
        property var list: []
        function match(entry) {
            for (const r of list) if (Matcher.match(r, entry)) return r
            return null
        }
    }
    function entry(id, app, summary) {
        return { id: id, appName: app, appId: "", summary: summary ?? "s", body: "b", icon: "", image: "",
            urgency: "normal", expireTimeout: 0, actions: [], progress: -1, origin: "dbus" }
    }
    function init() {
        Notif.NotifCenter.rules = null
        Notif.NotifCenter.clearAll()
        Notif.NotifCenter.dnd = false
        Notif.NotifCenter.dismissPopup()
    }
    function test_valid_and_errors() {
        const v = Config.ComponentSpec.validRules
        compare(v([{ name: "a", app: "x", mute: true }]), "")
        compare(v(undefined), "")
        compare(v("no"), "rules is not an array")
        compare(v([1]), "rule 1 is not an object")
        compare(v([{ name: "a", colour: 1 }]), "rule 1: unknown key \"colour\"")
        compare(v([{ app: "x" }]), "rule 1: name is required")
        compare(v([{ name: "a", app: 3 }]), "rule 1: app must be a string")
        compare(v([{ name: "a", hide: "yes" }]), "rule 1: hide must be true or false")
        compare(v([{ name: "a", sound: "rel.wav" }]), "rule 1: sound must be an absolute .wav, .ogg or .oga path")
        compare(v([{ name: "a" }, { name: "b", match: "(" }]), "rule 2: match is not a valid regular expression")
    }
    function test_rule_hide_and_mute_flags() {
        fakeRules.list = [{ name: "quiet", app: "noisy", hide: true }, { name: "m", app: "meh", mute: true }]
        Notif.NotifCenter.rules = fakeRules
        Notif.NotifCenter.ingest(entry(1, "noisy"))
        compare(Notif.NotifCenter.popup, null)
        compare(Notif.NotifCenter.entries[0].hidden, true)
        compare(Notif.NotifCenter.entries[0].tag, "rule: quiet")
        compare(Notif.NotifCenter.suppressed, 1)
        let sounds = 0
        Notif.NotifCenter.soundRequested.connect(() => sounds++)
        Notif.NotifCenter.ingest(entry(2, "meh"))
        compare(Notif.NotifCenter.popup.id, 2)
        compare(sounds, 0)
    }
    function test_reveal_rule_marks_the_entry() {
        compare(Config.ComponentSpec.validRules([{ name: "a", reveal: true }]), "")
        compare(Config.ComponentSpec.validRules([{ name: "a", reveal: "yes" }]), "rule 1: reveal must be true or false")
        fakeRules.list = [{ name: "music", app: "player", reveal: true }]
        Notif.NotifCenter.rules = fakeRules
        Notif.NotifCenter.ingest(entry(1, "player"))
        Notif.NotifCenter.ingest(entry(2, "other"))
        compare(Notif.NotifCenter.entries[1].reveal, true)
        compare(Notif.NotifCenter.entries[0].reveal, undefined)
    }
    function test_blur_only_the_named_apps() {
        // The first matching rule wins: the named apps get no reveal (so they are blurred while
        // recording) and the catch-all reveals every other app.
        fakeRules.list = [{ name: "blur secret", appMatch: "^secret-" }, { name: "rest", appMatch: ".", reveal: true }]
        compare(Config.ComponentSpec.validRules(fakeRules.list), "")
        Notif.NotifCenter.rules = fakeRules
        Notif.NotifCenter.ingest(entry(1, "secret-mail"))
        Notif.NotifCenter.ingest(entry(2, "public-news"))
        compare(Notif.NotifCenter.entries[1].reveal, undefined)
        compare(Notif.NotifCenter.entries[0].reveal, true)
    }
    function test_matcher() {
        const e = { appName: "app", appId: "id", summary: "Build FAILED", body: "x" }
        verify(Matcher.match({ name: "a", app: "app" }, e))
        verify(!Matcher.match({ name: "a", app: "App" }, e))
        verify(Matcher.match({ name: "a", match: "failed" }, e))
        verify(!Matcher.match({ name: "a", app: "app", match: "nope" }, e))
        verify(!Matcher.match({ name: "empty", mute: true }, e))
        verify(!Matcher.match({ name: "bad", match: "(" }, e))
    }
    function test_app_name_regexp() {
        const e = { appName: "Org.Gnome.Calendar", appId: "", summary: "s", body: "b" }
        verify(Matcher.match({ name: "a", appMatch: "^org\\.gnome\\." }, e))
        verify(Matcher.match({ name: "a", appMatch: "calendar$" }, e))
        verify(!Matcher.match({ name: "a", appMatch: "^calendar" }, e))
        verify(!Matcher.match({ name: "a", appMatch: "gnome", match: "nope" }, e))
        verify(!Matcher.match({ name: "bad", appMatch: "(" }, e))
        compare(Config.ComponentSpec.validRules([{ name: "a", appMatch: "(" }]), "rule 1: appMatch is not a valid regular expression")
        compare(Config.ComponentSpec.validRules([{ name: "a", appMatch: 3 }]), "rule 1: appMatch must be a string")
        compare(Config.ComponentSpec.validRules([{ name: "a", appMatch: "^x" }]), "")
    }
}

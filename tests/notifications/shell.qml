//@ pragma ShellId ui-shell-notifications-test
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "adapters" as Adapters
import "components" as Controls
import "modules/notifications" as Notif
import "theme" as Theme

// Nested-session test: real NotifSource on the real session bus, real popup windows. It sends with
// notify-send, asserts NotifCenter state per phase and prints NOTIF_PASS or NOTIF_FAIL.
ShellRoot {
    id: root
    property string phase: "normal"
    property string sentId: ""
    property double deadline: Date.now() + 20000
    property bool sent: false
    readonly property var center: Notif.NotifCenter
    Component.onCompleted: center.source = Adapters.NotifSource
    Instantiator {
        model: Quickshell.screens
        Notif.NotifPopupSurface {}
    }

    // A real drawer stack, as the drawer builds it, for the "stack" phase.
    Theme.MonitorStyle {
        id: stackStyle
        palette: Theme.ActivePalettes.forOutput(Quickshell.screens[0].name)
    }
    Controls.InputState { id: stackInput; pointerActive: false }
    FloatingWindow {
        id: stackWindow
        visible: true
        implicitWidth: 420
        implicitHeight: 600
        Notif.NotifStack {
            id: stack
            width: parent.width
            group: root.center.groups.find(g => g.appName === "t-burst") ?? { appName: "t-burst", items: [] }
            style: stackStyle
            inputState: stackInput
        }
    }

    function log(text) { console.log("notif-test: " + text) }
    function fail(text) { console.log("NOTIF_FAIL " + text); Qt.quit() }
    function advance(name) { phase = name; sent = false; deadline = Date.now() + 20000 }
    function send(args) {
        sender.exec(["notify-send"].concat(args))
        sent = true
    }
    function sendShell(script) {
        sender.exec(["bash", "-c", script])
        sent = true
    }
    Process {
        id: sender
        stdout: StdioCollector { id: out; onStreamFinished: root.sentId = out.text.trim() }
    }
    function lastWith(app) { return center.entries.find(e => e.appName === app) }

    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (Date.now() > root.deadline) return root.fail("timeout in phase " + root.phase + " entries=" + root.center.entries.length)
            const c = root.center
            if (root.phase === "normal") {
                if (!root.sent) root.send(["-a", "t-normal", "-u", "normal", "One", "first body"])
                else if (c.entries.length === 1 && c.popup && c.popup.summary === "One" && c.unread === 1) root.advance("progress")
            } else if (root.phase === "progress") {
                if (!root.sent) { root.sendShell("notify-send -p -a t-progress -h int:value:10 Prog ten"); root.sent = true }
                else if (root.sentId !== "" && root.lastWith("t-progress") && root.lastWith("t-progress").progress === 10) {
                    root.sendShell("notify-send -r " + root.sentId + " -a t-progress -h int:value:40 Prog forty")
                    root.advance("progress-check")
                }
            } else if (root.phase === "progress-check") {
                const e = root.lastWith("t-progress")
                if (e && e.progress === 40 && c.entries.length === 2) root.advance("burst")
            } else if (root.phase === "burst") {
                if (!root.sent) root.sendShell("for i in $(seq 1 100); do notify-send -a t-burst \"Burst $i\" body; done")
                else if (c.entries.length === 102) {
                    if (c.popup === null || c.popup.summary !== "Burst 100") return root.fail("newest does not win: " + (c.popup ? c.popup.summary : "none"))
                    root.advance("dnd")
                }
            } else if (root.phase === "dnd") {
                if (!root.sent) { c.setDnd(true); root.send(["-a", "t-dnd", "Quiet", "no popup"]) }
                else if (c.entries.length === 103) {
                    if (c.popup !== null) return root.fail("popup shown under DND")
                    if (c.unread !== 103) return root.fail("unread " + c.unread)
                    c.setDnd(false)
                    root.advance("stack")
                }
            } else if (root.phase === "stack") {
                if (stack.count !== 100) return root.fail("stack count " + stack.count)
                if (!root.sent) {
                    if (stack.mountedCount !== 4) return root.fail("collapsed deck mounts " + stack.mountedCount)
                    c.toggleGroup("t-burst")
                    root.sent = true
                }
                else if (stack.mountedCount === 100) {
                    c.toggleGroup("t-burst")
                    root.advance("stack-collapse")
                }
            } else if (root.phase === "stack-collapse") {
                if (stack.mountedCount !== 4) return
                if (!root.sent) {
                    root.sent = true
                    stack.dismiss(c.groups.find(g => g.appName === "t-burst").items[0].id)
                    return
                }
                if (stack.count === 100) return
                if (stack.count !== 99) return root.fail("delete one left " + stack.count)
                root.advance("clear")
            } else if (root.phase === "clear") {
                c.markAllRead()
                if (c.unread !== 0) return root.fail("unread after markAllRead " + c.unread)
                c.clearAll()
                if (c.entries.length !== 0) return root.fail("clearAll left entries")
                root.advance("pause")
                console.log("NOTIF_PASS")
                Qt.quit()
            }
        }
    }
}

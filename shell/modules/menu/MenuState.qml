pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "../../config" as Config

// What the menu shows and what it answers. Programs reach the shell through scripts/menu, which
// puts a request directory into the spool under the runtime directory; this watches the spool,
// queues what it finds (one tab per app) and writes the answer back. The shell is also the only
// writer of `.shell`, the file that tells scripts/menu a shell is running.
QtObject {
    id: root

    readonly property string spool: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") + "/" + Config.Menu.spoolSubdirectory
    readonly property MenuQueue queue: MenuQueue {}

    // Panels this menu gives way to: while one of them is open the card is hidden, nothing is
    // answered, and the card comes back when they close. Set by shell.qml.
    property var blockers: []
    readonly property bool blocked: root.blockers.some(panel => panel.open)

    // The card is mapped while a request waits.
    readonly property bool open: root.queue.open
    property string screenName: ""
    // Every request directory in the spool, by name, as its MenuRequest object.
    property var requests: ({})

    // Set when the spool exists and `.shell` is written; the listing starts only then.
    property bool ready: false

    // The request the card shows, or null.
    readonly property var visibleRequest: root.queue.visible

    function admit(request) {
        root.queue.add({ id: request.fileName, app: request.app, pid: request.callerPid, prompt: request.prompt, lines: request.lines })
    }
    // A request that cannot be shown or whose caller is gone: it leaves the queue and its directory
    // is removed. Its object stays in `requests` until the directory is really gone from the spool,
    // so it is never read a second time.
    // `reason` is logged with the request name only, never with its lines.
    function discard(request, reason) {
        console.info("Menu: request " + request.fileName + " dropped: " + reason)
        root.queue.remove(request.fileName)
        Quickshell.execDetached(["rm", "-rf", "--", request.filePath])
    }
    // Makes the spool listing the one truth: every request directory gets one MenuRequest for as
    // long as it exists, and an answered one is not admitted again. The listing is read afresh from
    // the file system each time something changed, so a reset of the folder model cannot drop or
    // repeat a request.
    function reconcile(output) {
        const present = output.split("\n").filter(name => name !== "")
        for (const name of Object.keys(root.requests)) {
            if (present.includes(name)) continue
            root.queue.remove(name)
            root.requests[name].destroy()
            delete root.requests[name]
        }
        for (const name of present) {
            if (root.requests[name] !== undefined) continue
            const request = root.requestFactory.createObject(root, { fileName: name, filePath: root.spool + "/" + name })
            request.ready.connect(() => root.admit(request))
            request.rejected.connect(() => root.discard(request, "unreadable request"))
            request.callerGone.connect(() => root.discard(request, "its caller process ended"))
            root.requests[name] = request
            // A name scripts/menu never makes: nothing in it is read.
            if (!request.wellNamed) root.discard(request, "not a request name")
        }
    }
    // Reads the spool again; a change that arrives during a read starts one more read after it.
    function requestScan() {
        if (!root.ready) return
        if (root.scan.running) root.scanAgain = true
        else root.scan.running = true
    }

    // Both answers do nothing while a blocker panel is open: the card is hidden then.
    // Answers the shown request with the line at `index` (counted from 0 in the unfiltered list).
    function choose(index) {
        const shown = root.queue.visible
        if (!shown || root.blocked || index < 0 || index >= shown.lines.length) return
        root.finish(shown, "Y" + (index + 1))
    }
    // Answers the shown request with no choice.
    function cancel() {
        const shown = root.queue.visible
        if (!shown || root.blocked) return
        console.info("Menu: request " + shown.id + " answered with no choice")
        root.finish(shown, "")
    }
    function finish(shown, text) {
        const request = root.requests[shown.id]
        if (request) request.reply(text)
        root.queue.remove(shown.id)
    }

    onOpenChanged: {
        if (!open) return
        const target = Config.Outputs.launcherScreen(Quickshell.screens)
        if (target) screenName = target.name
    }

    // Makes the spool (closed to everyone else), empties it of requests left by a shell that did
    // not end cleanly, and writes this process id for scripts/menu to find.
    property Process prepare: Process {
        running: root.spool.startsWith("/")
        command: ["sh", "-c", `
            umask 077
            d=$1
            mkdir -p -- "$d" || exit 1
            chmod 700 -- "$d" || exit 1
            find "$d" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + || exit 1
            printf '%s\\n' "$2" > "$d/.shell.tmp" || exit 1
            mv -f -- "$d/.shell.tmp" "$d/.shell"
        `, "sh", root.spool, String(Quickshell.processId)]
        onExited: (code, status) => {
            if (code === 0) root.ready = true
            else console.warn("Menu: the spool could not be prepared (exit " + code + "); requests will not be shown")
        }
    }

    property FolderListModel listing: FolderListModel {
        folder: root.ready ? "file://" + root.spool : ""
        showFiles: false
        showDirs: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
    }
    // Only a signal that the spool changed: what is in it is read by `scan`.
    property Connections listingChanges: Connections {
        target: root.listing
        function onCountChanged() { root.requestScan() }
        function onRowsInserted() { root.requestScan() }
        function onRowsRemoved() { root.requestScan() }
        function onModelReset() { root.requestScan() }
        function onStatusChanged() { root.requestScan() }
    }
    onReadyChanged: root.requestScan()
    property bool scanAgain: false
    property Process scan: Process {
        command: ["find", root.spool, "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-not", "-name", ".*", "-printf", "%f\\n"]
        stdout: StdioCollector { onStreamFinished: root.reconcile(text) }
        onExited: {
            if (!root.scanAgain) return
            root.scanAgain = false
            running = true
        }
    }
    property Component requestFactory: Component { MenuRequest {} }

    // UI_SHELL_OPEN_MENU=1 shows one request that needs no program and writes no file.
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_MENU") !== "1") return
        root.queue.add({
            id: "preview", app: "preview", prompt: Config.Menu.previewPrompt,
            lines: Config.Menu.previewLines
        })
    }
}

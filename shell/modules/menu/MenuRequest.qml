import QtQuick
import Quickshell.Io

// One request directory of the spool, written by scripts/menu: `meta`, `items` and the named pipe
// `result`. Reads the first two, watches that the caller is still there, and answers on the pipe.
// It decides nothing about what is shown; MenuState does.
QtObject {
    id: root

    // The model roles of the spool listing.
    required property string fileName
    required property string filePath

    // Both files were read and are valid; `app`, `prompt` and `lines` are set.
    signal ready()
    // The directory is not a request this shell can show; it should be removed.
    signal rejected()
    // The caller went away without an answer.
    signal callerGone()

    property string app: ""
    property string prompt: ""
    property var lines: []
    property int callerPid: 0
    property bool answered: false
    // Set by a failed read or parse of either file.
    property bool broken: false

    readonly property bool wellNamed: /^[0-9]+-[0-9]+$/.test(root.fileName)
    property bool metaRead: false
    property bool itemsRead: false

    function reject() {
        if (root.broken) return
        root.broken = true
        root.rejected()
    }
    function admit() {
        if (!root.metaRead || !root.itemsRead || root.broken) return
        root.watch.command = ["tail", "--pid=" + root.callerPid, "-s", "0.2", "-f", "/dev/null"]
        // After the command, so the process never starts with the previous (empty) one.
        root.watch.running = true
        root.ready()
    }

    // Writes `Y<n>` (the chosen line, counted from 1) or an empty line (no choice) once.
    function reply(text) {
        if (root.answered) return
        root.answered = true
        root.answerText = text
        root.writer.running = true
    }

    property FileView meta: FileView {
        path: root.wellNamed ? root.filePath + "/meta" : ""
        // A request can vanish while it is read (its client went away); onLoadFailed handles it.
        printErrors: false
        onLoaded: {
            let parsed = null
            try { parsed = JSON.parse(text()) } catch (error) { parsed = null }
            if (parsed === null || typeof parsed !== "object"
                    || !Number.isInteger(parsed.pid) || parsed.pid < 1
                    || typeof parsed.app !== "string" || typeof parsed.prompt !== "string") {
                root.reject()
                return
            }
            root.callerPid = parsed.pid
            root.app = parsed.app === "" ? "unknown" : parsed.app
            root.prompt = parsed.prompt
            root.metaRead = true
            root.admit()
        }
        onLoadFailed: root.reject()
    }
    property FileView items: FileView {
        path: root.wellNamed ? root.filePath + "/items" : ""
        printErrors: false
        onLoaded: {
            const content = text()
            const split = content.split("\n")
            // The file ends with a newline: that is the end of the last line, not another line.
            if (split.length > 1 && split[split.length - 1] === "") split.pop()
            root.lines = split
            root.itemsRead = true
            root.admit()
        }
        onLoadFailed: root.reject()
    }
    // Exits when the caller's process is gone.
    property Process watch: Process {
        onExited: root.callerGone()
    }
    // `cat` opens the pipe for writing, which the waiting client has open for reading.
    property string answerText: ""
    property Process writer: Process {
        stdinEnabled: true
        command: ["sh", "-c", "cat > \"$1/result\"", "sh", root.filePath]
        onStarted: {
            write(root.answerText + "\n")
            stdinEnabled = false
        }
    }
}

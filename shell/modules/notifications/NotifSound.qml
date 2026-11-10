import QtQuick
import Quickshell.Io

// Plays one sound file through the configured notify-sound script. Failures only log.
QtObject {
    id: root
    required property string command
    function play(path) {
        if (command === "" || path === "") return
        const p = runner.createObject(root, { command: [root.command, path] }) as Process
        p.running = true
    }
    property Component runner: Component {
        Process {
            id: proc
            onExited: code => {
                if (code !== 0) console.warn("notify-sound exit " + code)
                proc.destroy()
            }
        }
    }
}

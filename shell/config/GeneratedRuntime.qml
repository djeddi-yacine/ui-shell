pragma Singleton
import QtQuick

// Source-tree declaration only. Staging replaces it from config.ini before use.
QtObject {
    readonly property string configFile: ""
    readonly property var paths: ({})
    readonly property var commands: ({})
    readonly property var bootstrap: ({})
    readonly property var bundle: ({})
    readonly property var profileColors: ({
        defaultPalette: undefined,
        byOutput: ({}),
        globalPalette: undefined
    })
    readonly property var wallpaperTargets: undefined
    readonly property var xdg: ({})
    readonly property var theme: ({})
    readonly property var wallpaperFolders: []
}

pragma Singleton

import QtQuick

QtObject {
    // Live palette data is loaded explicitly; generated source writes must not
    // restart the shell or discard an in-flight editor operation.
    readonly property bool watchSourceFiles: false
    readonly property bool barEnabled: true
    readonly property bool appLauncherEnabled: true
    readonly property bool notificationsEnabled: Notifications.enabled
    readonly property bool controlTuningEnabled: true
    readonly property bool audioControlEnabled: true
    readonly property bool screenRecordEnabled: true
    readonly property bool screenShotEnabled: true
    readonly property bool authEnabled: true
    readonly property bool clipboardEnabled: true
    // The media control: bar icon, panel and panel key. The media keys have their own switch (phase 2).
    readonly property bool mprisEnabled: true
    // The keyboard media keys (play or pause, pause, next, previous) are handled by the shell.
    readonly property bool mprisKeysEnabled: true
    readonly property int barHeight: 32
    readonly property string barLabel: "ui-shell"
    readonly property list<int> barWorkspaceNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    readonly property bool barWorkspacesEnabled: true
    // Control mode for the bar alone (a key from scripts/control-model/modes.json); empty follows the global mode.
    readonly property string barControlMode: ""
}

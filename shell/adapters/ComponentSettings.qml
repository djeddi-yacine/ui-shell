pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "../config" as Config

Item {
    id: root
    required property string component
    required property string screenName
    readonly property bool ready: shared.ready && monitor.ready
    readonly property bool loading: shared.reading || monitor.reading
    readonly property bool busy: saving || verifyingScope.length > 0
    readonly property string loadError: shared.error || monitor.error
    property string saveError: ""
    property bool saving: false
    property string verifyingScope: ""
    property string savedScope: ""
    property int failureSequence: 0
    property var failure: null
    readonly property bool showIcons: value("showIcons", Config.AppLauncher.showIcons)
    readonly property int visibleRows: value("visibleRows", Config.AppLauncher.visibleRows)
    readonly property int wideColumns: value("wideColumns", Config.WallpaperPicker.wideColumns)
    readonly property int maximumVisibleRows: value("maximumVisibleRows", Config.WallpaperPicker.maximumVisibleRows)
    signal scopeReady(string scope)
    signal committed(string scope)
    signal failed()

    // An option's effective value for this component: output override, shared default, then
    // the explicit default declared in Config.ComponentSpec.
    function option(key) {
        const entry = Config.ComponentSpec.components[component].find(item => item.key === key)
        return value(key, entry ? entry.fallback : undefined)
    }
    function value(key, configuredDefault) {
        const override = monitor.values[key]
        return override === undefined ? sharedValue(key, configuredDefault) : override
    }
    function sharedValue(key, configuredDefault) {
        const override = shared.values[key]
        return override === undefined ? configuredDefault : override
    }
    function fileForScope(scope) { return scope === "default" ? shared : monitor }
    function refresh() { shared.refresh(); monitor.refresh() }
    function reportFailure(scope, saving, diagnostic) {
        failureSequence += 1
        failure = { source: "component-settings", sequence: failureSequence,
            title: saving ? qsTr("Settings save failed") : qsTr("Settings load failed"),
            message: saving ? qsTr("The settings were not committed. Your draft is still open.")
                : qsTr("These settings could not be loaded. The last valid values have not been replaced."),
            operation: saving ? qsTr("Save %1 settings").arg(component) : qsTr("Load %1 settings").arg(component),
            target: scope === "default" ? qsTr("Shared default") : qsTr("Output: %1").arg(screenName),
            details: [fileForScope(scope).path ? qsTr("File: %1").arg(fileForScope(scope).path) : "", diagnostic]
                .filter(value => value.length > 0).join("\n") }
        failed()
    }
    function settled(scope) {
        scopeReady(scope)
        if (verifyingScope !== scope) {
            if (fileForScope(scope).error) reportFailure(scope, false, fileForScope(scope).error)
            return
        }
        verifyingScope = ""
        if (fileForScope(scope).error) { saveError = fileForScope(scope).error; reportFailure(scope, true, saveError) }
        else committed(scope)
    }
    function save(scope, revision, first, second) {
        if (busy || (scope !== "default" && scope !== "output")) return
        saveError = ""
        savedScope = scope
        saving = true
        writer.command = [Config.GeneratedRuntime.commands.saveComponentSettings, component,
            scope, scope === "default" ? "" : screenName, revision, String(first), String(second)]
        writer.running = true
    }
    QmlSettingsFile {
        id: shared
        component: root.component
        scope: "default"
        outputName: ""
        onSettled: root.settled(scope)
    }
    QmlSettingsFile {
        id: monitor
        component: root.component
        scope: "output"
        outputName: root.screenName
        onSettled: root.settled(scope)
    }
    Process {
        id: writer
        stderr: StdioCollector { id: writerError }
        onExited: function(exitCode, exitStatus) {
            root.saving = false
            if (exitCode !== 0 || exitStatus !== 0) {
                root.saveError = writerError.text.trim() || qsTr("Could not save component settings.")
                root.reportFailure(root.savedScope, true, root.saveError)
                return
            }
            root.verifyingScope = root.savedScope
            root.fileForScope(root.savedScope).refresh()
        }
        onRunningChanged: {
            if (!running && root.saving) {
                root.saving = false
                root.saveError = qsTr("Could not start settings writer.")
                root.reportFailure(root.savedScope, true, root.saveError)
            }
        }
    }
}

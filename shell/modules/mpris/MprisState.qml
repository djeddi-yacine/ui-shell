pragma Singleton
import QtQuick
import Quickshell
import "../../adapters" as Adapters
import "../../config" as Config

// The media control's shared state: the panel's open state and the one selection that the bar
// icon, the panel and (phase 2) the media keys all read. It exists whenever something refers
// to it, so the keys can work with the panel closed.
QtObject {
    id: root
    property bool open: false
    property string screenName: ""
    // UI_SHELL_MPRIS_SOURCE: real (the session's players), preview (fake players, for looking at
    // the panel) or off (no players; the nested test session has none, and a real watcher could
    // log a warning the harness treats as fatal).
    readonly property string sourceMode: Quickshell.env("UI_SHELL_MPRIS_SOURCE") || "real"
    readonly property var source: sourceMode === "preview" ? previewSource : sourceMode === "off" ? offSource : Adapters.MprisSource
    property QtObject offSource: QtObject { readonly property var players: [] }
    property Component previewComponent: Component { PreviewSource {} }
    property var previewSource: sourceMode === "preview" ? previewComponent.createObject(root) : null
    readonly property Adapters.MediaSelection selection: Adapters.MediaSelection { source: root.source }
    // The art setting (auto, cover, blurhash or off): the open panel sets it from its Ctrl+E
    // settings. It applies to every player; auto uses the per-player table.
    property string artMode: Config.Mpris.artMode
    readonly property string cacheDir: Quickshell.env("UI_SHELL_MPRIS_DIR") || ((Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ui-shell/mpris")
    // What the backdrop shows: `state`, `kind` and `path`. It works only while the panel is open.
    readonly property Adapters.MediaArt art: Adapters.MediaArt {
        runner: Adapters.MediaArtRunner {}
        player: root.selection.current
        keyOf: root.selection.keyOf
        enabled: root.open
        forcedMode: root.artMode
        defaultMode: Config.Mpris.artDefaultMode
        modes: Config.Mpris.artModes
        providers: Config.Mpris.providers
        cacheDir: root.cacheDir
        debounceMs: Config.Mpris.artDebounceMs
        shrinkSize: Config.Mpris.artShrinkSize
        blurhashComponents: Config.Mpris.blurhashComponents
        blurhashDecodeSize: Config.Mpris.blurhashDecodeSize
        downloadMaxBytes: Config.Mpris.downloadMaxBytes
        stepTimeoutSeconds: Config.Mpris.stepTimeoutSeconds
        shrinkTools: Config.Mpris.shrinkTools
        hotEntries: Config.Mpris.hotCacheEntries
        blurhashEncoder: Config.Mpris.blurhashEncoder
        blurhashDecoder: Config.Mpris.blurhashDecoder
        cacheMaxBytes: Config.Mpris.cacheMaxBytes
        cacheMaxEntries: Config.Mpris.cacheMaxEntries
        failureMemorySeconds: Config.Mpris.failureMemorySeconds
    }
    // The settings offer the blurhash mode only when the tool check found its tools.
    property Binding offerBlurhash: Binding { target: Config.Mpris; property: "blurhashAvailable"; value: root.art.blurhashAvailable }
    Component.onCompleted: {
        if (Quickshell.env("UI_SHELL_OPEN_MPRIS") === "1") {
            const output = Config.Outputs.launcherScreen(Quickshell.screens)
            if (output) show(output.name)
        }
    }
    function show(output) {
        screenName = output
        open = true
    }
}

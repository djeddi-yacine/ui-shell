//@ pragma ShellId ui-shell
//@ pragma AppId org.ui.shell
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "surfaces" as Surfaces
import "modules/wallpaper" as Wallpaper
import "components" as Controls
import "modules/apps" as Apps
import "modules/tuning" as Tuning
import "modules/audio" as Audio
import "modules/record" as Record
import "modules/shot" as Shot
import "modules/auth" as Auth
import "modules/mpris" as Mpris
import "adapters" as Adapters
import "config" as Config

ShellRoot {
    Component.onCompleted: {
        Quickshell.watchFiles = Config.Config.watchSourceFiles
        // Apply the saved control-colour tuning before the first surface renders.
        Adapters.ControlTuningStore.reload()
    }
    Controls.InputState {
        id: shellInput
        pointerActive: false
    }
    Wallpaper.PickerShortcut {}
    Loader {
        active: Config.Config.appLauncherEnabled
        sourceComponent: Apps.AppShortcut {}
    }
    Loader {
        active: Config.Config.controlTuningEnabled
        sourceComponent: Tuning.TuningShortcut {}
    }
    Loader {
        active: Config.Config.audioControlEnabled
        sourceComponent: Audio.AudioShortcut {}
    }
    Loader {
        active: Config.Config.screenRecordEnabled
        sourceComponent: Record.RecordShortcut {}
    }
    Loader {
        active: Config.Config.screenShotEnabled
        sourceComponent: Shot.ShotShortcut {}
    }
    Loader {
        active: Config.Config.mprisEnabled
        sourceComponent: Mpris.MprisShortcut {}
    }
    Loader {
        active: Config.Config.mprisKeysEnabled
        sourceComponent: Mpris.MprisKeys {}
    }
    // The authentication dialog is modal: it appears over whatever is open and is not part of
    // the panel mutual exclusion below.
    Auth.AuthSurface {}
    Connections {
        target: Record.RecordPanelState
        function onOpenChanged() { if (Record.RecordPanelState.open) { Wallpaper.PickerState.open = false; Apps.AppState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false; Shot.ShotPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Shot.ShotPanelState
        function onOpenChanged() { if (Shot.ShotPanelState.open) { Wallpaper.PickerState.open = false; Apps.AppState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false; Record.RecordPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Tuning.TuningState
        function onOpenChanged() { if (Tuning.TuningState.open) { Record.RecordPanelState.open = false; Shot.ShotPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Audio.AudioState
        function onOpenChanged() { if (Audio.AudioState.open) { Record.RecordPanelState.open = false; Shot.ShotPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Apps.AppState
        function onOpenChanged() { if (Apps.AppState.open) { Wallpaper.PickerState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false; Record.RecordPanelState.open = false; Shot.ShotPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Wallpaper.PickerState
        function onOpenChanged() { if (Wallpaper.PickerState.open) { Apps.AppState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false; Record.RecordPanelState.open = false; Shot.ShotPanelState.open = false; Mpris.MprisState.open = false } }
    }
    Connections {
        target: Mpris.MprisState
        function onOpenChanged() { if (Mpris.MprisState.open) { Wallpaper.PickerState.open = false; Apps.AppState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false; Record.RecordPanelState.open = false; Shot.ShotPanelState.open = false } }
    }

    Variants {
        model: Quickshell.screens

        Surfaces.BarSurface { inputState: shellInput }
    }

    Variants {
        model: Quickshell.screens

        Wallpaper.PickerSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.appLauncherEnabled ? Quickshell.screens : []
        Apps.AppSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.controlTuningEnabled ? Quickshell.screens : []
        Tuning.TuningSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.audioControlEnabled ? Quickshell.screens : []
        Audio.AudioSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.screenRecordEnabled ? Quickshell.screens : []
        Record.RecordSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.screenShotEnabled ? Quickshell.screens : []
        Shot.ShotSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.mprisEnabled ? Quickshell.screens : []
        Mpris.MprisSurface { inputState: shellInput }
    }
}

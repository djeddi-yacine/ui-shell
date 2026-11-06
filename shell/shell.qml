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
    Connections {
        target: Apps.AppState
        function onOpenChanged() { if (Apps.AppState.open) { Wallpaper.PickerState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false } }
    }
    Connections {
        target: Wallpaper.PickerState
        function onOpenChanged() { if (Wallpaper.PickerState.open) { Apps.AppState.open = false; Tuning.TuningState.open = false; Audio.AudioState.open = false } }
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
}

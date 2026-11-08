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
import "modules/panels" as Panels
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
    // Only one of these panels is open at a time; opening one closes the others.
    Panels.PanelGroup {
        panels: [
            Record.RecordPanelState, Shot.ShotPanelState, Tuning.TuningState, Audio.AudioState,
            Apps.AppState, Wallpaper.PickerState, Mpris.MprisState
        ]
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

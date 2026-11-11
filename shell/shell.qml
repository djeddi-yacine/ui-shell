//@ pragma ShellId ui-shell
//@ pragma AppId org.ui.shell
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import "surfaces" as Surfaces
import "modules/wallpaper" as Wallpaper
import "components" as Controls
import "modules/apps" as Apps
import "modules/tuning" as Tuning
import "modules/audio" as Audio
import "modules/record" as Record
import "modules/shot" as Shot
import "modules/auth" as Auth
import "modules/clipboard" as Clipboard
import "modules/menu" as Menu
import "modules/mpris" as Mpris
import "modules/notifications" as Notif
import "modules/panels" as Panels
import "adapters" as Adapters
import "config" as Config

ShellRoot {
    Component.onCompleted: {
        Quickshell.watchFiles = Config.Config.watchSourceFiles
        // Apply the saved control-colour tuning before the first surface renders.
        Adapters.ControlTuningStore.reload()
        Notif.NotifCenter.source = Adapters.NotifSource
        // The panels the menu gives way to: the members of the group below.
        Menu.MenuState.blockers = [
            Record.RecordPanelState, Shot.ShotPanelState, Tuning.TuningState, Audio.AudioState,
            Apps.AppState, Wallpaper.PickerState, Mpris.MprisState, Notif.NotifState, Clipboard.ClipboardState
        ]
    }
    Adapters.QmlSettingsFile {
        id: notifRulesFile
        component: "notifications"
        scope: "default"
        outputName: ""
    }
    // The rules are read once, when the shell starts: a saved edit applies at the next start.
    Notif.NotifRules { id: notifRules; file: notifRulesFile }
    Notif.NotifSound { id: notifSound; command: Config.GeneratedRuntime.commands.notifySound ?? "" }
    Connections {
        target: Notif.NotifCenter
        function onSoundRequested(path) { notifSound.play(path) }
    }
    Notif.NotifFeeds {
        center: Notif.NotifCenter
        shotRunner: Adapters.ShotRunner
        recordState: Adapters.RecordState
    }
    Binding { target: Notif.NotifCenter; property: "redact"; value: Adapters.RecordState.active }
    Binding {
        target: Notif.NotifCenter
        property: "fullscreen"
        value: Hyprland.focusedMonitor?.activeWorkspace?.hasFullscreen ?? false
    }
    Binding { target: Notif.NotifCenter; property: "rules"; value: notifRules }
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
        active: Config.Config.clipboardEnabled
        sourceComponent: Clipboard.ClipboardShortcut {}
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
    Loader {
        active: Config.Config.notificationsEnabled
        sourceComponent: Notif.NotifShortcut {}
    }
    Variants {
        model: Config.Config.notificationsEnabled ? Quickshell.screens : []
        Notif.NotifPopupSurface {}
    }
    Variants {
        model: Config.Config.notificationsEnabled ? Quickshell.screens : []
        Notif.NotifSurface { inputState: shellInput }
    }
    // Only one of these panels is open at a time; opening one closes the others.
    Panels.PanelGroup {
        panels: [
            Record.RecordPanelState, Shot.ShotPanelState, Tuning.TuningState, Audio.AudioState,
            Apps.AppState, Wallpaper.PickerState, Mpris.MprisState, Notif.NotifState, Clipboard.ClipboardState
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
        model: Config.Config.screenShotEnabled ? Quickshell.screens : []
        Shot.WindowPickSurface {}
    }
    Variants {
        model: Config.Config.screenShotEnabled || Config.Config.screenRecordEnabled ? Quickshell.screens : []
        Shot.RegionPickSurface {}
    }
    Variants {
        model: Config.Config.mprisEnabled ? Quickshell.screens : []
        Mpris.MprisSurface { inputState: shellInput }
    }
    Variants {
        model: Config.Config.clipboardEnabled ? Quickshell.screens : []
        Clipboard.ClipboardSurface { inputState: shellInput }
    }
    // The menu other programs call through scripts/menu. It gives way to any panel of the group
    // above (hidden while one is open, back when it closes) and never answers on its own.
    Variants {
        model: Quickshell.screens
        Menu.MenuSurface { inputState: shellInput }
    }
}

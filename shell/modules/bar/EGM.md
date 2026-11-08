# bar

## Overview
Per-output top bar content: a labelled button for every panel (Launcher, Wallpaper, Tuning, Audio, Screenshot, Record, Media; development scaffolding until the bar is designed), Hyprland workspace buttons and the output name. No qmldir; imported by relative path.

## Interface
- `Bar`: `Item` with `screenName`, `inputState` [bar/Bar.qml:Bar]
- `PanelButton`: labelled toggle for one panel (`panelState` with `open`, `screenName`, `show(output)`); used for Tuning, Audio and Screenshot [bar/PanelButton.qml]
- `RecordButton`: bar entry for recording; idle opens the panel, while recording shows the elapsed time and a `PopupWindow` with the target and Stop [bar/RecordButton.qml]
- `WorkspaceNumbers`: `RowLayout` with `screenName`, `style`, `inputState`, `monitor` (`HyprlandMonitor`) [bar/WorkspaceNumbers.qml:WorkspaceNumbers]

## Invariants
- "Apps" button is shown only if `ShellConfig.Config.appLauncherEnabled`; workspaces only if `barWorkspacesEnabled` [bar/Bar.qml].
- Workspace buttons come from `ShellConfig.Config.barWorkspaceNumbers` and are disabled when no `HyprlandMonitor` matches `screenName` [bar/WorkspaceNumbers.qml:enabled].
- Bar style uses `Theme.ActivePalettes.forOutput(screenName)` and `Config.barControlMode` [bar/Bar.qml:styleTokens].

## Side Effects
- Clicking Apps calls `Apps.AppState.show(screenName)` [bar/Bar.qml].
- Clicking the label sets `Wallpaper.PickerState.screenName/targetOutput/open` [bar/Bar.qml].
- Workspace click runs `Hyprland.dispatch('hl.dsp.focus({ workspace = "N" })')` [bar/WorkspaceNumbers.qml:onClicked].

## Verification
- Run: `make test-qml`
- `AuthChip` [AuthChip.qml]: "No auth agent" entry, visible only when `Config.authEnabled`, the start-up grace has passed and `AuthState.auth.agentActive` is false; click explains why in an inline popup.
- `MprisButton` [MprisButton.qml]: the media control's bar entry: one fixed icon (`audio-player`), the same in every state; the panel shows the state and the pin; visible by `Config.Mpris.iconVisibility`; click opens the panel.

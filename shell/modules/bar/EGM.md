# bar

## Overview
Per-output top bar content: launcher button, wallpaper-picker button, Hyprland workspace buttons and the output name. No qmldir; imported by relative path.

## Interface
- `Bar`: `Item` with `screenName`, `inputState` [bar/Bar.qml:Bar]
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

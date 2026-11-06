# shell Blueprint

## System Overview
`shell/` is the Quickshell (QML) rice: a top bar plus four on-demand panels (wallpaper picker, app launcher, control tuning, audio, screen recording, screenshot). Each panel is a self-contained module under `modules/` with a state singleton, a global shortcut, a layer-shell surface and a panel. Panels share controls and popups from `components/`, colours and control look from `theme/`, options from `config/`, and reach processes only through `adapters/`. Nothing here runs a daemon of its own.

## Local Interface & Invariants
- `shell.qml`: `ShellRoot` that creates one `InputState` (`shellInput`) and, per output via `Variants`, `Surfaces.BarSurface`, `Wallpaper.PickerSurface`, `Apps.AppSurface`, `Tuning.TuningSurface` and `Audio.AudioSurface` [shell.qml:ShellRoot, Variants].
- `Wallpaper.PickerShortcut` is always created; `Apps.AppShortcut`, `Tuning.TuningShortcut` and `Audio.AudioShortcut` load only when `Config.Config.appLauncherEnabled`, `controlTuningEnabled` and `audioControlEnabled` are true [shell.qml:Loader].
- On startup it sets `Quickshell.watchFiles` from `Config.Config.watchSourceFiles` and calls `Adapters.ControlTuningStore.reload()` before any surface renders [shell.qml:Component.onCompleted].
- Only one panel is open at a time: opening one sets the others' `open` to false through `Connections` on each state singleton [shell.qml:onOpenChanged].

## Subdirectories & System Boundaries
- adapters: [./adapters/EGM.md](./adapters/EGM.md) - process-wrapping adapters (app2unit, audio graph, settings files, theme profiles, tuning store).
- components: [./components/EGM.md](./components/EGM.md) - shared controls and the context, error, exit and colour popups.
- config: [./config/EGM.md](./config/EGM.md) - singleton configuration, key maps, component option tables, generated runtime placeholders.
- modules: [./modules/EGM.md](./modules/EGM.md) - the panels: apps, audio, bar, record, shot, themes, tuning, wallpaper.
- surfaces: [./surfaces/EGM.md](./surfaces/EGM.md) - the layer-shell window that hosts the bar.
- theme: [./theme/EGM.md](./theme/EGM.md) - palette, shape, density, typography, motion, control colours and tuning.

## Global Invariants
- Panels talk to the system only through `adapters/`; `components/` and `theme/` start no processes (see each child contract).
- Esc leaves; a panel with unsaved work asks through `components` `ExitDialog` first (see [./components/EGM.md](./components/EGM.md)).
- New surfaces load their panel asynchronously (`Config.<Module>.asynchronousPanelLoad`) so popups do not distort the window.

## Global Side Effects
- Per-output layer-shell windows reserve or cover screen space (`ui-shell-*` namespaces, see [./modules/EGM.md](./modules/EGM.md) and [./surfaces/EGM.md](./surfaces/EGM.md)).
- Helper scripts run through adapters: app2unit, the audio graph helper with a `pw-dump --monitor` watcher, theme and settings readers/writers (see [./adapters/EGM.md](./adapters/EGM.md)).

## System Verification
- Run: `make test-qml` (defined in `tests/targets.mk`, included by the root `Makefile`).
- Authentication dialog: `modules/auth` over `adapters/PolkitAuth` and `components/SecretDialog` (design `features/designs/polkit.md`). The polkit agent lives in the shell process, so it needs no daemon of its own.

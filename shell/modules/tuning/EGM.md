# tuning (Control Tuning Panel)

## Overview
Bottom-docked overlay card for live-previewing control colour/behaviour modes and sliders. Package URI `UiShell.Tuning` ([tuning/qmldir]). The editing logic lives in `Controls.ControlTuningEditor`, persisted by `Adapters.ControlTuningStore`.

## Interface
- `TuningState` singleton: `open`, `screenName`, `show(output)` [tuning/TuningState.qml:TuningState]
- `TuningShortcut`: `GlobalShortcut` (`Config.Tuning.shortcutAppId`/`shortcutName`) that toggles `TuningState.open` [tuning/TuningShortcut.qml:onPressed]
- `TuningSurface`: per-screen `PanelWindow`; full-output, no input mask; a click on the backdrop leaves like Esc (asks first when dirty) [tuning/TuningPanel.qml:TuningPanel]
- `TuningPanel`: `cardItem`, `closed()`, `activate()`, `requestClose()`, `showContext(kind)` [tuning/TuningPanel.qml:TuningPanel]

## Invariants
- Pointer events outside the card pass through to the shell underneath [tuning/TuningSurface.qml:mask].
- `requestClose()` discards unsaved edits (`editor.discard()`); Esc with `editor.dirty` (the draft differs from what the panel opened with: a moved slider or a changed mode) asks via `ExitDialog` first; `modified` only means "differs from the mode preset" and is display-only [tuning/TuningPanel.qml:requestClose, exit].
- `settings` for the context popup is null; the "settings" kind is a no-op [tuning/TuningPanel.qml:showContext].
- `editor.begin()` runs on `activate()` and focus goes to the first slider on the next event-loop turn (the window is not active yet) so the first Esc works without a click and `editor.onSaved` leaves the panel [tuning/TuningPanel.qml:activate, editor].

## Side Effects
- Reads env `UI_SHELL_OPEN_TUNING=1` at startup [tuning/TuningState.qml:Component.onCompleted].
- Persists tuning via `Adapters.ControlTuningStore` on save [tuning/TuningPanel.qml:editor.store].
- Layer-shell Overlay, namespace `ui-shell-control-tuning`, exclusive keyboard focus while visible [tuning/TuningSurface.qml:WlrLayershell].
- Registers a Hyprland global shortcut [tuning/TuningShortcut.qml].

## Verification
- Run: `make test-qml`

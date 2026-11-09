# shot

## Overview
The screenshot panel: choose a screen, a window or a region (the shared `Controls.TargetPicker`), choose whether the picture goes to the clipboard, a file or both, then Capture. The panel's window is hidden while the picture is taken so it is not in it, then it comes back showing what was saved, with its size and a Copy path button. Phase 5 of `features/designs/screen-recording.md`.

## Interface
- `ShotPanelState` (singleton): `open`, `screenName`, `capturing`, `initialContext`, `show(output)`; env `UI_SHELL_OPEN_SHOT`, `UI_SHELL_SHOT_CONTEXT` [shot/ShotPanelState.qml].
- `ShotShortcut`: `GlobalShortcut` `ui-shell:screen-shot` toggles the panel [shot/ShotShortcut.qml].
- `ShotSurface`: layer-shell overlay `ui-shell-shot`, hidden while a region is being selected and while capturing [shot/ShotSurface.qml].
- `ShotPanel`: target picker, clipboard and file switches, Capture, last result; `PanelContext` (Ctrl+I/Space/E) and `ErrorPopup` [shot/ShotPanel.qml].

## Invariants
- Capture needs a valid target and at least one destination (clipboard or file) [ShotPanel.qml:canCapture]; the script refuses otherwise.
- The panel is hidden (`capturing`) before the script starts and the script waits `Config.Shot.closeDelayMilliseconds` before capturing [ShotPanel.qml:capture].
- The lists of screens and windows, the last region and the pointer selection come from `Adapters.RecordState` (shared with recording); picked regions are applied only by the open panel [ShotPanel.qml].
- The last picture is announced once and only while its file exists (`ShotRunner.verifyLast`) [ShotPanel.qml:savedHint].
- Saved defaults come from `ComponentSettings{component:"shot"}` (copyToClipboard, saveToFile).

## Side Effects
- A window is captured through its own foreign-toplevel handle (`grim -T <Hyprland stableId>`), not a screen rectangle: right whatever workspace it is on or what covers it; no portal. [scripts/screen-shot:window_handle]
- A picked region is taken at once (panel hidden) into a buffer (`capture --buffer yes`); the button then says Save and `commit` delivers it. `ShotRunner.buffer` holds it; leaving or reopening the panel discards it. [ShotPanel.qml:takeRegion]
- Before grim runs, `screen-shot` waits (bounded) for the `ui-shell-shot` layer to leave `hyprctl layers`, then the configured delay, so the panel is not in the picture.
- `Adapters.ShotRunner.capture` runs `scripts/screen-shot capture` once: grim writes the picture (to `<XDG Pictures>/screenshots` or a temporary file) and `wl-copy` copies it. No state file, no process outlives the call.

## Verification
- Run: `make test-qml`, `make test-shot` (stand-ins) and `make test-shot-live` (real grim and wl-copy on this desktop).

- Window target "Pick": `RecordState.pickWindow()` opens `shot/WindowPickSurface.qml` (an overlay per screen, namespace `ui-shell-window-pick`) that polls `screen-record visible-windows` every 250 ms, so workspace switches and new windows show live. Pointer hover highlights the front-most window; click or Enter picks, Tab and the arrows move, Esc or a right click cancels. The panel hides meanwhile (`RecordState.picking`) and the pick becomes the target [shot/ShotPanel.qml:onWindowPicked].

- Region target: `RecordState.pickRegion()` opens `shot/RegionPickSurface.qml` (an overlay per screen, namespace `ui-shell-region-pick`, shared with the recording panel). Drag draws the rectangle (dimmed surroundings, accent border, round corner handles, a size label) and `shot/Cords.qml` hangs a swinging cord from each screen corner to the selection's matching corner (look from refs/zephyr). Release reports `WxH+X+Y` through `regionPicked` and `screen-record remember-region`; Esc, a right click or a click without a drag cancels. Tunables: `config/RegionPick.qml`.

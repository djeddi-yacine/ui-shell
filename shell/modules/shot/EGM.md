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
- `Adapters.ShotRunner.capture` runs `scripts/screen-shot capture` once: grim writes the picture (to `<XDG Pictures>/screenshots` or a temporary file) and `wl-copy` copies it. No state file, no process outlives the call.

## Verification
- Run: `make test-qml`, `make test-shot` (stand-ins) and `make test-shot-live` (real grim and wl-copy on this desktop).

# record

## Overview
The screen-recording panel: choose a screen, desktop audio and a countdown, then Start. The panel only chooses; the recording runs on its own through `scripts/screen-record`, and the bar entry and the shortcut show and stop it. Phases 1 to 4 of `features/designs/screen-recording.md`: a screen, a window or a region, with desktop audio.

## Interface
- `RecordPanelState` (singleton): `open`, `screenName`, `initialContext`, `show(output)`; env `UI_SHELL_OPEN_RECORD`, `UI_SHELL_RECORD_CONTEXT` for previews [record/RecordPanelState.qml].
- `RecordShortcut`: `GlobalShortcut` `ui-shell:screen-record`; only toggles the panel (it never stops a recording) [record/RecordShortcut.qml].
- `RecordSurface`: layer-shell overlay, namespace `ui-shell-record`, panel loaded asynchronously [record/RecordSurface.qml].
- `RecordPanel`: the shared `Controls.TargetPicker` (screen, window or region), desktop audio toggle, countdown choice, Start; `PanelContext` (Ctrl+I/Space/E) and `ErrorPopup` [record/RecordPanel.qml].

## Invariants
- While a recording starts or runs, the panel shows its clock (or the countdown), target, sound and Stop (focused) instead of the picker; idle, it shows the last saved file with a Copy path button [RecordPanel.qml:runningView, idleView].
- The "Saved" line is news only: it shows the latest saved recording once (`RecordPanelState.displayedResult` / `acknowledgedResult`) and only while its file exists (the script reports a finished recording whose file is gone as idle) [RecordPanel.qml:savedHint].
- Start is enabled only when the recorder is available, the picker holds a valid target and nothing is recording [RecordPanel.qml:canStart].
- Selecting a region with the pointer hides the panel's window (`Adapters.RecordState.picking`) but keeps the panel and its choices; a cancelled selection changes nothing [RecordSurface.qml:visible].
- Desktop audio, microphone and webcam are pickers (Off, default, every device); the pick is kept in `RecordPanelState.picks` for the session and a vanished pick falls back to the saved start, then Off [RecordPanel.qml:resolve].
- The choices apply to one recording; saved defaults come from `ComponentSettings{component:"record"}`: countdown, desktopAudio, microphone, fps, quality, codec, audioCodec, bitrate, container, cursor, webcam (Ctrl+E) [RecordPanel.qml:options].
- Failures reach the user only through `Adapters.RecordState.failed` into the shared `ErrorPopup` [RecordPanel.qml].
- Opening this panel closes the other panels, and they close it [shell.qml].

## Side Effects
- Start runs `Adapters.RecordState.start("monitor:NAME", audio, countdown)`, which spawns the detached recorder wrapper (see `scripts/screen-record`) and closes the panel.
- Layer-shell window `ui-shell-record` while open.

## Verification
- Run: `make test-qml` and `make test-record`

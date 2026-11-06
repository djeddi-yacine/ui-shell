# audio (Audio Control)

## Overview
Overlay audio panel (output, input, playback, recording, cards, patchbay tabs) backed by `Adapters.AudioGraph`. Package URI `UiShell.Audio` ([audio/qmldir]).

## Interface
- `AudioState` singleton: `open`, `screenName`, `initialContext`, `initialTab`, `show(output)` [audio/AudioState.qml:AudioState]
- `AudioShortcut`: `GlobalShortcut` (`Config.Audio.shortcutAppId`/`shortcutName`), toggles `AudioState.open` [audio/AudioShortcut.qml]
- `AudioSurface`: per-screen `PanelWindow` [audio/AudioSurface.qml:AudioSurface]
- `AudioPanel`: `tab`, `graph`, `sinks`, `sources`, `playback`, `recording`, `cards`, `tabs`; `activate()`, `selectTab(key)`, `requestClose()`, `showContext()`, `closed()` [audio/AudioPanel.qml:AudioPanel]
- `AudioRow`: `title`, `volume`, `muted`, `choices`; signals `volumeMoved(int)`, `muteToggled()`, `defaultRequested()`, `choiceMade(string)` [audio/AudioRow.qml:AudioRow]
- `PatchView`: `graph`; signals `connectRequested(out, into)`, `disconnectRequested(out, into)`, `disconnectNodeRequested(node, isSource)` [audio/PatchView.qml:PatchView]
- `PatchNode`: `node`, `isSource`, `cursor`, `linkCount` [audio/PatchNode.qml:PatchNode]
- `PatchLogic.js` (`.pragma library`): `kindLabel`, `step`, `rowCenter`, `rowTop`, `audioPorts`, `split`, `edges`, `linked`, `controlPoints` [audio/PatchLogic.js]

## Invariants
- Tab keys are exactly `output, input, playback, recording, cards, patchbay`; unknown `tab` falls back to the first [audio/AudioPanel.qml:tabs, currentTab].
- Patchbay sources have audio output ports (sink monitors only if linked), destinations have audio input ports; applications sort before devices [audio/PatchLogic.js:split].
- One edge per source/destination pair regardless of channel count [audio/PatchLogic.js:edges].
- Esc order: error popup, context popup, link mode, panel [audio/AudioPanel.qml:Keys.onPressed, PatchView.qml:Keys].
- `AudioGraph.active` follows `AudioPanel.open` [audio/AudioPanel.qml:audio].
- Max volume/step come from `options.option("maximumVolume"|"volumeStep")` (ComponentSettings) [audio/AudioPanel.qml].

## Side Effects
- Mutations through `audio.run([...])`: `default`, `volume`, `mute toggle`, `move`, `profile`, `connect`, `disconnect` [audio/AudioPanel.qml].
- Env: `UI_SHELL_OPEN_AUDIO=1`, `UI_SHELL_AUDIO_CONTEXT`, `UI_SHELL_AUDIO_TAB` [audio/AudioState.qml].
- Layer-shell Overlay, namespace `ui-shell-audio-control`, exclusive keyboard focus [audio/AudioSurface.qml].

## Verification
- Run: `make test-qml`

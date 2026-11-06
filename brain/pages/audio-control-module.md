---
id: audio-control-module
title: Audio control module replaces pavucontrol and helvum
category: decision
status: active
tags: [audio, pipewire, module]
created: "2026-11-05T07:23:45"
updated: "2026-11-05T16:18:35"
---

<!-- compiled_truth -->
# Decision

A fourth shell module, `modules/audio` (surface, state, shortcut, panel, like launcher, picker and tuning), gives control over PipeWire: it replaces pavucontrol (mixer, devices, per-application routing, card profiles) and helvum (patchbay). Control only: no waveforms, meters or bouncing bars.

## What the references teach

- **Stock Omarchy panel**: uses `Quickshell.Services.Pipewire` natively (nodes, `PwObjectTracker`, `node.audio.volume/muted`, `preferredDefaultAudioSink`). Live and polling-free for the mixer. Quickshell exposes nodes and node-level link groups, not ports.
- **omarchy-audio-control (ssupt)**: the most complete feature set: per-application persistent output and microphone routing through WirePlumber metadata (`target.object`, `target.node`), multi-output groups through `module-combine-sink`, saved scenes (defaults, volume, balance, ports, profiles), Bluetooth profiles, microphone test, diagnostics and guarded recovery. Costs a Rust service on a socket with a JSON protocol and systemd units: a daemon.
- **omarchy-plugin-audio (Ziryt)**: one panel, eight views, fully keyboard-driven. Useful patterns: pure `.pragma library` JS for argv building and models (unit-testable), a command queue where a keyed command replaces its waiting predecessor (slider drags send only the newest value), persisted patchbay node positions, a detachable window, `pw-top`, ALSA mixer, `pactl` for stream moves, kills and card profiles.
- **oma-aux (sam0110)**: a patchbay from one CLI helper: `pw-dump` normalised to a snapshot, `pw-link` connect/disconnect/toggle with channel matching (FL to FL, mono fallback), `pw-link -iolm` as the change feed, saved routes in JSON, per-route filters. Closest to the script-as-action style of this project.

## Our design

- **No daemon.** State is read live and changed by actions; persistence is delegated to WirePlumber (default devices, stream targets) plus one small JSON for UI layout (patchbay positions).
- **Two data paths, each for what it does best.** Native Quickshell Pipewire for live mixer state (volume, mute, defaults, streams). `scripts/audio-graph` for what native lacks: a port-level graph snapshot (`pw-dump` through `jq`), `pw-link` for links, `pw-metadata` for stream targets, `pactl set-card-profile`, with every argument validated. Its logic is testable against fixtures without PipeWire.
- **Views**: Mixer (outputs, inputs, per-application playback and recording), Routing (move a stream to a device, follow default), Devices (card profiles, ports), Patchbay (ports and links). Keyboard-first like the other panels; slider writes coalesced per target.
- **Deferred on purpose**: output groups, scenes, Bluetooth codec choice, microphone test, `pw-top`, ALSA mixer, per-route EQ and meters. Each is a later lego piece, not part of the first version.


## Timeline

- time: 2026-11-05T07:23:45
  kind: decision
  summary: "Created this page: Audio control module replaces pavucontrol and helvum"
  source: "survey of omarchy-audio-control, omarchy-plugin-audio, oma-aux, omarchy stock panel"
  affects: [audio-control-module]

- time: 2026-11-05T07:23:45
  kind: decision
  summary: Initial design from the reference survey
  source: "refs/omarchy-audio-control, refs/omarchy-plugin-audio, refs/oma-aux, refs/omarchy/shell/plugins/panels/audio"
  affects: [audio-control-module]

- time: 2026-11-05T07:28:46
  kind: decision
  summary: "First slice built. scripts/audio-graph is the single data source and action tool: snapshot (pw-dump through jq, volumes cube-rooted to match wpctl, stream target from default metadata, cards, ports, links), volume/mute/default via wpctl (WirePlumber), move via pw-metadata, link/unlink via pw-link, profile via pw-cli. PipeWire tooling only, no pactl. UI_SHELL_AUDIO_FIXTURE or a file argument replaces the live graph for tests and previews. adapters/AudioGraph snapshots on pw-dump --monitor events while the panel is open and coalesces keyed actions (slider drags). modules/audio: Mixer (outputs, inputs, playback and recording with per-stream device chooser) and Devices (card profiles) tabs; SUPER+A; layer ui-shell-audio-control. Native Quickshell Pipewire was rejected as a second data source: one source keeps volumes identical to wpctl. Next: patchbay tab (ports, links) and a keyboard walkthrough."
  source: implementation 2026-11-05
  affects: [audio-control-module]

- time: 2026-11-05T07:31:20
  kind: decision
  summary: "UI pass modelled on the references (ssupt mixer, Ziryt panel, oma-aux): header with title and the default output in mono caps, tabs on the right, hairline-ruled uppercase mono section labels with counts, two-line rows (identity and controls above, full-width slider below), default chip, app icons from application.icon-name (snapshot gained an icon field), accent-warning percentage above 100%, key footer. Keys on a focused row: M mutes, D sets default, arrows move the slider. Card sits below the bar. Stack is PipeWire plus WirePlumber (wpctl is WirePlumber); PulseAudio tools are not used. Tests deferred until the module is complete (patchbay still to do)."
  source: "user: state of the art UI like the references"
  affects: [audio-control-module]

- time: 2026-11-05T07:35:15
  kind: decision
  summary: "Patchbay tab built after studying the plugins. From Ziryt (Patchance-style): cabled Bezier links with horizontally pulled control points, sampled-curve hit tests, a dashed drag preview that turns red when the drop would unlink, pure .pragma library logic (PatchLogic.js), mono fanning out. From oma-aux: sources left, destinations right, select a source then toggle any number of destinations, drag as the second way, channel matching in audio-graph connect/disconnect (FL-FL, FR-FR, mono fans out, positional fallback; pairs action exposes the plan). Auto layout with fixed-height rows, so no stored node positions. Keyboard: arrows, Enter, X. Split rule: playback streams, inputs, and linked sink monitors are sources; sinks and recording streams are destinations. Verified against the live graph with Node. Deferred: tests (fixture pairing, PatchLogic edges and hit test, the check-audio-graph assertions that the richer fixture now changes), pointer drag verification on a real mouse, scroll cue, Devices tab walkthrough."
  source: implementation 2026-11-05
  affects: [audio-control-module]

- time: 2026-11-05T07:49:45
  kind: decision
  summary: "Audio tests added in three layers. Hermetic: check-audio-graph (fixture, pairing, validation, empty-channelVolumes regression) and tst_PatchLogic. Live: tests/scripts/check-audio-live runs on a PRIVATE PipeWire + WirePlumber (policy profile, null sinks) under a temp XDG_RUNTIME_DIR with ffmpeg|pw-cat tones, so desktop audio cannot be reached (make test-audio, isolation verified by fingerprinting the host session); make test-audio-host uses the current session and touches only uitest-* streams. The stress test found real bugs: a stream mid-creation has empty channelVolumes and made the snapshot divide by zero (fixed), virtual sources (Audio/Source/Virtual) were missed (fixed), and move default did not relink a stream whose links were all removed by hand (fixed: it now relinks to the default device). 298 checks, about 25 s."
  source: make test-audio
  affects: [audio-control-module]

- time: 2026-11-05T07:51:59
  kind: reversal
  summary: "Audio shortcut moved from SUPER+A to SUPER+M (mixer): SUPER+A was already the previous-layout action in hypr/binds/layouts.lua and the duplicate bind went unnoticed because test-hypr-config does not check for duplicate binds. SUPER+T (tuning) is free."
  source: keybind review
  affects: [audio-control-module]

- time: 2026-11-05T08:07:20
  kind: reversal
  summary: "Corrected against the project's own contract (STYLE.md): the audio panel showed a permanent key footer and a big title, and the tuning panel explanatory text; both removed. Keys, information and options now go through the shared PanelContext (Ctrl+Space, Ctrl+I, Ctrl+E). Component settings are spec-driven (shell/config/ComponentSpec.qml): audio is a third component with showIcons and maximumVolume (100/125/150) via scripts/render-audio-settings and renderAudioSettings (optional manifest command). New surfaces load their panel asynchronously (Config.<Module>.asynchronousPanelLoad); a synchronous load with an ErrorPopup distorted the whole window. Object.fromEntries is not available in the QML engine here; use a loop. Nested session with the host PipeWire: make test-env-audio (UI_SHELL_HOST_PIPEWIRE=1 binds the socket read-only)."
  source: "user review: inconsistency with ctrl+space and ctrl+e"
  affects: [audio-control-module]

- time: 2026-11-05T08:34:58
  kind: decision
  summary: "User review round: icons removed everywhere (UI, snapshot, Ctrl+E option); the long Mixer became six task tabs (Output, Input, Playback, Recording, Cards, Patchbay) with live counts, Left/Right moves between tabs and one generic AudioRow list serves the four volume tabs; the patchbay is click-only (select a source, click destinations to link or unlink; keyboard unchanged): no drag, preview, curve hit-testing or custom cursor, PatchLogic lost edgeAt/rowAt/pointAt. Ctrl+E options are now Step (1, 2, 5, 10 percent arrow-key step) and Maximum volume (100, 125, 150). Environment note: GUI tests hang while the host screen is locked (hyprlock stops frame delivery to the nested session); unlock before running test-wallpaper, test-launcher, test-env-snapshot."
  source: user review
  affects: [audio-control-module]

- time: 2026-11-05T16:18:35
  kind: decision
  summary: "Audio UI round: tabs show labels only (no counts); patchbay is click-only and symmetric (select a node on either side, click one on the other side to link or unlink; X removes a node's links); rows, nodes and slider use outlined cards like the reference plugins; slider glides when not pressed and ignores wheel while the panel scrolls; Ctrl+Space help text wraps instead of overflowing."
  source: user request 2026-11-05
  affects: [audio-control-module]

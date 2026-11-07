---
id: mpris-media-control
title: "Media session control (MPRIS)"
category: project
status: active
tags: [mpris, media, panel, keys]
created: "2026-11-06T16:21:51"
updated: "2026-11-07T03:53:15"
---

<!-- compiled_truth -->
The media control shows and controls the current MPRIS player. It is built (design: features/designs/mpris.md; contract: shell/modules/mpris/EGM.md); the owner's live checks on the host are pending.

What it is: a bar entry (one fixed icon, audio-player) and Super+N open a square, keyboard-first panel: player name and an icon pin (top right), title and artist as one scrolling line each, a seek bar (a live bar with LIVE for streams), previous/play-pause/next, and a one-row player selector (left/right buttons, a square per player). The card never changes size. Data comes only from Quickshell's MPRIS module; no daemon, no helper process. The one timer ticks once a second only while the panel is open and playing.

Decisions that matter later:
- One selection owner (shell/adapters/MediaSelection): pin, then the playing player (latest to start), then the last that played; playerctld excluded; players are keyed by desktop entry (else identity, else bus name); one pin only, kept in memory and kept while its player is absent. The bar entry, panel and media keys all read it.
- The media keys (play/pause, pause on XF86AudioStop, next, previous) are shell shortcuts only, bound with locked=true; the playerctl binds are gone. If the shell is down the keys do nothing (accepted).
- Art: per-player mode (cover, blurhash, off; mpd cover, browsers blurhash) from a config table; Ctrl+E Art is an override for every player (auto = the table). A provider is an ordered list of steps run by scripts/media-art (curl to fetch, vips else ffmpeg to shrink, the owner's blurhash tools); the script checks tools once at start and the UI hides blurhash when its tools are missing (players fall back to the cover). Hot cache of recent results; stale art never shows; art runs only while the panel is open. The picture is always a local file made by the script, never the player's own address. Owner chose to keep blurhash over a QML blur (proposal not taken: a blur mode, and shrinking before cover, because Qt decodes a full PNG before scaling).
- Look: a permanent dim layer above the art (artScrimOpacity), a smooth cross-fade where the old picture stays opaque until the new one is in, drawn transport icons replaced by the owner's SVGs tinted by the theme.
- Nested test session: no players by default (UI_SHELL_MPRIS_SOURCE=off); the two blurhash tools are bound read-only from ~/.local/bin; media keys cannot reach it.


## Timeline

- time: 2026-11-06T16:21:51
  kind: decision
  summary: "Created this page: Media session control (MPRIS)"
  source: features/reqs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-06T16:21:51
  kind: decision
  summary: "Brainstorm done (six lenses). Owner: bar icon + key open a keyboard-first panel; controls only; Quickshell MPRIS only, no daemon; per-player art (cover/blurhash/off, mpd=cover, browsers=blurhash); everything composable (swappable art providers, policy, keys); media keys are shell-only with no playerctl fallback (accepted loss when the shell is down); pin kept in memory and kept while its player is absent (shown on the bar icon); selection: pin, then playing, then last played, playerctld excluded."
  source: features/reqs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:03:02
  kind: decision
  summary: "Design drafted in features/designs/mpris.md (Technical Plan, Alternatives, Detailed Implementation). Owner delegated provider structure ('most flexible'): art providers are ordered steps composed in config (steps share one file-in/file-out/one-JSON-line contract). Confirmed at reconcile: steps in config, and Ctrl+E settings (seek step, default art mode). Phases: 0 host spike, 1 adapter+selection+panel+icon, 2 media keys (shell-only, playerctl removed), 3 art."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:11:15
  kind: decision
  summary: "Stage 9 review of the design (readiness, codebase, style) found 5 blockers and 12 majors; all fixed in features/designs/mpris.md. Owner chose the panel key SUPER+N. Author decisions: pause (not stop) everywhere; panel keys Space/Left/Right/N/P/K/Up/Down/Esc with a non-focusable slider; art scrim uses scrimColor and Config.Mpris.artScrimOpacity (no new theme token); MediaArt is a component owned by MprisState; panel takes injected selection/art/settings so it is testable; art steps write into --dir and name their own files; UI_SHELL_MPRIS_SOURCE=real|preview|off (nested default off)."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:16:29
  kind: decision
  summary: "Stage 9 re-audit done (cap reached, review concluded). Fixes applied: MprisCard (testable, no PanelContext) vs MprisPanel (owns ComponentSettings like ShotPanel); art runs only while the panel is open; step script contract (--dir, --timeout on every step, prune --keep, reuse existing files, ordered media_keys array); nested workspace_empty_bind moves to Ctrl+Alt+E; panelKeys reuse Config.Keyboard; whenPlayer = at least one player. Design ready to implement, phase 1 first."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:23:34
  kind: decision
  summary: "Phase 1 implemented: MprisSource, MediaSelection, MprisState/Card/Panel/Surface/Shortcut/ArtBackdrop/PreviewSource, MprisButton, Config.Mpris, Ctrl+E settings (mpris component), panel key SUPER+N (nested workspace_empty_bind moved to Ctrl+Alt+E), shell.qml wiring and one-way mutual exclusion, tests (tst_MediaSelection, tst_MprisCard), check-mpris, test-mpris. Not yet: media keys (phase 2), art (phase 3), live checks on the host."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:31:28
  kind: decision
  summary: "Panel look redone (drawn MediaIcon icons, header line, display-size title, centred transport, player chips to switch players, pin). Bar entry uses drawn icons and a filled/hollow pin square. Phase 2 built: MprisKeys (four GlobalShortcuts), media_keys ordered array in hypr/profile.lua, hardware.lua binds them with locked=true, playerctl binds removed, mprisKeysEnabled flag, check-mpris key checks. Pending: owner live check of keys and look; phase 3 art."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:47:29
  kind: decision
  summary: "Card rework (owner request): one-row player selector with left/right buttons and a square per player (replaces chips); title and artist are single fixed-height scrolling lines (MarqueeText) so the card never resizes; every row always present; pin is an icon button top right (pin-circle / pin-circle-filled, warning colour when absent); cassette icon replaces the note; new icons moved from repo root to shell/icons and recoloured white. Verified in the nested GPU preview."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T02:57:25
  kind: decision
  summary: "Audit of selection and key handling (owner request). Fixed: players with the same key are one entry (playing one shown); empty key falls back to bus name; non-object entries dropped; state changes atomic (provisional ranking so current never shows a wrong player; one assignment per state); actions capability-gated and drop calls on a quit player; held keys ignored except seek; invalid pin keys and seek values ignored. Streams (no length) get a live bar (sweeping segment, LIVE) instead of a slider. check-mpris also checks no duplicate media key, locked=true, and binding via profile.media_keys. New edge-case tests in tst_MediaSelection and tst_MprisCard."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T03:04:38
  kind: decision
  summary: "Phase 3 built: scripts/media-art (fetch/shrink/blurhash/prune; one JSON line, exit 0 for handled outcomes, scheme allow-list, size cap, timeout on every step, atomic writes, reuse, prune keeps the shown file), MediaArt + MediaArtRunner, art runs only while the panel is open, default mode from Ctrl+E, faults once per cause via ErrorPopup, preview cover. Phase 0 facts settled on this host: blurhash_decoder writes a loadable PNG; the encoder takes 2.8 s on a 4000 px image vs 0.3 s shrink + 0.01 s encode, so shrink first is required; magick, vips, ffmpeg, curl, wget all present. Tests: tst_MediaArt (13), check-media-art (stand-in tools). Pending: owner live checks (mpd cover, YouTube blurhash, missing-tool popup)."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T03:19:48
  kind: decision
  summary: "Art round 2 (owner request): hot cache in MediaArt (last 8 requests by key, shown at once with no gap); start-up capabilities check (media-art capabilities) gates the blurhash mode (hidden in Ctrl+E via ComponentSpec available hook, players fall back to cover); nested session binds the two blurhash tools read-only from ~/.local/bin and has it on PATH; cross-fade between art layers over the panel surface; tools trimmed to curl for fetch and vips-else-ffmpeg for shrink (wget and magick dropped: fewer paths to test, vips shrinks while loading, ffmpeg is the common fallback). Open: owner asked whether native QML blur is a good option; see answer."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T03:37:04
  kind: decision
  summary: "Round 3: owner kept blurhash (declined the blur/shrink-cover proposal for now). Fade rebuilt: new picture waits until loaded, fades in over the old one which stays opaque underneath, then the old is dropped (no dip to the surface), 360 ms InOutQuad, proportional duration, tested by sampling. Ctrl+E art is now a real override for every player: auto (per-player table) | cover | blurhash | off (key artMode; was defaultArtMode which only reached players with no table entry). Pin confirmed as ONE player (single pinKey; media keys act on it), test added. New icons from repo root renamed (arrow-left/right, media-play/pause/next/previous/record/stop) and used for transport and selector; drawn MediaIcon removed; record and stop unused."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T03:49:07
  kind: decision
  summary: "Round 4 look: control icons smaller (transport 26, play 32, arrows 16; even sizes) and sharp (SvgIcon renders at exact device-pixel size and centres on whole pixels); secondary text over art lifted (artMutedOpacity 0.78, fading); the dim layer over the art is PERMANENT (owner: covers have strong colours and cannot show at full brightness): constant strength with or without art, z above both picture layers. Bug fixed on the way: the dim was painted under the picture layers because they carry z 1 or 2."
  source: features/designs/mpris.md
  affects: [mpris-media-control]

- time: 2026-11-07T03:53:15
  kind: decision
  summary: "Compiled truth written after implementation (phases 1-3)"
  source: features/designs/mpris.md
  affects: [mpris-media-control]

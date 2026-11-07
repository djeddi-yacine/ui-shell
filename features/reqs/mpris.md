# Media session control (MPRIS)

* **Author:** djeddi-yacine
* **Date:** 2026-11-06
* **Status:** brainstorm brief, draft 3. All six review lenses are in and every open decision is settled. Ready for `/egm-draft`.

Input: `features/studies/mpris.md`. This file records what we need from it.

## Overview

A media control for the shell: a small bar icon and a shell key open a keyboard-first panel that shows what is playing and lets you control it. The panel shows the title and artist over an art backdrop, three transport buttons (previous, play/pause, next) and a seek bar. The shell also handles the keyboard media keys, and those keys always act on the same player the panel shows.

Data comes only from Quickshell's built-in MPRIS module (`Quickshell.Services.Mpris`). It watches D-Bus by events, so no helper process, no polling script and no daemon are needed. Player choice: you can pin one player (the pin lives in memory for the shell session); without a pin the shell shows the playing player, else the last one that played.

Art is the part the owner designed on purpose. His music has covers from 512 px to 8000 px, while browsers (YouTube) often give poor, non-square thumbnails. So each player has an art mode: the cover itself, a blurhash backdrop (a few colours that the theme can tint, with the title drawn over it), or no art. Defaults: mpd shows the cover, browsers show the blurhash. Blurhash is made by a stateless script action that uses the owner's `~/.local/bin/blurhash_encoder` and `blurhash_decoder`.

Out of scope for good: lyrics, a visualizer (`cava`), a playlist or track list, jumping between tracks, volume, shuffle and loop.

Acceptance: mpd through `mpd-mpris` and a browser playing YouTube both work, with the checks listed under "Acceptance checks".

## Analysis

Six lenses reviewed the hypothesis. They agree on the following, from most to least serious.

1. **The media keys become a hard dependency on a running shell.** Today `hypr/binds/hardware.lua:15-18` binds the keys to `playerctl` with `locked = true`, so they work with no shell at all. The shell can own keys only through `hl.dsp.global` and a `GlobalShortcut` (the pattern in `hypr/binds/shell.lua:8-30`). That dispatcher takes no argument, so each action (play/pause, next, previous, stop) needs its own shortcut, its own `profile.shell_shortcuts` entry and its own bind that keeps `locked = true`. If the shell is down, restarting or crashed, the keys do nothing. The old and new binds must be switched together or each key fires twice. This is a regression in resilience that must be written down and accepted, not left implicit. It is also a keyboard-only concern, so the brief must say what the user sees when the shell is down.
2. **"Same player" needs one owner of the selection.** The bar icon, the panel and the key handlers must read one shared "current player" and never compute the policy themselves. The reference projects drift here (study PF12, PF13). The state has to live in an object that exists when the panel is closed and is not behind the panel's feature flag (the keys must work without the panel). The policy runs in one place, as a pure function that tests can drive with fakes. Facts the policy depends on:
   * Player objects are deleted when a player leaves (`watcher.cpp` 66-76), so a held reference dangles.
   * A player enters the list only after its first `GetAll` completes (`watcher.cpp` 78-81), so "no player" is briefly true at start-up.
   * The order of `Mpris.players.values` is unverified (study U13), so a tie must never depend on it. Use an explicit "last played" sequence number.
   * `playerctld` may appear as a player (U14) and would duplicate real ones, so it is excluded by name.
   * Browsers register as `org.mpris.MediaPlayer2.firefox.instanceNNN`: the bus name changes when a browser restarts, so a pin or an art choice keyed by it silently dies. The key for both is the desktop entry, with the lower-cased identity as fallback.
3. **The position bar needs a timer, which is the one exception to "no polling".** Quickshell extrapolates `position` from the last known value and emits no ticks (`player.cpp` 174-185, `player.hpp` 111-138). The seek bar therefore needs a 1-second timer that runs only while the panel is open and the shown player is playing, never while only the bar icon is visible (the reference MC runs it always, PF1). When a player gives no length, Quickshell returns the position as the length and the bar would look full, so the bar is hidden when `lengthSupported` is false or `length` is not above 0 (PF16, PF29). `canSeek` false disables the bar and the keyboard seek. Position can drift on players that skip `Seeked`; the brief accepts this and re-reads when the panel opens.
4. **The art pipeline is the biggest part of the feature, with its own risks.**
   * *Cost.* A track change can run four commands: fetch, shrink, encode, decode. A skip-heavy session (holding Next) would queue them. Needs: a debounce, one chain in flight per player that is killed when the track changes, caps as config values (download bytes, timeout, decoded size, cache bytes), and a short negative cache so a bad URL is not retried on every metadata change. Only the blurhash mode needs shrink, encode and decode; the cover mode needs only the fetch.
   * *Safety.* The image control never receives the player's art address. It receives a local file produced by the script, always with an explicit `sourceSize` and `asynchronous: true`. An 8000 px cover decoded at full size is about 256 MB. The script accepts only `http(s)` and local `file://` paths, with a size cap, timeout and atomic writes; `data:` and `blob:` are rejected.
   * *Stale results.* Art often arrives after the track-changed event (`player.hpp` 361-364, PF32), so art is keyed on the art address changing, not on the track changing. A result whose key (player plus address) is no longer current is dropped. The previous art does not stay on screen: the new track shows the plain themed surface until its own art arrives.
   * *Ownership.* A separate art adapter exposes one result property; the panel reaches the system only through adapters. Failures follow the `RecordState` split: "no art" is silent, a broken script or a missing tool is reported once through the shared `ErrorPopup`, never silently replaced.
   * *Prerequisites.* `blurhash_encoder` and `blurhash_decoder` are user-local tools, not part of the repository; the shrink tool (`magick`, `vips` or `ffmpeg`) is an explicit config choice, validated when used. `mpd-mpris` publishes art only if mpd's cover feature is configured.
   * *Text over art.* Readability must come from theme tokens (scrim colour and opacity, text colour), because the reference projects use literal colours and the repository bans them.
5. **Keyboard-first means the panel keys must be defined; the references offer nothing to copy.** All three reference projects have almost no keyboard handling (study MC6.6, SN6.5, NP6.3). The brief needs a key table for the panel: play/pause, previous, next, seek step back and forward, pin and cycle player, close (Esc). The step size is a `Config` value. Esc always leaves; there is no unsaved work, so no `ExitDialog`. Every action must have a keyboard path even when the bar icon is hidden.
6. **Fit with the shell's structure.** The module follows the existing pattern (`shell/modules/EGM.md`): `shell/modules/mpris/` with a state singleton, shortcut, surface and panel, plus `shell/config/Mpris.qml`. The bar icon mirrors `RecordButton.qml`. One adapter singleton is the only importer of `Quickshell.Services.Mpris`, like `PolkitSource`. `shell.qml` needs an enabled flag, the "one panel open" connections, and the namespace in `hypr/rules.lua`. The media keys' state is always loaded when the keys are enabled; only the panel sits behind the panel flag.
7. **Scope check (zoom-out lens).** The core (Mpris adapter, one current-player rule, bar icon, panel, shell-handled keys, one bounded timer) is right-sized. The art pipeline (three modes per player, two external binaries, a shrink tool, a fetch script with a cache) is more code than the rest of the feature. The three reference projects get a blurred backdrop from one `MultiEffect` on the cover, which the shell already uses (`SecretDialog.qml`), and Qt's `sourceSize` already caps a huge cover at load. The owner chose composability, so the pieces are swappable and the build order is left to the design (decision 1).
8. **Edge cases need behaviours, not names.** Defined in "Behaviour rules" below.

## Behaviour rules (proposed, from the reviews)

* **Selection, in order:** (1) the pinned player, if it is present; (2) a playing player, the most recently started one winning ties; (3) the last player that played, if still present; (4) none. The `playerctld` proxy is never selected.
* **Pin:** set and cleared from the panel by keyboard, and shown by a mark on the bar icon, because the pin affects keys while the panel is closed. The pin is kept while its player is absent (decision 3); an absent pin is shown differently from an active one.
* **Keys when the shown player cannot do the action** (for example `canGoNext` false): nothing happens and nothing is shown; the shell checks the capability first so Quickshell does not log a warning.
* **Seek:** relative steps by `seek(offset)`; a click or drag sets `position`. Both are gated on `canSeek`.
* **No player:** the key opens the panel with a plain "Nothing playing" line; the bar icon follows its visibility setting.
* **Missing metadata:** an empty title falls back to the player's identity; an empty artist hides the line. Text is plain text and elided.
* **Bar icon visibility** is an explicit setting: always, only while a player exists, or never. With "never", the key still opens the panel.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * A keyboard-first panel and a bar icon for the current media player (title, artist, art backdrop, previous, play/pause, next, seek).
  * Shell-handled media keys that act on the player the panel shows.
  * A pin for one player (in memory), with an indicator, and a fixed selection order.
  * Per-player art mode (cover, blurhash, off) with a safe art script, a bounded cache and a stale-result guard.
  * Every limit, size, step and tool choice as a `Config.Mpris` value; every colour from theme tokens.
  * One Mpris adapter, one selection owner, one art adapter; tests with fakes for the selection and art logic.
* **Out-of-Scope Non-Goals:** lyrics, `cava`, playlist or track list, jumping to a track, volume, shuffle, loop, `openUri`, `quit` and `raise` of players, persistent pin, a daemon of any kind.

## Alternatives Weighed

* **Keep the `playerctl` binds and add a bridge to the shell.** Rejected for the keys' main path by the owner ("shell first is the right logic"). A wrapper that asks the shell and falls back to `playerctl` brings a second code path that can pick a different player. The owner chose shell-only keys (decision 2).
* **Handle the keys with an `IpcHandler` and `qs ipc call`.** Not used: no `IpcHandler` exists in the shell today, and a `GlobalShortcut` reuses the existing pattern.
* **Poll with `busctl` for shuffle, loop and the track list (as the references do).** Rejected: those features are out of scope, and the reference helpers cost a permanent process or a 3-second poll (study PF2, PF5).
* **A permanent position timer.** Rejected: only while the panel is open and playing.
* **Show the previous track's art until the new one arrives.** Rejected: a plain themed surface avoids a wrong cover under the new title.
* **Persist the pin in a file.** Rejected by the owner: in memory for the session.
* **Build the whole art chain as one fixed script.** Rejected by the owner's composability requirement: each mode and each tool must be replaceable on its own.
* **Pass the art address straight to the image control (as all three references do).** Rejected: no scheme or size control, and a network load outside the script's caps.

## Composability requirement (owner)

Asked how much of the art pipeline to build first, the owner answered: "make everything composable so a deep change later dont cost much". This is a requirement on the whole feature, and it settles the art-scope question: the pipeline is built as swappable pieces, and the design chooses the build order.

* **Art providers.** Each art mode (cover, blurhash, off) is a provider: an ordered list of step names in `Config.Mpris`, run by the art adapter. Every step is a script action with one uniform contract (input: an address or a file and an output path; output: one JSON line with the path of a local file, or a named failure). The panel only knows the result (`state`, `kind`, `path`). Which provider a player uses is one entry in a `Config.Mpris` table keyed by the player key, with a default for unmatched players. Adding, removing or replacing a provider (a live blur, a different encoder) is a config entry and, for a new step, a script subcommand, with no change to the panel. (Settled in drafting: the owner delegated the structure with "most flexible" as the criterion, and confirmed steps in config at the reconcile gate.)
* **Steps inside a provider are pieces too.** (Trimmed in implementation, at the owner's suggestion: fetching uses curl only, shrinking uses vips else ffmpeg.) The fetch tool, the shrink tool and the blurhash encoder and decoder are named config values behind the provider, so swapping one does not touch the others.
* **Selection policy** is one pure function behind one interface; a different policy replaces the function.
* **Keys** are a table of action names to shortcuts; adding an action is one entry plus one handler.
* **One adapter per outside system:** one for Quickshell's MPRIS module, one for art. Nothing else imports them.
* **Staging stays free.** Because the pieces are independent, the design can build the contract and the simplest provider first and add the rest later without rework. That order is the design's choice, not decided here.

## Decisions made by the owner at the brainstorm gates

1. **Art scope:** build everything composable, so a deep change later costs little (see "Composability requirement"). The build order is left to the design.
2. **Media keys when the shell is down:** they do nothing. There is no `playerctl` fallback and no wrapper; the keys are shell shortcuts only, and one code path keeps keys and panel on the same player. The brief accepts this resilience loss. The `playerctl` binds are removed in the same change.
3. **The pin when the pinned player closes:** the pin is kept in memory. While the player is absent the normal order is used; when the same player (same desktop entry) comes back it is the shown one again. The bar icon's pin mark must therefore stay visible while a pin is held, even if its player is absent, so a stale pin never grabs the keys unseen.
4. **Panel settings:** the panel has Ctrl+E settings (seek step and default art mode) like the other panels, confirmed at the reconcile gate of the draft.

## Key Decisions & Staging for Next Steps

Settled by the owner:

* A bar icon (visibility configurable) and a shell key open a panel; the panel is keyboard-first.
* Only controls: previous, play/pause, next, seek; no lyrics, no `cava`, no playlist.
* Data only from Quickshell's MPRIS module; no daemon.
* A pin for one player, kept in memory for the shell session; the shell handles the keys first.
* Art per player: cover, blurhash or off; mpd defaults to the cover, browsers to the blurhash; the shrink tool is an explicit config choice; no art shows the plain themed surface.
* Acceptance: mpd (through `mpd-mpris`) and a browser with YouTube.

Proposed by the review, not yet confirmed by the owner (the behaviour rules above, plus):

1. One Mpris adapter, one selection owner outside the panel flag, one art adapter.
2. Keys through `GlobalShortcut` with `locked = true`, one per action (play/pause, next, previous, stop), removed from `hardware.lua` in the same change; `XF86AudioStop` keeps its "pause" meaning.
3. The 1-second position timer only while the panel is open and playing.
4. Art caps, debounce and cache as `Config.Mpris` values; the cache under `$XDG_RUNTIME_DIR/ui-shell/` with an environment override for tests.
5. Staging: phase 0 spike (do `mpd-mpris` and the browser report art, position and `canSeek` as expected; does the watcher find players that start after the shell, U1; does `playerctld` appear, U14; can `GlobalShortcut` with `locked` fire on the lock screen; how fast are the blurhash tools on a large cover); phase 1 adapter, selection logic, panel and bar icon with fake-player tests; phase 2 the keys; phase 3 the art pipeline.

## Acceptance checks

* mpd and a YouTube tab at once: pin each in turn, and the media keys follow the pin.
* Start a player after the shell started: it appears (U1).
* Skip tracks quickly: no stale art, no extra commands left running.
* An 8000 px cover: the panel stays responsive and memory stays bounded.
* A YouTube non-square thumbnail: no distortion.
* A track with no art, a failed fetch, a missing shrink tool: the plain surface, and the failure reported once where it is a real fault.
* `canSeek` false and `lengthSupported` false: no seek bar, no full-bar look.
* Panel closed and idle: no timer and no process running.
* Shell stopped: the media keys do nothing (decision 2).
* Close the pinned player and start it again: the pin is shown as absent, then active again, and the keys follow it (decision 3).

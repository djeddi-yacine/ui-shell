# Media session control (MPRIS)

*   **Author:** djeddi-yacine
*   **Status:** Implemented (phases 1 to 3); the owner's live checks on the host are pending
*   **Date:** 2026-11-06

--------------------------------------------------------------------------------

## Overview

ui-shell gets a media control. A small bar icon and a shell key open a panel
that shows what is playing and lets you control it with the keyboard. The panel
shows the title and artist over an art backdrop, three buttons (previous,
play/pause, next) and a seek bar. The shell also handles the keyboard media
keys, and those keys always act on the same player the panel shows.

Today the media keys call `playerctl` directly (`hypr/binds/hardware.lua`
lines 15-18). `playerctl` picks a player by its own rules, so a key can skip a
track in a browser tab while your music player is the one you care about, and
nothing in the shell shows what is playing.

Quickshell already contains an MPRIS module (`Quickshell.Services.Mpris`) that
lists the players on the session bus and exposes their title, artist, state,
position and controls. It watches D-Bus by events, so no helper process,
polling script or daemon is needed. The work is the player choice, the art, the
panel and the keys.

Art is the part the owner designed on purpose. The owner's music has covers from
512 px to 8000 px, while browsers (YouTube) often give poor, non-square thumbnails.
So each player has an art mode: the cover itself, a blurhash backdrop (a few
colours the theme can tint, with the title drawn over it), or no art. Defaults:
mpd shows the cover, browsers show the blurhash.

The owner's requirement for the whole design is composability: every part is a
swappable piece behind a small contract, so a deep change later costs little.

Inputs: `features/studies/mpris.md` (what the three reference projects and
Quickshell's MPRIS module do) and `features/reqs/mpris.md` (what we chose and
why).

## The Problem

The shell cannot show or choose a media player, and the keys that control
media bypass it. Four facts make the fix harder than it looks:

*   **"The same player" needs one owner.** The bar icon, the panel and the key
    handlers must agree on which player is current. If each computes it, they
    drift (the reference projects show this, study PF12 and PF13). The choice
    must also work when the panel is closed, because the keys do.
*   **The keys become a dependency on the shell.** The current binds work with
    no shell running. A shell shortcut works only while the shell runs. The
    owner accepts this: if the shell is down, the keys do nothing.
*   **Position needs a timer, which breaks "no polling".** Quickshell
    extrapolates a player's position and emits no ticks (`player.cpp` 174-185).
    A seek bar needs a periodic tick (one second by default), kept to the moments it is useful.
*   **Art is the largest and riskiest part.** A cover can be 8000 px (about
    256 MB decoded at full size). Art addresses come from the player and can be
    web links. Art often arrives after the track-changed event. Browsers send
    non-square images. Four external commands (fetch, shrink, encode, decode)
    could run on every skip.

The proposed solution:

*   One Mpris adapter that is the only importer of the Quickshell module, and
    one selection owner that the icon, the panel and the keys all read.
*   A module with a bar icon, a keyboard-first panel and a shell shortcut, in
    the same shape as the audio, record and shot modules.
*   Shell shortcuts for the media keys, replacing the `playerctl` binds.
*   An art adapter with swappable providers, a stale-result guard and bounded
    caches.

## Goals

*   Show the current media player in a themed panel: title, artist, art
    backdrop, previous, play/pause, next, and a seek bar where seeking works.
*   Open the panel from a bar icon or a shell key, and operate every action by
    keyboard. The icon's visibility is a setting (always, only while a player
    exists, never); with "never" the key still opens the panel.
*   Choose the current player by one fixed order: the pinned player, then a
    playing player (the most recently started wins), then the last player that
    played. Never choose the `playerctld` proxy.
*   Let the owner pin one player. The pin is kept in memory for the shell
    session, stays when its player closes, and returns to that player when it
    comes back. The icon always shows that a pin is held, and shows an absent
    pin differently.
*   Handle the media keys in the shell, acting on the current player, with one
    code path and no `playerctl` fallback.
*   Give each player an art mode (cover, blurhash, off) from one config table,
    with defaults (mpd cover, browsers blurhash) and a default for players that
    match no entry.
*   Load art only through a script action that applies a scheme allow-list, a
    size cap, a timeout and a cache; the image control never receives the
    player's art address.
*   Never show a previous track's art under a new title, and never leave a
    fetch running for a track that was skipped.
*   Run the position timer only while the panel is open and the shown player is
    playing; run no timer, process or image decode while the panel is closed and
    nothing changes.
*   Keep every limit, size, step, key and tool choice in `Config.Mpris`, and
    every colour in theme tokens.
*   Make each piece (art provider, selection function, key table) replaceable
    on its own through a small contract.
*   Test the selection logic and the art logic with fakes, and give the owner an
    exact live check with mpd and a YouTube tab.

## Non-Goals

*   Lyrics, a visualizer (`cava`), a playlist or track list, jumping to a track.
*   Volume, shuffle, loop, and the player actions `openUri`, `quit` and
    `raise`.
*   A saved pin, or any state file for the selection.
*   A daemon, or a helper process that runs without a reason (`busctl`
    monitors, polling scripts).
*   A `playerctl` fallback for the keys when the shell is down.
*   Claims about players or browsers that were not tested (see the phase 0
    spike).

## Decisions from the owner

*   **Art scope:** build everything composable so a deep change later costs
    little. The build order is the design's choice (see Technical Plan).
*   **Keys when the shell is down:** they do nothing. No wrapper, no
    `playerctl` fallback. The `playerctl` binds are removed in the same change
    as the shell shortcuts are added.
*   **The pin:** kept in memory for the session and kept while its player is
    absent; the bar icon makes a held pin visible so it never grabs the keys
    unseen.
*   **Player choice:** pin, then playing, then last played; `playerctld`
    excluded.
*   **Art defaults:** mpd shows the cover; browsers show the blurhash; the
    shrink tool is an explicit config choice; with no art the panel shows a
    plain themed surface.
*   **Acceptance:** mpd through `mpd-mpris` and a browser playing YouTube.
*   **Panel key:** SUPER + N (chosen by the owner from the free keys).

*   **Provider structure:** steps composed in config (delegated to the author with "most flexible" as the criterion; confirmed at the reconcile gate).
*   **Panel settings:** Ctrl+E settings for the seek step and the default art mode (confirmed at the reconcile gate).

## Decided by the author (mechanical)

*   Panel keys (Space, Left and Right, N and P, K, Up and Down, Esc) follow the
    shell's own key conventions; Tab keeps its "next control" meaning.
*   The module is named `mpris` (`shell/modules/mpris/`, `Config.Mpris`,
    namespace `ui-shell-mpris`), after the protocol, like `audio` and `record`.
*   The player key for the pin and for the art table is the desktop entry, with
    the lower-cased identity as fallback, not the bus name (browsers change their
    bus name on restart).
*   **Art providers are steps composed in config** (the owner left the structure
    to the author, with "most flexible" as the criterion). A provider is an
    ordered list of step names in `Config.Mpris`; the art adapter runs the
    steps in turn. See "Art providers" in the Technical Plan for what it costs
    and how it can be changed.
*   Text from players is shown as plain text and elided; an empty title falls
    back to the player's identity; an empty artist hides its line.
*   A key that the shown player cannot perform (for example `canGoNext` false)
    does nothing and shows nothing; the shell checks the capability first so
    Quickshell does not log a warning.
*   Seek keys use a relative step from `Config.Mpris`; click or drag sets an
    absolute position. Both are gated on `canSeek`, and the bar is hidden when
    the player gives no length.

## Critical User Journeys (CUJs)

### CUJ 1: See and control what is playing (phase 1)

*   **Given**: mpd is playing.
*   **When**: the owner clicks the bar icon or presses the panel key.
*   **Then**: the panel opens on the focused screen showing the title and
    artist over the cover, with play/pause focused. Space pauses, Left and Right
    seek, N and P skip, K pins, Up and Down show the other players, Esc closes. Nothing runs after it closes.

### CUJ 2: Media keys without the panel (phase 2)

*   **Given**: the panel is closed and a player is current.
*   **When**: the owner presses the play/pause, pause, next or previous key.
*   **Then**: the shell acts on the current player, the same one the panel
    would show. If the shell is down, nothing happens.

### CUJ 3: Two players at once (phase 1)

*   **Given**: mpd and a YouTube tab are both present.
*   **When**: the owner pins mpd from the panel and then starts the video.
*   **Then**: the panel and the keys keep following mpd, and the icon shows the
    pin. Without the pin they would follow the one that started most recently.

### CUJ 4: The pinned player closes (phase 1)

*   **Given**: mpd is pinned and then closes.
*   **When**: the owner opens the panel or presses a key.
*   **Then**: the normal order is used, the icon shows the pin as absent, and
    when mpd starts again it is the shown player again with no new action.

### CUJ 5: Browser art (phase 3)

*   **Given**: a YouTube tab plays and the browser's art mode is blurhash.
*   **When**: the track changes.
*   **Then**: the panel shows the plain surface until the new blurhash is ready,
    then the colour backdrop with the title over it. A quick run of skips leaves
    no old art and no extra commands running.

### CUJ 6: Art fails or is missing (phase 3)

*   **Given**: a track has no art, the fetch fails, or the shrink tool is
    missing.
*   **When**: the panel shows the track.
*   **Then**: it shows the plain themed surface. A real fault (a missing tool, a
    broken script) is reported once through the shared error popup; plain "no
    art" is silent.

### CUJ 7: A player without a length (phase 1)

*   **Given**: a player reports no length or `canSeek` false.
*   **When**: the panel shows it.
*   **Then**: there is no seek bar (not a full bar), and the seek keys do
    nothing.

### CUJ 8: No player (phase 1)

*   **Given**: no player exists.
*   **When**: the owner presses the panel key.
*   **Then**: the panel opens with a "Nothing playing" line, and the bar icon
    follows its visibility setting.

## Technical Plan

### Architecture

```
org.mpris.MediaPlayer2.* on D-Bus
          |
          v
Quickshell.Services.Mpris        only shell/adapters/MprisSource.qml imports it
          |  players (plain objects, playerctld removed)
          v
shell/adapters/MediaSelection.qml    pure logic, injected `source`
   play order, pin, current player, pin state
          |  one shared instance: MprisState.selection.current / pinState
          +------------------+--------------------+
          v                  v                    v
 bar/MprisButton      MprisPanel (per output)   MprisKeys (4 GlobalShortcut)
 (icon + pin mark)    title, artist, buttons,   play/pause, next, previous,
                      seek bar, art backdrop    pause -> act on `current`
                             |
                             v
          shell/adapters/MediaArt.qml    art logic (state, kind, path)
            per-player mode -> provider (steps) -> MediaArtRunner -> scripts/media-art
                             |
                             v
                  local file + kind  -> Image (sourceSize capped)
```

Data flows one way. The Mpris adapter hands plain player objects to the
selection logic. The selection logic produces one `current` player. The bar
icon, the panel and the keys read only `current`; none of them reads
`Mpris.players`. The art adapter reads `current` and answers with a local image
file, never the player's own address.

### The Mpris adapter (`MprisSource`)

The only importer of `Quickshell.Services.Mpris`. A `Singleton` that exposes
`players`, a JavaScript array built from `Mpris.players.values` with every
player removed whose `dbusName` starts with `org.mpris.MediaPlayer2.playerctld`,
and nothing else. `players` is a binding on the model's `values`, so it
re-evaluates when a player appears or leaves. Like `PolkitSource`, it is kept thin so the rest runs without Quickshell
in tests. Player objects disappear when a player leaves, so nothing else keeps
a reference to one across a change of the list.

### The selection (`MediaSelection`)

An ordinary component (not a singleton) with an injected `source` that supplies
`players`; tests give it a fake source, the shell gives it `MprisSource`.

*   **Play order.** An `Instantiator` over `source.players` creates one watcher
    per player (a `Connections` on its `isPlaying`), so a player that starts
    playing gets the next number from a counter. A player already playing when
    the selection first sees it is numbered in key order, once; after that, only
    the order of events matters, never the position in the list (study U13).
    `current` is a binding on the player list, the numbers and the pin.
*   **Player key.** `keyOf(player)`, a function of the selection (a Quickshell
    player cannot gain a property): the desktop entry lower-cased, with the
    lower-cased identity as fallback. It is the key for the pin and for the art
    table. It survives a browser restart, where the bus name does not.
*   **`current`.** The first that applies: the pinned player if present; the
    playing player with the highest number; the last player that played, if
    still present; none. It is a pure function of the player list, the numbers
    and the pin, so tests run it with fakes.
*   **Pin.** `pinKey` holds the key (in memory only). `pinState` is `none`,
    `active` (the pinned player is present) or `absent` (held, player gone).
    `pin(key)`, `unpin()` and `showPlayer(delta)` (pin the player `delta`
    places away in the list of present players, ordered by key) are the actions;
    a pin on a missing player is allowed and takes effect when the player
    returns. `showPlayer(delta)` starts from `current`, wraps around the ends,
    does nothing with one player or none, and with no `current` picks the first
    (delta above 0) or the last (delta below 0). `playerCount` is the number of
    present players.
*   **Actions.** `playPause()`, `next()`, `previous()`, `pause()` and
    `seekBy()` check the capability first (`canTogglePlaying`, `canGoNext`,
    `canGoPrevious`, `canPause`, `canSeek`) and do nothing when the player cannot,
    so Quickshell never logs a warning. `seekBy(seconds)` is the selection's
    name for Quickshell's `seek(offset)`.

### The state and the flags (`MprisState`)

A `QtObject` singleton in `shell/modules/mpris/`, in the shape of `AudioState`
and `AuthState`: `open`, `screenName`, `show(output)`, plus the one
`MediaSelection` instance (`selection`) and the `MediaArt` instance (`art`),
each a property with a declared value. The panel's saved settings belong to the
panel, as in every other panel. It exists whenever something references it,
so the keys work with the panel closed. Two flags in `Config.Config` separate the
parts: `mprisEnabled` (bar icon, panel, shortcut) and `mprisKeysEnabled` (the
four media-key shortcuts). Turning the panel off does not turn the keys off.

### The panel and the bar icon

*   **Structure.** Two files: `MprisPanel` (the window content: it hosts
    `PanelContext`, owns the `ComponentSettings` instance for this output, as
    `ShotPanel` does, and wires `ErrorPopup`) and `MprisCard` (everything shown
    and every key: backdrop, title, artist, buttons, seek bar, pin, timer). The
    card takes `selection`, `art` and the seek step as required properties and
    imports nothing that needs Quickshell, so tests build the card with fakes.
*   **Window.** One `PanelWindow` per output like the audio panel (`Variants`),
    layer Overlay, namespace `ui-shell-mpris`, exclusive keyboard while open,
    `ExclusionMode.Ignore`. It is one of the panels in the "one panel open at a
    time" connections in `shell/shell.qml`.
*   **Content.** The art backdrop (or a plain `Style` surface), the title and
    artist over it, a row of three `ShellButton`s (previous, play/pause, next),
    and a `ShellSlider` for the seek bar. Text is plain text and elided; an empty
    title shows the player's identity; an empty artist hides its line. A pin
    button shows the pin state. "Nothing playing" shows when there is no
    current player.
*   **Keys in the panel** (all from a `Config.Mpris` table, not literals):
    Space play/pause, N and P next and previous, Left and Right seek by
    the seek step (Ctrl+E `seekStep`, else `seekStepSeconds`), K pin or unpin the shown player, Up and Down show the
    previous or next player (and pin it), Tab moves between controls as in every
    other panel, Esc closes. The panel handles these keys before the focused
    control sees them, and the slider is not focusable (`Qt.NoFocus`), so its own
    arrow stepping never fights the seek keys. Ctrl+Space, Ctrl+I and Ctrl+E follow the shell's
    panel rules (help, info, settings). There is no `ExitDialog`: there is no
    unsaved work.
*   **Seek bar.** Shown only when `positionSupported`, `lengthSupported` and
    `length > 0`; disabled when `canSeek` is false (so the keys do nothing). A
    drag or click sets `position`; the arrow keys call `seekBy(seconds)`.
*   **Position timer.** One `Timer` (`Config.Mpris.positionTickMs`, 1000 by default) inside the panel, running only while
    the panel is open, the current player is playing, and the bar is shown. It
    calls the player's `positionChanged()` so the bar re-reads the extrapolated
    position. On opening the panel the position is read once. This is the one
    exception to "no polling" and nothing outside the panel runs a timer.
*   **Bar icon.** `shell/modules/bar/MprisButton.qml`, modelled on
    `RecordButton.qml`: a `ShellButton` with a plain-text glyph ("▶" playing,
    "❚❚" paused, "♪" no current player), a pin mark after it ("◆" when `active`,
    "◇" when `absent`), `Accessible.name`, and a click that opens the panel. Its visibility is `Config.Mpris.iconVisibility`:
    `always`, `whenPlayer` or `never`.

### Art providers

*   **Art modes and the table.** `Config.Mpris.artModes` maps a player key to a
    mode (`cover`, `blurhash`, `off`), with `artDefaultMode` for unmatched
    players. Shipped defaults: `mpd` is `cover`; the browsers' keys are
    `blurhash`.
*   **A provider is a list of steps.** `Config.Mpris.providers` maps a mode to an
    ordered list of step names: `cover` is `["fetch"]`, `blurhash` is
    `["fetch", "shrink", "blurhash"]`, `off` is `[]`. Adding a provider or
    reordering steps is a config change.
*   **Steps.** `scripts/media-art STEP [FLAGS] INPUT` is one stateless bash
    script with one subcommand per step. Every step takes an input (an address
    or a file), writes into the cache directory given by `--dir`, chooses its own
    file name, and prints exactly one line of JSON: `{"ok":true,"path":...}` or
    `{"ok":false,"error":<code>,"detail":...}`. The exact flags are in the
    Detailed Implementation. Steps:
    *   `fetch`: accepts only `http(s)` and local `file://` or
        plain paths (anything else, including `data:` and `blob:`, is refused),
        enforces a download size cap and a timeout, writes atomically, and for a
        local file validates it (regular file, size cap) and returns its path
        without copying. Fetching always uses `curl`.
    *   `shrink`: resizes so the longest edge is at most `SIZE`
        with `vips` or else `ffmpeg` (the first installed, from `Config.Mpris.shrinkTools`).
    *   `blurhash`: runs `blurhash_encoder` then
        `blurhash_decoder` (paths are config values) and writes a small image.
*   **The adapter.** `MediaArt` (an ordinary component owned by `MprisState`,
    with its `player` bound to `selection.current`) watches the art
    address (`trackArtUrl`), not the track-changed event, because art often
    arrives later. After a debounce (`Config.Mpris.artDebounceMs`) it runs the
    steps for the player's mode one after another through `MediaArtRunner`
    (each step's `path` is the next step's input) and exposes `state`, `kind` and
    `path` (`state` is `none`, `loading`, `ready` or `failed`). It runs only while
    the panel is open, so a bar-icon-only session never fetches art.
*   **Stale guard.** Each run has a key: player key plus address. When the key
    changes, the running step is killed and the chain is dropped; a result whose
    key is no longer current is ignored. While loading and when `none`, the panel
    shows the plain surface (the previous art is not kept).
*   **Cache.** Under `$XDG_RUNTIME_DIR/ui-shell/mpris/` (override
    `UI_SHELL_MPRIS_DIR` for tests), keyed by a hash of the input and the step name; an existing file is reused, not fetched again. Capped by `cacheMaxBytes` and `cacheMaxEntries`; the oldest entries are
    removed by a maintenance subcommand (`prune`, which is not a provider step)
    when a run ends, never the file currently shown. A failed address is remembered for
    `failureMemorySeconds` so it is not retried on every metadata change.
*   **Image loading.** The image control always gets a local file, with an
    explicit `sourceSize` from `Config.Mpris.artSourceSize` and
    `asynchronous: true`. The cover is drawn with `PreserveAspectCrop`, so a
    non-square thumbnail is cropped, not stretched, and the small blurhash image
    is drawn with `smooth: true`.
*   **Errors.** "No art", a refused scheme (`scheme`) and a bad input
    (`bad-input`) are silent. A missing tool (`missing-tool`), a timeout
    (`timeout`), a size cap (`too-large`) and a tool or script failure
    (`tool-failed`, which also covers a non-zero exit or empty output) are
    reported once per cause through `ErrorPopup`, with the player and address in
    the details.
*   **Why steps in config, and what it costs.** The owner asked for "most
    flexible". Steps in config let a tool or a whole provider change with no
    script or panel edit. The cost: the adapter becomes a small pipeline runner
    (one process at a time, killed on a change), which is the most QML of the
    three structures considered. Because every step has the same contract (a file
    in, a file out, one JSON line), moving to one script per provider later means
    wrapping the same steps; the panel and the selection do not change.

### The media keys

*   **Transport.** Four `GlobalShortcut`s in `shell/modules/mpris/MprisKeys.qml`,
    named from `Config.Mpris.keyShortcuts`: `media-play-pause`, `media-next`,
    `media-previous`, `media-pause`. Each calls the matching action on
    `MprisState.selection`, so they act on the same player the panel shows.
*   **Binds.** `hypr/profile.lua` gets a `media_keys` table (key, target,
    description) and `hypr/binds/hardware.lua` binds each with
    `hl.dsp.global(target)` and `locked = true`, replacing the four `playerctl`
    lines in the same change (`XF86AudioPlay`, `XF86AudioStop` kept as "pause",
    `XF86AudioNext`, `XF86AudioPrev`). Both removal and addition ship together so
    no key fires twice.
*   **Shell down.** The keys do nothing (owner decision). The bar and panel are
    not involved, so nothing shows; the tradeoff is documented in the README.
*   **Lock screen.** `locked = true` is kept; whether a global shortcut fires on
    the lock screen is checked in phase 0, not assumed.

### Hyprland and shell wiring

*   `hypr/rules.lua`: add `mpris` to the `shell-owns-motion` namespace pattern.
*   `hypr/profile.lua`: `shell_shortcuts.media_panel = { key = "N", target =
    "ui-shell:media-panel" }` for the panel key (SUPER + N, chosen by the owner
    from the free keys), recorded in `README.md`. In the nested session the
    modifier is Ctrl+Alt, where N is already "focus empty workspace"; the nested
    profile moves that bind to Ctrl+Alt+E (`hypr/user/nested.lua`).
*   `shell/shell.qml`: a `Loader` for `MprisShortcut`, a `Variants` for
    `MprisSurface`, a `MprisKeys` loader on `mprisKeysEnabled`, and the mutual
    exclusion with the other panels.
*   The nested session: the panel key works like the other shell shortcuts (after
    the nested `workspace_empty_bind` move above). The media keys (XF86) cannot
    reach the nested session from the host keyboard, so those binds are inert
    there; the panel opens with the panel key or `UI_SHELL_OPEN_MPRIS=1`.

### Configuration (`Config.Mpris`)

All values explicit, with no literals in components; the full list with default
values is in the Detailed Implementation. Names used throughout: `namespace`,
`shortcutAppId`, `shortcutName`, `keyShortcuts`, `panelKeys`, `iconVisibility`,
`seekStepSeconds`, `positionTickMs`, `artModes`, `artDefaultMode`, `providers`,
`shrinkTools`, `blurhashEncoder`, `blurhashDecoder`,
`artSourceSize`, `artShrinkSize`, `blurhashComponents`, `blurhashDecodeSize`,
`artDebounceMs`, `downloadMaxBytes`, `stepTimeoutSeconds`, `cacheMaxBytes`,
`cacheMaxEntries`, `failureMemorySeconds`, `artScrimOpacity` and the panel size
values. Colours come from the existing theme: the art scrim is
`style.scrimColor(Config.Mpris.artScrimOpacity)`, so the title stays readable
over any art without a new theme token.

### Testing

*   **`tests/tst_MediaSelection.qml`:** the order (pin, playing, last played,
    none), ties by the latest start, `playerctld` ignored, pin kept while its
    player is absent and returning, the capability checks, with fake players.
*   **`tests/tst_MediaArt.qml`:** the stale guard (a skip mid-chain drops the old
    result), the debounce, the negative cache, the error rules, with a fake
    step runner.
*   **`tests/tst_MprisCard.qml`:** no seek bar when length is unsupported, seek
    disabled when `canSeek` is false, "Nothing playing", empty title and artist
    fallbacks, keys do nothing when the capability is missing. `MprisCard` takes
    `selection`, `art` and the seek step as required properties and imports no
    Quickshell singleton, so the test builds it with fakes. `MprisPanel` (which
    hosts `PanelContext` and `ComponentSettings`) is checked in the nested
    preview, like the other panels.
*   **`tests/scripts/check-media-art`:** the script steps with stand-ins for the
    tools (scheme allow-list, size cap, timeout, atomic write, refused `data:`).
*   **Namespace and key table check:** like `check-auth`, the namespace in the
    QML equals `hypr/rules.lua`; the shortcut names equal the Hyprland targets.
*   **Owner live checks on the host:** mpd (through `mpd-mpris`) and a YouTube
    tab; the acceptance list in the brief.

### Phases

0. Spike (owner on the host): whether the watcher finds players that start after
   the shell (U1); whether `playerctld` appears (U14); whether a global shortcut
   with `locked` fires on the lock screen; what `blurhash_decoder` writes and how
   fast the two tools are on a large cover; whether `mpd-mpris` reports art,
   position and `canSeek`. The spike changes nothing in the repository.
1. The Mpris adapter, `MediaSelection`, `MprisState`, the panel and the bar icon,
   the panel key bind, the preview source and the fake-player tests (CUJ 1, 3,
   4, 7, 8). No art yet: the plain surface.
2. The media keys (CUJ 2): the four shortcuts, the media binds, and removing the
   `playerctl` lines.
3. The art providers (CUJ 5, 6): `scripts/media-art`, `MediaArt`, the config
   table, the cache and the tests.

## Alternatives Considered

### Keep the `playerctl` binds and add a bridge to the shell

Rejected by the owner. A wrapper that asks the shell and falls back to
`playerctl` when the shell is down keeps the keys alive through a crash, but it
is a second code path that can pick a different player than the panel shows,
which breaks the central promise (keys and panel act on the same player). The
owner accepted that the keys do nothing when the shell is down.

### Handle the keys with an `IpcHandler` and `qs ipc call`

Rejected. No `IpcHandler` exists in the shell today, so this would add a new
mechanism. A `GlobalShortcut` per action reuses the pattern that every other
shell shortcut uses (`hypr/binds/shell.lua`).

### Poll with `busctl` for shuffle, loop and the track list (as the references do)

Rejected. Those features are out of scope, and the reference projects pay for
them with a permanent `busctl monitor` or a 3-second poll (study PF2, PF5).
Quickshell's built-in module needs no helper process for what we show.

### A permanent position timer

Rejected. Quickshell emits no position ticks, so a seek bar needs a timer, but
only while the panel is open and the player is playing. A timer that runs from
start-up (as one reference does, PF1) costs wake-ups for nothing.

### Compute the current player in each place that needs it (icon, panel, keys)

Rejected. The references drift when each part applies its own rule (PF12,
PF13). One selection object read by all three keeps the keys and the panel on
the same player, and one pure function can be tested with fakes.

### Put the selection inside the panel's state, behind the panel flag

Rejected. The keys must work with the panel closed and with the panel
disabled. The selection lives in a state that exists whenever it is
referenced, and two flags separate the panel from the keys.

### Key the pin and the art table by the D-Bus name

Rejected. Browsers register as `org.mpris.MediaPlayer2.firefox.instanceNNN`, so
the name changes when the browser restarts and the pin would die silently. The
key is the desktop entry, with the lower-cased identity as fallback.

### Show the previous track's art until the new one arrives

Rejected. It puts a wrong cover under the new title for as long as the fetch
takes, and art often arrives after the track change (`player.hpp` 361-364). The
panel shows the plain surface until the new art is ready.

### Persist the pin in a file

Rejected by the owner. The pin lives in memory for the shell session; a file
would be state to keep accurate, against the stateless rule.

### Pass the art address straight to the image control (as all three references do)

Rejected. Qt would fetch any scheme with no size cap, outside the limits the
script enforces, and an 8000 px cover decoded at full size is about 256 MB. The
image control receives only a local file with an explicit `sourceSize`.

### Build the whole art chain as one fixed script

Rejected by the owner's composability requirement: each mode and each tool must
be replaceable on its own.

### Art providers as one script per provider, or as functions in one script

Considered and not chosen. One script per provider keeps the adapter simpler (one
process per track, one kill on a skip) but swapping a tool inside a provider is
an argument or a script edit. One script with providers inside is the smallest,
but every new provider edits that script. Steps composed in config were chosen
as the most flexible; the cost is a small pipeline runner in the art adapter.
The step contract is the same in all three, so a later move to the other
structures wraps the same steps.

### A live blur of the cover instead of blurhash

Not chosen. One `MultiEffect` on the cover would need no encoder, decoder or
shrink tool, and the reference projects use it. It needs a GPU renderer (the
offscreen tests cannot draw it), costs more per frame than a small decoded
image, and leaves the owner's installed blurhash tools unused. Because art is a
provider, a `blur` provider can be added later as a config entry plus a QML
backdrop, without changing the panel.

### Build the cover first and blurhash later

Not decided here. The pieces are independent, so the phases can add the
contract and the `cover` provider first and `blurhash` after; the Technical Plan
keeps both in phase 3 and leaves the order inside it to the detailed
implementation.

## Detailed Implementation

No code here; names, contracts and values only. Paths are relative to the
repository root. The module follows `shell/modules/audio/` (state, shortcut,
surface, panel); the adapters follow the polkit feature's injectable pattern
(`shell/adapters/PolkitAuth.qml`, tests in `tests/auth/`). Each phase updates the
documentation for what it adds (README, `STYLE.md`, the `EGM.md` contracts).

### Contracts

*   **Player (what `MediaSelection` reads).** Quickshell's `MprisPlayer` and the
    test `FakePlayer` expose the same members: `dbusName`, `identity`,
    `desktopEntry`, `trackTitle`, `trackArtist`, `trackArtUrl`, `isPlaying`,
    `canTogglePlaying`, `canPause`, `canGoNext`, `canGoPrevious`, `canSeek`,
    `positionSupported`, `lengthSupported`, `position` (settable, seconds),
    `length` (seconds; equals `position` when `lengthSupported` is false), the
    signal `positionChanged()`, and the methods `togglePlaying()`, `pause()`,
    `next()`, `previous()` and `seek(offset)` (relative, seconds). There is no
    `key` member: the selection computes it with `keyOf(player)`.
*   **Source (what `MediaSelection` is injected with).** An object with one
    property, `players`: a JavaScript array of players that re-evaluates when a
    player appears or leaves. `MprisSource` (real), the empty source of
    `UI_SHELL_MPRIS_SOURCE=off` (`players` is an empty array), `PreviewSource`
    (shipped preview) and `FakeSource` (tests) all provide it. The selection
    watches each player's own changes (`isPlaying` and the rest) with one
    `Connections` per player created by an `Instantiator`; `FakePlayer` is a
    `QtObject` with real properties, so the same mechanism works in tests.
*   **`MediaSelection` members.** `current` (a player or `null`), `playerCount`,
    `pinKey` (string, empty when none), `pinState` (`none`, `active` or
    `absent`); actions `pin(key)`, `unpin()`, `showPlayer(delta)`, `playPause()`,
    `pause()`, `next()`, `previous()` and `seekBy(seconds)`; and
    `keyOf(player)`, which returns the desktop entry lower-cased, else the
    identity lower-cased. The behaviour of `showPlayer` is in the Technical Plan.
*   **`MediaArt` members.** `state` (`none`, `loading`, `ready` or `failed`),
    `kind` (`cover`, `blurhash` or `""`, taken from the mode), `path` (the `path`
    of the last step, an absolute local file, or `""`), the signal
    `faultReported(failure)` with
    `{ source: "mpris", sequence, title, message, operation, target, details }`
    for the shared `ErrorPopup` (`sequence` increases only for a new cause: step,
    error code and player key). Inputs, all properties set by `MprisState` so
    tests set them by name: `player` (bound to `selection.current`), `runner`,
    `enabled` (true only while the panel is open), `defaultMode`, `modes`
    (`artModes`), `providers`, `cacheDir`, `debounceMs`, `shrinkSize`, `blurhashComponents`,
    `blurhashDecodeSize`, `downloadMaxBytes`, `stepTimeoutSeconds`,
    `shrinkTools`, `blurhashEncoder`, `blurhashDecoder`,
    `cacheMaxBytes`, `cacheMaxEntries`, `failureMemorySeconds`. In phase 1
    `MprisState.art` is a plain object with the same three members
    (`state: "none"`, `kind: ""`, `path: ""`); from phase 3 it is the
    `MediaArt` instance.
*   **`MediaArtRunner` interface.** `run(step, flags, input, runKey)` starts one
    process (`flags` is an array of strings); `kill()` stops it; the signal
    `finished(runKey, result)` carries the parsed JSON line. A non-zero exit,
    empty output or output that is not valid JSON becomes
    `{ ok: false, error: "tool-failed", detail }`. `FakeRunner` has the same
    members. `MediaArt` passes `--dir` (its `cacheDir`) and the flags below.
*   **Step script (`scripts/media-art STEP [FLAGS] INPUT`, and the maintenance
    subcommand `prune`).** Bash, like the other scripts, with a local `fail()`
    that prints a usage error to stderr and exits 2. A handled outcome exits 0
    and prints exactly one JSON line, `{"ok":true,"path":"..."}` or
    `{"ok":false,"error":"<code>","detail":"..."}`; this is a deliberate
    difference from `screen-shot` and `screen-record` (which exit 1 with
    stderr), because the runner needs a machine-readable cause. Error codes:
    `scheme`, `bad-input` (silent) and `missing-tool`, `timeout`, `too-large`,
    `tool-failed` (reported). Common flags for every step: `--dir DIR` (the
    cache directory; `UI_SHELL_MPRIS_DIR`, else `$XDG_RUNTIME_DIR/ui-shell/mpris`,
    created `0700`) and `--timeout S` (`stepTimeoutSeconds`). Each step names its
    own output file in `DIR` (a hash of the input plus the step name) and reuses
    it when it already exists, so QML never hashes. The previous step's `path`
    is the next step's `INPUT`. Steps:
    *   `fetch --max-bytes N ADDRESS`: only `http`, `https`,
        `file://` and plain absolute paths are accepted (`data:`, `blob:` and
        everything else is `scheme`); a local file is validated (regular file, at
        most `--max-bytes`) and its own path is returned with no copy; a remote
        file is downloaded to a temporary name and moved into place only when
        complete.
    *   `shrink --tool vips|ffmpeg --size N SRC`: writes a copy whose
        longest edge is at most N (`shrinkSize`). `missing-tool` when the tool is
        not found.
    *   `blurhash --encoder PATH --decoder PATH --components X,Y --size N SRC`:
        encodes then decodes to a small PNG (`--size` is `blurhashDecodeSize`).
        Tool names are looked up in `PATH`, then in `$HOME/.local/bin`. If phase 0
        shows the decoder's output needs converting, an optional
        `--convert TOOL` flag is added to this step (see "Phase 0 outcomes").
    *   `prune --dir DIR --max-bytes N --max-entries N --keep PATH`: not a
        provider step and takes no input; removes the oldest files in `DIR` beyond
        either cap, never `PATH` (the file currently shown), and prints
        `{"ok":true,"removed":N}`. `MediaArt` runs it after each finished chain.
*   **Key tables.** `Config.Mpris.panelKeys` maps an action to a Qt key and
    reuses `Config.Keyboard` where a key already exists: `seekBack` is
    `Config.Keyboard.previousKey` (Left), `seekForward` is `nextKey` (Right),
    `playerPrevious` is `rowUpKey` (Up), `playerNext` is `rowDownKey` (Down),
    `playPause` is `selectKey` (Space), `close` is `cancelKey` (Esc); the new
    keys are `next` N, `previous` P and `pin` K.
    `Config.Mpris.keyShortcuts` has one line per action, in the layout
    `playPause: { name: "media-play-pause", description: ... }` (and `pause`,
    `next`, `previous`), so `check-mpris` can read it line by line. All five
    shortcuts (the panel's and these four) use `shortcutAppId`. In
    `hypr/profile.lua`, `media_keys` is an ordered array, one line per entry:
    `{ action = "playPause", key = "XF86AudioPlay", target = "ui-shell:media-play-pause", description = "Play or pause" }`
    (then `pause` with `XF86AudioStop`, `next` with `XF86AudioNext`, `previous`
    with `XF86AudioPrev`); `hardware.lua` iterates it with `ipairs`. `XF86AudioStop`
    keeps its "pause" meaning.
*   **Ctrl+E settings.** Component `mpris`, two options: `seekStep` (choices 5,
    10, 15, 30; fallback `Config.Mpris.seekStepSeconds`) and `artMode`
    (choices `auto`, `cover`, `blurhash`, `off`, with labels; fallback
    `Config.Mpris.artMode`, `auto`). `scripts/render-mpris-settings SEEK_STEP
    DEFAULT_ART_MODE` accepts the literal `undefined` for either argument (no
    override, as `render-shot-settings` does), exits 2 for any other value
    outside the choices, and prints the settings file with `seekStep` as an
    unquoted integer and `artMode` as a quoted string. The panel owns the
    `ComponentSettings { component: "mpris" }` instance for its output and
    resolves the effective values with `settings.option(...)`: it passes the
    seek step to the card and, while the panel is open, sets
    `MprisState.artMode` with a `Binding`; `auto` uses the per-player table.

### `Config.Mpris` values

| Key | Default |
|---|---|
| `namespace` | `"ui-shell-mpris"` |
| `asynchronousPanelLoad` | `true` |
| `outerMargin` | 24 |
| `shortcutAppId`, `shortcutName` | `"ui-shell"`, `"media-panel"` |
| `keyShortcuts`, `panelKeys` | as in "Key tables" |
| `iconVisibility` | `"whenPlayer"` (`always`; `whenPlayer`: at least one player exists; `never`) |
| `seekStepSeconds` | 10 |
| `positionTickMs` | 1000 |
| `panelSize` | 460 (the panel is a square: width and height) |
| `artScrimOpacity`, `artMutedOpacity` | 0.62 (the permanent dim over the art), 0.78 (secondary text over art) |
| `artSourceSize` | 640 (pixels, longest edge, for the image control; an 8000 px cover is capped at load) |
| `artShrinkSize` | 256 |
| `blurhashComponents` | `"4,3"` (maps to `--components`) |
| `blurhashDecodeSize` | 32 |
| `artDebounceMs` | 250 |
| `downloadMaxBytes` | 20971520 (20 MiB) |
| `stepTimeoutSeconds` | 10 |
| `cacheMaxBytes`, `cacheMaxEntries` | 67108864 (64 MiB), 40 |
| `failureMemorySeconds` | 60 |
| `hotCacheEntries`, `artFadeMs` | 8, 240 |
| `shrinkTools` | `["vips", "ffmpeg"]` (the first one installed is used; fetching always uses curl) |
| `blurhashEncoder`, `blurhashDecoder` | `"blurhash_encoder"`, `"blurhash_decoder"` |
| `providers` | `cover: ["fetch"]`, `blurhash: ["fetch", "shrink", "blurhash"]`, `off: []` |
| `artMode`, `artDefaultMode` | `"auto"` (applies to every player; auto uses `artModes`), `"cover"` (for a player with no entry) |
| `artModes` | `mpd` and `music player daemon` (the identity fallback when `mpd-mpris` gives no desktop entry): `cover`; `firefox`, `chromium`, `brave-browser`, `google-chrome`, `zen`: `blurhash` (the exact keys are confirmed in phase 0) |

### New files

Adapters (`shell/adapters/`):

*   `shell/adapters/MprisSource.qml`: `Singleton`, the only importer of
    `Quickshell.Services.Mpris`; exposes `players` as in the contract.
*   `shell/adapters/MediaSelection.qml`: the selection logic, an ordinary
    component with no imports beyond QtQuick, QtQml.Models (for the `Instantiator`)
    and an injected `source`; it must
    import nothing relative, because the test copy sits at a different depth.
*   `shell/adapters/MediaArt.qml`: the art logic, an ordinary component with no
    imports beyond QtQuick; the debounce, the run key (player key plus art
    address), the step chain from `providers`, the negative cache, the failure
    rules and `prune`. Config values arrive as properties.
*   `shell/adapters/MediaArtRunner.qml`: wraps one `Process` running
    `commands.mediaArt`; the only place that starts the script. Not copied for
    tests (it reads `Config.GeneratedRuntime`); `FakeRunner` replaces it.

Module (`shell/modules/mpris/`):

*   `shell/modules/mpris/qmldir`: phase 1 registers `MprisState` (singleton),
    `MprisShortcut`, `MprisSurface`, `MprisPanel`, `MprisCard`,
    `MprisArtBackdrop`, `PreviewSource`; phase 2 adds `MprisKeys`.
*   `shell/modules/mpris/MprisState.qml`: `QtObject` singleton with `open`,
    `screenName`, `show(output)`, `source` (from `UI_SHELL_MPRIS_SOURCE`: `real`
    default, `preview`, `off`; `MprisSource` is referenced only for `real`, as
    `AuthState` does for the polkit source), `selection` (a `MediaSelection` on
    that source) and `art` (see the contract). Env `UI_SHELL_OPEN_MPRIS=1` opens
    the panel at start.
*   `shell/modules/mpris/PreviewSource.qml`: shipped fake players for
    `UI_SHELL_MPRIS_SOURCE=preview`, working enough to judge the look: play and
    pause toggle `isPlaying`, `position` advances while playing, `seek` moves it,
    `next` and `previous` change the title, one player has `canSeek` false and one
    reports no length. The sample cover `preview-cover.png` (512 by 512, drawn
    by the author, no third-party image) is used only from phase 3; in phase 1
    the backdrop ignores it.
*   `shell/modules/mpris/MprisShortcut.qml`: `GlobalShortcut`
    `ui-shell:media-panel` toggling the panel on the launcher-policy output
    (`Config.Outputs.launcherScreen`), like `AudioShortcut.qml`.
*   `shell/modules/mpris/MprisKeys.qml` (phase 2): a `Scope` with four
    `GlobalShortcut`s from `Config.Mpris.keyShortcuts`, each calling the matching
    selection action.
*   `shell/modules/mpris/MprisSurface.qml`: the per-output overlay window in the
    shape of `AudioSurface.qml` (not `ShotSurface.qml`, whose capture-hiding
    logic is not needed), with one deliberate improvement: the namespace comes
    from `Config.Mpris.namespace`, not a literal (as `Config.Auth.namespace` does).
    Layer Overlay, exclusive keyboard while open, `ExclusionMode.Ignore`; hosts
    the panel.
*   `shell/modules/mpris/MprisPanel.qml`: the window content, as `ShotPanel.qml`
    is for the shot module: hosts `PanelContext` (help entries on Ctrl+Space, the
    Ctrl+I info popup showing the shown player's identity, the pin state and the
    art mode in use, and Ctrl+E settings), owns the
    `ComponentSettings { component: "mpris" }` instance with this output's
    `screenName`, wires its `onFailed` and the art `faultReported` signal to the
    `ErrorPopup`, uses `PanelMotion`, and contains the card. It is not built in
    unit tests.
*   `shell/modules/mpris/MprisCard.qml`: everything shown and every key, with
    required properties `selection`, `art`, `seekStep`, `style`, `inputState`: the
    backdrop, title, artist, three `ShellButton`s, the seek `ShellSlider`
    (`focusPolicy: Qt.NoFocus`), the pin button, the position timer, and the
    keys from `panelKeys` handled before the focused control. It imports only the
    `components`, `config` and `theme` folders and none of their adapters, so
    tests can build it. (`PanelContext` and `ComponentSettingsEditor` import
    `../adapters`, which is why they stay in `MprisPanel`.)
*   `shell/modules/mpris/MprisArtBackdrop.qml`: the image (explicit `sourceSize`,
    `asynchronous`, `PreserveAspectCrop`; `smooth: true` for the blurhash kind) or
    the plain themed surface, under
    `style.scrimColor(Config.Mpris.artScrimOpacity)`. In phase 1 it shows only
    the plain themed surface.
*   `shell/modules/mpris/EGM.md`: the module contract.

Bar (`shell/modules/bar/`):

*   `shell/modules/bar/MprisButton.qml`: the bar icon as in the Technical Plan,
    importing `../mpris`. Its `visible` is `ShellConfig.Config.mprisEnabled` and
    (`iconVisibility` is `always`, or it is `whenPlayer` and
    `selection.playerCount > 0`). Placed after `RecordButton` in `Bar.qml` with
    `Layout.fillHeight: true`.

Config:

*   `shell/config/Mpris.qml`: the `Config.Mpris` singleton with every value in the
    table above.

Scripts:

*   `scripts/media-art`: the step script as in the contract.
*   `scripts/render-mpris-settings`: renders the saved Ctrl+E options.

Tests:

*   `tests/tst_MediaSelection.qml`, `tests/tst_MprisCard.qml` and (phase 3)
    `tests/tst_MediaArt.qml`.
*   `tests/mpris/FakePlayer.qml`, `FakeSource.qml` (phase 1) and `FakeRunner.qml`
    (phase 3): fakes with the same members as the real objects; the card suite uses
    the real `MediaSelection` on a `FakeSource`. `tests/mpris/` holds the fakes;
    `shell/tests/mpris/` (created by `check-qml` at run time) holds copies of the
    shell files under test.
*   `tests/scripts/check-media-art`: runs the script steps with stand-ins for
    `curl`, the shrink tools and the blurhash tools (scheme allow-list,
    size cap, timeout on every step, atomic write, refused `data:` and `blob:`, a
    local file returned in place, an existing file reused, `prune` keeping the
    shown file, a missing tool).
*   `tests/scripts/check-mpris`: `MprisSurface.qml` reads the namespace from
    `Config.Mpris.namespace`; that value equals the pattern in `hypr/rules.lua`;
    the `name` values in `Config.Mpris.keyShortcuts` (one per line) equal the
    `target` values in `hypr/profile.lua` `media_keys` (one entry per line);
    `hardware.lua` has no `playerctl` line.

### Modified files

Hyprland:

*   `hypr/profile.lua`: phase 1: `shell_shortcuts.media_panel = { key = "N",
    target = "ui-shell:media-panel" }`. Phase 2: `media_keys` as in the contract.
*   `hypr/user/nested.lua`: phase 1: move `workspace_empty_bind` from
    `CTRL + ALT + N` to `CTRL + ALT + E`, so the nested panel key does not clash.
*   `hypr/binds/shell.lua`: phase 1: add the panel bind (`main_mod` plus `N`).
*   `hypr/binds/hardware.lua`: phase 2: remove the four `playerctl` lines; add
    one `hl.dsp.global` bind per `media_keys` entry with `locked = true`, in the
    same change as `MprisKeys`.
*   `hypr/rules.lua`: add `mpris` to the `shell-owns-motion` pattern.

Shell wiring:

*   `shell/shell.qml`: import `modules/mpris`; a `Loader` for `MprisShortcut` on
    `mprisEnabled`; a `Variants` for `MprisSurface` with its model gated on
    `mprisEnabled`; (phase 2) a `Loader` for `MprisKeys` on `mprisKeysEnabled`.
    Mutual exclusion keeps the existing one-way pattern (the handlers are not a
    full mesh): add `Mpris.MprisState.open = false` to the close list of each
    existing handler (picker, apps, record, shot, tuning, audio), and add a new
    handler for `MprisState.open` that closes those six. Auth stays outside it.
*   `shell/config/Config.qml`: `mprisEnabled` (phase 1) and `mprisKeysEnabled`
    (phase 2).
*   `shell/config/qmldir`: add `singleton Mpris 1.0 Mpris.qml`.
    `shell/adapters/qmldir`: add `singleton MprisSource`, `MediaSelection` (phase
    1) and `MediaArt`, `MediaArtRunner` (phase 3).
*   `shell/modules/bar/Bar.qml`: place `MprisButton`.
*   `shell/config/ComponentSpec.qml`: add the `mpris` entry.

Settings and commands:

*   `scripts/component-settings-path`: allow `mpris`.
*   `scripts/save-component-settings`: add the `mpris` case.
*   `scripts/read-shell-config`: add `mediaArt` (phase 3) and
    `renderMprisSettings` (phase 1) to the default command list and the
    exact-keys list.
*   `tools/config.ini`: add `mediaArt = scripts/media-art` and
    `renderMprisSettings = scripts/render-mpris-settings`.
*   `tests/scripts/check-component-settings`: add `mpris` cases (renderer shape,
    `undefined` accepted, a value outside the choices rejected, the path, a save
    digest).

Tests and docs:

*   `tests/scripts/check-qml`: create `shell/tests/mpris/`; copy
    `shell/adapters/MediaSelection.qml`, `shell/modules/mpris/MprisCard.qml` and
    `shell/modules/mpris/MprisArtBackdrop.qml` into it in phase 1 (their relative
    imports stay valid at that depth, which is the same as `shell/modules/*`) and
    `shell/adapters/MediaArt.qml` in phase 3; add the suite names to the
    `for` list on line 18-22.
*   `tests/scripts/test-nested`: add `--setenv` lines for `UI_SHELL_OPEN_MPRIS`
    and `UI_SHELL_MPRIS_SOURCE` (default `off`, because the nested session has no
    players and a real watcher could log a warning the harness treats as fatal)
    next to `UI_SHELL_OPEN_AUTH`.
*   `tests/targets.mk`: add `test-mpris` (runs `check-mpris`, and from phase 3
    `check-media-art`; the QML suites run under `test-qml`) to `.PHONY`,
    `test-help` and the `test` aggregate.
*   `tests/README.md`: the owner live check ("Media control, live").
*   `README.md`: the feature, the panel key (SUPER + N), the pin, the media keys
    moving to the shell and what happens when the shell is down, and the tools.
*   `STYLE.md`: the position-timer exception to "no polling" and the rule that
    every panel and key reads the one shared selection.
*   `shell/EGM.md`, `shell/adapters/EGM.md`, `shell/config/EGM.md`,
    `shell/modules/EGM.md` and `shell/modules/bar/EGM.md`: each lists every file
    of its folder, so each gains the new files that sit in it.
*   Brain: update `brain/pages/mpris-media-control.md` through the `brain` CLI
    when the phase 0 results arrive.

### Phase 0 outcomes that change the plan

*   Blurhash decoder output: if Qt cannot load what `blurhash_decoder` writes, the
    `blurhash` step gets the optional `--convert TOOL` flag and converts it. If a
    tool is slow on a large cover, the `shrink` step already runs before it.
*   Lock screen: if a global shortcut with `locked = true` does not fire on the
    lock screen, the media keys work when unlocked and the README says so.
*   Players that start after the shell (U1): if the watcher misses them, the
    selection re-reads on `Mpris.players` changes only; the fix is a Quickshell
    question, not a design change, and the README records the limit.
*   `playerctld` (U14): if it never appears, the exclusion stays as a harmless
    guard.
*   `mpd-mpris` and the browser (art, position, `canSeek`): the shipped `artModes`
    keys are corrected to the real desktop entries or identities.

### Order of work

1.  Phase 0 spike (owner on the host; no repository files).
2.  Phase 1: `MprisSource`, `MediaSelection`, `PreviewSource`, `MprisState`,
    `Config.Mpris`, `mprisEnabled`, `MprisCard`, `MprisPanel`, the backdrop
    (plain surface only), the surface, the shortcut, the bar icon, the
    `shell.qml` wiring and mutual exclusion, `rules.lua`, the panel bind in
    `profile.lua`, `shell.lua` and the nested bind move, the Ctrl+E settings
    (`ComponentSpec`, `render-mpris-settings`, the registrations,
    `check-component-settings`), the fakes, `tst_MediaSelection`,
    `tst_MprisCard`, `check-qml`, `test-nested`, `check-mpris` (without the key
    checks), `test-mpris`, and the phase 1 docs.
3.  Phase 2: `MprisKeys`, `mprisKeysEnabled`, `media_keys` in `profile.lua`, the
    `hardware.lua` change, the `check-mpris` key checks, and the phase 2 docs.
4.  Phase 3: `scripts/media-art`, `MediaArt`, `MediaArtRunner`, the backdrop's
    image, `PreviewSource`'s cover, `tst_MediaArt`, `check-media-art`, the
    `mediaArt` registrations, and the phase 3 docs.

### Checks before each phase is called done

*   `make test-qml`, `make test-mpris` and `make test-hypr-config` pass; the
    existing suites still pass; `make test-env-snapshot` with no preview passes
    as it did before the change.
*   The owner confirms the look of the panel in the nested preview
    (`UI_SHELL_MPRIS_SOURCE=preview UI_SHELL_OPEN_MPRIS=1 make test-env`) and the
    live checks on the host (mpd, YouTube, the keys). No result from the nested
    session counts as a live check.
*   No literal colours or sizes in new components; durations and limits come from
    `Config.Mpris` or `Theme.Motion`.

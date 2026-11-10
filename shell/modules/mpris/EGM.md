# mpris

## Overview
The media control: shows what the current player is playing and controls it. Design: `features/designs/mpris.md`. All three phases are built: the panel, the selection, the bar entry, the panel key, the media keys and the art backdrop.

## Interface
- `MprisState` (singleton): `open`, `screenName`, `show(output)`, `source`, `selection` (a `MediaSelection`), `art` (a `MediaArt`: `state`, `kind`, `path`, `faultReported`), `artMode` (auto, cover, blurhash or off: applies to every player; auto uses the per-player table), `cacheDir`; env `UI_SHELL_OPEN_MPRIS=1` opens the panel at start, `UI_SHELL_MPRIS_SOURCE=real|preview|off` picks the player source [mpris/MprisState.qml].
- `MprisShortcut`: `GlobalShortcut` `ui-shell:media-panel` toggles the panel [mpris/MprisShortcut.qml].
- `MprisKeys`: four `GlobalShortcut`s (`media-play-pause`, `media-pause`, `media-next`, `media-previous`) calling the selection's actions; loaded on `Config.mprisKeysEnabled`, independent of the panel flag [mpris/MprisKeys.qml].
- `MarqueeText`: one line of fixed height that scrolls to the end and back when it does not fit (speed and pauses from `Config.Mpris`); static with an ellipsis when not running or with motion off [mpris/MarqueeText.qml].
- Icons are `Controls.Icon` pictures from the shared components (rendered at exactly their size in device pixels and centred on whole pixels so their edges stay sharp; tinted by the theme; the card's controls use even sizes, `transportIconSize` 26, `playIconSize` 32, `arrowIconSize` 16, `pinIconSize` 18): `media-play`, `media-pause`, `media-previous`, `media-next`, `arrow-left`, `arrow-right`, `pin-circle`, `pin-circle-filled`, `tape-music-cassette` and, in the bar, `audio-player`. See `shell/components/EGM.md` (`Icon`).
- `MprisSurface`: overlay window per output, namespace from `Config.Mpris.namespace` [mpris/MprisSurface.qml].
- `MprisPanel`: window content: context popups (keys, information, settings), the saved settings for the output, the card [mpris/MprisPanel.qml].
- `MprisCard`: everything shown and every key: a header (cassette icon, player name, icon pin button at the top right), the title and artist as one scrolling line each, the seek bar, the icon transport buttons, and the one-row player selector (left and right buttons and one square per player); required `selection`, `art`, `seekStep`, `style`, `inputState`; imports no adapter, so tests build it [mpris/MprisCard.qml].
- `MprisArtBackdrop` and `MprisArtLayer`: two alternating layers; a new picture waits invisible until it has loaded, fades in over the old one (which stays opaque underneath until the new one is complete, so the surface never shows through), then the old one is dropped; no art fades out onto the surface; a dim layer (`Config.Mpris.artScrimOpacity`) is permanently above both pictures, at the same strength with or without art, so a bright cover never shows at full brightness and the card's brightness never jumps; the picture is a local file from the art script decoded at a capped `sourceSize`; a file that cannot be loaded is reported (`pictureLost`) so the adapter forgets and remakes it [mpris/MprisArtBackdrop.qml, MprisArtLayer.qml].
- `PreviewSource`: fake players for the preview [mpris/PreviewSource.qml].

## Invariants
- The bar entry, the panel and the keys read only `selection.current`; none reads the Mpris module.
- The only timer is the card's position tick (`Config.Mpris.positionTickMs`), running only while the panel is open and the shown player is playing and has a length.
- The seek bar is hidden when the player gives no length (Quickshell would return the position as the length) and disabled when `canSeek` is false.
- The namespace appears in `Config.Mpris` and `hypr/rules.lua`; `tests/scripts/check-mpris` fails if they differ.
- Selection state is atomic: `current` is a pure function of the player list, the numbers and the pin; a new playing player is ranked as already numbered, so `current` changes once and never shows a wrong player in between. Players with the same key (two windows of one app) are one entry, the playing one shown. A player with no desktop entry or identity is keyed by its bus name. Actions are capability-gated and a call on a player that has quit is dropped.
- Held keys: only seeking repeats; play or pause, skip, pin and player switching ignore auto-repeat.
- A stream (no length) has a live bar (elapsed time, a sweeping segment, "LIVE") instead of a slider; a track whose length is known but cannot be sought has a disabled slider.
- Secondary text and icons over art are lifted towards the main text colour (`artMutedOpacity`), fading with the art.
- The card is a square (`Config.Mpris.panelSize`, height equal to width); the free space sits between the title block and the seek row, so the controls stay at the bottom.
- The card never changes size: every row is always present with a fixed height (the seek row is hidden by opacity, the selector buttons are disabled with one player), and the title and artist never wrap.
- Hot cache: the last `Config.Mpris.hotCacheEntries` finished requests are kept in memory by key and shown at once, with no step and no empty moment, when the same state returns. At start `scripts/media-art capabilities` says which tools exist; until it answers nothing runs, and without the blurhash tools a player set to blurhash uses the cover and the settings do not offer it.
- Art is keyed on (player, mode, art address): a change kills the running step and drops its result, so a skipped track's art never shows; the previous art is not kept while the next loads; real faults (`missing-tool`, `timeout`, `too-large`, `tool-failed`) are reported once per cause, `scheme` and `bad-input` are silent.
- A pin is kept while its player is absent and shown differently from an active pin.
- The media keys call the same selection the panel reads; if the shell is down they do nothing (the `playerctl` binds are gone).

## Side Effects
- Holds exclusive keyboard focus while the panel is open; Esc closes it.
- Art: `MprisState.art` runs `scripts/media-art` (through `MediaArtRunner`) only while the panel is open; the open panel gives it the default mode from its Ctrl+E settings and shows its faults in its `ErrorPopup`.
- Reads the session's players through `Adapters.MprisSource` unless the source is `preview` or `off`.

## Verification
- Run: `make test-qml` (tst_MediaSelection, tst_MprisCard), `make test-mpris`, `make test-hypr-config`; live check in `tests/README.md` ("Media control, live").

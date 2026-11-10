# clipboard (Clipboard History)

## Overview
Overlay panel that lists, searches, previews, copies and deletes the entries of the package's own `cliphist` store. All reads and writes go through `Adapters.ClipboardRunner`; this directory holds no capture or storage code. Package URI `UiShell.Clipboard` ([qmldir]).

## Interface
- `ClipboardState` singleton: `open`, `screenName`, `lateFailure`; `show(output)`, `toggle(output)` [ClipboardState.qml:ClipboardState]
- `ClipboardSearch` singleton: `results(items, query)` [ClipboardSearch.qml:ClipboardSearch]
- `ClipboardShortcut`: `GlobalShortcut` (`Config.Clipboard.shortcutAppId` / `shortcutName`), toggles `ClipboardState` on `Config.Outputs.launcherScreen(...)` [ClipboardShortcut.qml]
- `ClipboardSurface`: per-screen `Scope` with a scrim `PanelWindow` and a card `PanelWindow`; `modelData`, `inputState`, `shown` [ClipboardSurface.qml:ClipboardSurface]
- `ClipboardPanel`: `screenName`, `inputState`, `runner`, `shown`, `query`, `selectedIndex`, `selectedLine`, `confirmingClear`, `previewOpen`, `previewSource`, `previewState`, `matches`, `selectedEntry`, `ready`, `busy`, `closing`, `idle`, `notice`, `pageSize`; `activate()`, `forget()`, `requestClose()`, `select(index)`, `moveSelection(delta)`, `copySelection()`, `copySelectionContent()`, `removeSelection()`, `askToClear()`, `confirmClear()`, `togglePreview()`, `refresh()`, `showHelp()`, `presentLateFailure()`, `handleKey(event)`; signal `closed()` [ClipboardPanel.qml:ClipboardPanel]
- `ClipboardRow`: `entry`, `style`, `inputState`, `selected`, `candidateVisible`, `keyboardCandidate`, `badge`, `label`; signals `chosen()`, `activated()`, `previewRequested()` [ClipboardRow.qml:ClipboardRow]

## Invariants
- A search matches only when every space-separated word occurs in the entry's `text`, case-insensitively; the history order is kept and never re-ranked [ClipboardSearch.qml:results].
- The scrim and the card are separate windows so only the card (namespace `Config.Clipboard.namespace`) can be hidden from screen capture; the scrim uses `Config.Clipboard.scrimNamespace`, layer `Top`, no keyboard focus; the card uses layer `Overlay` and `Exclusive` keyboard focus only while visible [ClipboardSurface.qml].
- Row badges are `File`, `Image`, `Data`, otherwise `Text`; row labels render as `PlainText`, one line [ClipboardRow.qml:badge, label].
- Copy and copy-content call the runner and then `requestClose()` at once; copy-content acts only on entries with `kind === "file"` [ClipboardPanel.qml:copySelection, copySelectionContent].
- A copy failure that arrives after the panel closed sets `ClipboardState.lateFailure` and reopens the panel on `Config.Outputs.launcherScreen(...)`; `presentLateFailure()` clears it once shown [ClipboardState.qml:lateFailures, ClipboardPanel.qml:presentLateFailure].
- The picture preview loads only when the preview is open and the selected entry has `kind === "image"`, after `Config.Clipboard.imageDelayMilliseconds`; a result for another line is ignored [ClipboardPanel.qml:refreshPreview, imageDelay, onImageLoaded].
- Clearing needs a second confirmation (`Enter`); a runner failure resets `confirmingClear` [ClipboardPanel.qml:askToClear, confirmClear, onFailed].
- `requestClose()` dismisses in this order: error popup, context popup, clear confirmation, then the panel [ClipboardPanel.qml:requestClose].
- Mutating actions run only while `idle` (not busy, closing, or showing a popup) [ClipboardPanel.qml:idle].
- Only the visible panel reacts to runner signals; the runner is shared by every screen's panel [ClipboardPanel.qml:Connections].

## Side Effects
- Runner calls: `refresh`, `copy`, `copyContent`, `remove`, `wipe`, `loadImage`, `cancelImage`, `forget` [ClipboardPanel.qml; adapters/ClipboardRunner.qml].
- Env: `UI_SHELL_OPEN_CLIPBOARD=1` opens the panel at start-up on the launcher screen [ClipboardState.qml].
- Layer-shell windows: scrim (`Top`) and card (`Overlay`, exclusive keyboard focus while open) [ClipboardSurface.qml].
- Registers the global shortcut `ui-shell` / `clipboard` [ClipboardShortcut.qml].

## Verification
- Run: `make test-qml`, `make test-clipboard`

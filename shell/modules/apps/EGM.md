# apps (Application Launcher)

## Overview
Overlay application launcher: a per-output layer-shell surface hosting a searchable list of desktop entries, launched through an adapter runner. Package URI `UiShell.Apps` ([apps/qmldir]).

## Interface
- `AppState` singleton: `open`, `screenName`, `show(output)` [apps/AppState.qml:AppState]
- `AppCatalog` singleton (extends `AppSearch`): `entries` bound to `DesktopEntries.applications.values`; `hiddenEntryIds`/`searchFields` from `Config.AppLauncher` [apps/AppCatalog.qml:AppCatalog]
- `AppSearch`: `index` (filtered, normalized, name-sorted), `score(text, token)`, `results(query)` [apps/AppSearch.qml:results]
- `AppShortcut`: `GlobalShortcut` (appid/name from `Config.AppLauncher.shortcutAppId`/`shortcutName`); `preparedCatalog` warms `AppCatalog.index` when `Config.AppLauncher.warmCatalog` [apps/AppShortcut.qml:AppShortcut]
- `AppSurface`: per-screen `PanelWindow` (`modelData`, `inputState`, `panel`, `panelRequested`) [apps/AppSurface.qml:AppSurface]
- `AppPanel`: `FocusScope` with `query`, `selectedIndex`, `matches`, `selectedEntry`, `busy`, `error`, `closed()`, `activate()`, `choose()`, `moveSelection()`, `launchSelection()`, `requestClose()`, `showContext()`, `handleKey()` [apps/AppPanel.qml:AppPanel]
- `AppRow`: row delegate with `entry`, `selected`, `launching`, signals `chosen()`, `activated()` [apps/AppRow.qml:AppRow]

## Invariants
- Hidden (`noDisplay`) entries and ids in `hiddenEntryIds` never appear in results [apps/AppSearch.qml:index].
- Ranking is deterministic: rank then original index (`order`) [apps/AppSearch.qml:results].
- Selection/launch/close-by-choice are ignored while `busy`, `closing`, a context popup or error popup is open [apps/AppPanel.qml:choose, launchSelection].
- Esc closes in order: error popup, context popup, panel [apps/AppPanel.qml:requestClose].
- Surface is visible only on `AppState.screenName`; keyboard focus is Exclusive only while visible [apps/AppSurface.qml:visible, WlrLayershell.keyboardFocus].
- Panel is created lazily (`panelRequested`) and dropped on hide unless `Config.AppLauncher.retainPanelAfterClose` [apps/AppSurface.qml:onVisibleChanged].
- A successful launch (`onAccepted`) closes the panel; failure opens `ErrorPopup` [apps/AppPanel.qml:runner].

## Side Effects
- Launches applications through `Adapters.AppRunner` using `Config.AppLauncher.runnerExecutable`/`runnerArguments` [apps/AppPanel.qml:runner].
- Reads env `UI_SHELL_OPEN_APPS=1` to open at startup [apps/AppState.qml:Component.onCompleted].
- Registers a Hyprland global shortcut [apps/AppShortcut.qml:AppShortcut].
- Creates a layer-shell Overlay window, namespace `ui-shell-app-launcher`, exclusive keyboard focus [apps/AppSurface.qml:WlrLayershell].
- Calls `componentOptions.refresh()` (Adapters.ComponentSettings) on activate [apps/AppPanel.qml:activate].

## Verification
- Run: `make test-qml`

- Search results animate: the list model is a `ScriptModel` over `AppCatalog.results(query)`, which diffs by identity so rows that stay slide to their new place and new or dropped rows fade (technique from refs/nixnew launcher). Rows are not pooled (`reuseItems: false`); durations are `Theme.Motion.list*`.

# wallpaper (Wallpaper Picker)

## Overview
Overlay grid picker for per-output or shared-default wallpapers, which hands off to the theme editor popup to apply wallpaper and palette. Package URI `UiShell.Wallpaper` ([wallpaper/qmldir]).

## Interface
- `PickerState` singleton: `open`, `screenName`, `targetOutput`, `colorMode`, `cacheNamespace`, `savedTargets`, `currentTargets`, `startupTargets`; `selectionFor`, `savedPath`, `startupPath`, `currentPath`, `fitMode`, `appliedSelection`, `saveSelection` [wallpaper/PickerState.qml:PickerState]
- `PickerShortcut`: `GlobalShortcut` (`ShellConfig.WallpaperPicker.shortcutAppId`/`shortcutName`) [wallpaper/PickerShortcut.qml]
- `PickerSurface`: per-screen `PanelWindow` [wallpaper/PickerSurface.qml:PickerSurface]
- `PickerPanel`: `query`, `selectedIndex`, `filteredWallpapers`, `selectedWallpaper`, `themeEditor`; `activate()`, `choose()`, `moveSelection()`, `chooseTheme()`, `requestClose()`, `reportFailure()`, `handleKey()`, `closed()` [wallpaper/PickerPanel.qml:PickerPanel]
- `PickerHeader` (`targetChosen(int)`, `queryEdited(string)`, `searchKeyPressed`), `PickerFooter` (`themeRequested()`), `WallpaperTile` (`chosen()`, `activated()`) [wallpaper/PickerHeader.qml, PickerFooter.qml, WallpaperTile.qml]

## Invariants
- A default target (`id === ""`) must exist or `selectionFor` throws `PickerState: the configured default wallpaper is missing` [wallpaper/PickerState.qml:selectionFor].
- Targets are `Shared default` plus `Quickshell.screens` [wallpaper/PickerPanel.qml:targets].
- Selection/choose blocked while applying, closing, or any popup/theme editor is open [wallpaper/PickerPanel.qml:choose].
- Close order: theme editor (unless busy), error, context, panel [wallpaper/PickerPanel.qml:requestClose].
- `PickerState` re-syncs saved/current targets on `Theme.ActivePalettes.profileApplied` [wallpaper/PickerState.qml:profileChanges].
- Panel dropped on hide unless `Config.WallpaperPicker.retainPanelAfterClose` [wallpaper/PickerSurface.qml].

## Side Effects
- Env `UI_SHELL_OPEN_PICKER=1` opens at startup [wallpaper/PickerState.qml].
- Wallpaper/palette applied through `Themes.ThemeEditorPopup` / `Adapters.ThemeProfiles`; `onApplied` closes panel [wallpaper/PickerPanel.qml:profilePopup].
- Layer-shell Overlay, namespace `ui-shell-wallpaper-picker`, exclusive keyboard focus [wallpaper/PickerSurface.qml].
- Reads `ShellConfig.GeneratedWallpapers.items` and `GeneratedRuntime.wallpaperTargets` [wallpaper/PickerPanel.qml, PickerState.qml].

## Verification
- Run: `make test-qml`

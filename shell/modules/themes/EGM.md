# themes (Theme Editor)

## Overview
Palette/profile editing UI used as a popup from the wallpaper picker. Package URI `UiShell.Themes` ([themes/qmldir]). Persistence is delegated to `Adapters.ThemeProfiles`.

## Interface
- `ThemeEditor`: `ColumnLayout` with `profileModel`, `style`, `screenName`, `targetOutput`, `sourceId`, `mode`, `colors`, `customName`, `dirty`, `editable`, `custom`, `sourceChoices`; functions `begin(selection)`, `resetDraft()`, `save()`, `chooseSource()`, `edit(role, color)`, `draftSignature()`; signals `saved()`, `back()` [themes/ThemeEditor.qml:ThemeEditor]
- `ThemeEditorPopup`: `Controls.ContextPopup` with `screenName`, `targetOutput`, `wallpaperSelection`, `editor`, `profileModel`, `errorPopup`; `begin(selection, previousFocus)`, `resetDraft()`, `disclose(kind)`, `handleKey(event)`; signal `applied()` [themes/ThemeEditorPopup.qml:ThemeEditorPopup]

## Invariants
- Colours are editable only when `editable` (snapshot ready, not busy) and the source is `custom` [themes/ThemeEditor.qml:edit].
- `save()` requires `editable`, no failed source, and an acceptable name when custom [themes/ThemeEditor.qml:save].
- `dirty` compares `draftSignature()` to `savedSignature`; a failed palette load restores the previous draft [themes/ThemeEditor.qml:dirty, Connections.onFailed].
- Role list comes from `Config.ThemeEditor.roles`, sources from `Config.ThemeEditor.sources` plus snapshot palettes [themes/ThemeEditor.qml].

## Side Effects
- `profileModel.save(...)` commits profile/palette via `Adapters.ThemeProfiles` [themes/ThemeEditor.qml:save].
- Failures surface in `Controls.ErrorPopup` [themes/ThemeEditorPopup.qml:profiles.onFailed].
- Registers local `Shortcut`s for info/help keys [themes/ThemeEditorPopup.qml].

## Verification
- Run: `make test-qml`

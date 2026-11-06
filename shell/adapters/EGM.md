# adapters

## Overview
QML adapters between the shell UI and external helpers (app2unit, PipeWire helper, settings/theme helper scripts). Helper command paths come from `Config.GeneratedRuntime.commands`; each adapter wraps a `Quickshell.Io` `Process` and exposes state/error properties. Module `UiShell.Adapters` ([adapters/qmldir]).

## Interface
- `AppRunner` [AppRunner.qml:AppRunner]: required `executable`, `launchArguments`; `launch(entry)`, `reportFailure(message, details)`; properties `busy`, `error`, `status`, `output`, `failure`, `failureSequence`; signals `accepted()`, `failed(message)`.
- `AudioGraph` [AudioGraph.qml:AudioGraph]: `active`, `graph`, `ready`, `error`, `command`; `refresh()`, `run(args, key)` (keyed actions coalesce), `next()`.
- `QmlSettingsFile` [QmlSettingsFile.qml:QmlSettingsFile]: required `component`, `scope`, `outputName`; `path`, `revision`, `values`, `mode`, `ready`, `error`, `reading`; `refresh()`, `accept(item)`; signal `settled()`.
- `ComponentSettings` [ComponentSettings.qml:ComponentSettings]: required `component`, `screenName`; `showIcons`, `visibleRows`, `wideColumns`, `maximumVisibleRows`, `ready`, `loading`, `busy`, `loadError`, `saveError`, `failure`; `option(key)`, `value(key, default)`, `sharedValue`, `refresh()`, `save(scope, revision, first, second)`; signals `scopeReady`, `committed`, `failed`.
- `ThemeProfiles` [ThemeProfiles.qml:ThemeProfiles]: required `screenName`; `snapshot`, `snapshotReady`, `busy`, `outputs`, `wallpaperSelection`; `refresh(wallpaperColors)`, `loadProfile(path)`, `reset()`, `readPalette(path)`, `save(id, target, source, mode, colorData, writeDefinition, definitionPath)`; signals `ready`, `paletteReady`, `committed`, `failed`.
- `ControlTuningStore` (singleton) [ControlTuningStore.qml:ControlTuningStore]: `ready`, `busy`, `error`, `revision`; `known(values)`, `reload()`, `save(mode, values)`; signal `saved()`.

## Invariants
- `AppRunner.launch` ignores calls while `launchPending`; always runs `<executable> <launchArguments> -- <entry.id>.desktop` [AppRunner.qml:launch].
- `AudioGraph` runs one action at a time; `snapshot` output is the sole source of truth, `pw-dump --monitor` only triggers a debounced refresh [AudioGraph.qml:next, debounce, watcher].
- `QmlSettingsFile` accepts a file only when the helper returns exactly two lines: absolute path and revision `absent` or 64-hex; "controls" values must be finite numbers; other components are validated by `Config.ComponentSpec.valid` [QmlSettingsFile.qml:inspect, accept].
- `ComponentSettings.value` precedence: output override, shared default, then configured default; `save` is rejected while `busy` or for scopes other than `default`/`output` [ComponentSettings.qml:value, save].
- `ControlTuningStore.known` drops keys not in `Theme.ControlTuning.schema`; `save` stores only knobs differing from `presetValues(mode)` [ControlTuningStore.qml:known, save].
- `ThemeProfiles` ignores `start`/`loadProfile`/`save` while `busy`; helper reply must be `<absolute path>\n<64-hex revision>` [ThemeProfiles.qml:start, process.onExited].

## Side Effects
- Spawns `app2unit` via `AppRunner` [AppRunner.qml:runner].
- Spawns `Config.GeneratedRuntime.commands.audioGraph` (`snapshot` and action args) and `pw-dump --monitor --no-colors --indent 0` [AudioGraph.qml:reader, actor, watcher].
- Spawns `commands.readComponentSettings` and `commands.saveComponentSettings`; loads the returned settings file as QML via `file://` Loader [QmlSettingsFile.qml:inspect, qml; ComponentSettings.qml:writer].
- Spawns `commands.readThemeEditor`, `readThemePalette`, `saveThemeProfile`; loads generated native theme data via Loader; on save calls `Theme.ActivePalettes.apply` [ThemeProfiles.qml:process, data, accept].
- `ControlTuningStore` writes component "controls" settings and binds `Theme.ControlTuning.overrides` and `.mode` [ControlTuningStore.qml:Binding, writer].

## Verification
- Run: `make test-qml`

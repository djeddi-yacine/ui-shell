# config

## Overview
Singleton QML configuration for the shell: feature toggles, key bindings, panel geometry, and per-component option specs. Module `UiShell.Config` ([config/qmldir]). Three files are source-tree placeholders replaced at runtime preparation (see Side Effects).

## Interface
- `Config` [Config.qml]: `watchSourceFiles`, `barEnabled`, `appLauncherEnabled`, `controlTuningEnabled`, `audioControlEnabled`, `screenRecordEnabled`, `screenShotEnabled`, `barHeight`, `barLabel`, `barWorkspaceNumbers`, `barWorkspacesEnabled`, `barControlMode`, `notificationsEnabled` (mirrors `Notifications.enabled`).
- `AppLauncher` [AppLauncher.qml]: shortcut (`shortcutAppId`, `shortcutName`), runner (`runnerExecutable`, `runnerArguments`), layout, row and key properties (`visibleRows`, `showIcons`, `previousKey`, ...).
- `Audio` [Audio.qml]: `shortcutName`, `maximumVolumePercent`, `volumeStepPercent`, `refreshDelay`, layout sizes.
- `ComponentSpec` [ComponentSpec.qml:components, valid]: option tables (any number of options; integer, boolean or choices of numbers or strings, with optional labels) for `launcher`, `wallpaper`, `audio`, `record`, `shot`, `notifications`; `valid(option, value)`; `validRules(value)` returns `""` or the first problem of a notification rules list.
- `Keyboard` [Keyboard.qml]: key/modifier constants, `namedKeys`, `shortcut(key, modifiers)`.
- `WallpaperPicker` [WallpaperPicker.qml], `ThemeEditor` [ThemeEditor.qml] (roles, sources, colorChannels), `Tuning` [Tuning.qml], `ContextPanels` [ContextPanels.qml], `ErrorPanels` [ErrorPanels.qml]: panel geometry and key settings.
- `Outputs` [Outputs.qml:launcherScreen, pickerScreen]: target-screen selection by `screen-index` or `output-name`.
- `GeneratedLauncherOutput` [GeneratedLauncherOutput.qml], `GeneratedWallpapers` [GeneratedWallpapers.qml:items], `GeneratedRuntime` [GeneratedRuntime.qml: configFile, paths, commands, bootstrap, bundle, profileColors, wallpaperTargets, xdg, theme, wallpaperFolders].
- `Auth` (singleton) [Auth.qml]: `namespace`, `inputGuardMs`, `startupGraceMs`, `cardWidth`, `fieldHeight`, `scrimOpacity`, status texts.
- `Mpris` (singleton) [Mpris.qml]: namespace, shortcut names, panel size, seek step, tick, `panelKeys`, `keyShortcuts`, and the art values used from phase 3.
- `Config` gains `mprisEnabled` (bar entry, panel, panel key) and `mprisKeysEnabled` (the four media keys).
- `Mpris` also holds the art limits (sizes, caps, timeouts, cache bounds), the tool names and the provider table; `commands.mediaArt` is `scripts/media-art`; `blurhashAvailable` is set at start from the tool check and hides the mode in the settings.
- `Notifications` (singleton) [Notifications.qml]: `enabled`, timeouts (`lowTimeoutMs`, `normalTimeoutMs`, `maxTimeoutMs`), sound (`soundEnabled`, `soundFile`), `popupNamespace`, `drawerNamespace`, shortcut names (`shortcutDrawer`, `shortcutDnd`, `shortcutDismiss`), card and drawer sizes, the stack deck (`deckDepth`, `deckPeek`, `deckScaleStep`, `deckShade`), `arrivalWindowMs`, icon button sizes.

## Invariants
- `Outputs` never substitutes another screen: unsupported mode or missing target logs `console.error` and returns `null` [Outputs.qml:launcherScreen, pickerScreen].
- `Outputs.launcher*` use `GeneratedLauncherOutput` values only when not `undefined` [Outputs.qml:launcherTargetMode].
- `ComponentSpec.valid` accepts `undefined`; booleans must be boolean; integers must be in range or in `choices` [ComponentSpec.qml:valid].
- `Keyboard.shortcut` throws for modifiers or keys without an explicit name [Keyboard.qml:shortcut].
- `ErrorPanels.dismissKey` is `Keyboard.cancelKey` [ErrorPanels.qml:dismissKey].

## Side Effects
- None at runtime in this directory (pure `QtObject` singletons).
- Placeholders overwritten by runtime preparation: `GeneratedRuntime.qml` header comment "Source-tree declaration only. Staging replaces it from config.ini before use"; `GeneratedWallpapers.qml` comment "Placeholder only. Runtime preparation generates the configured folders". `GeneratedLauncherOutput.qml` is documented as an optional generated override [Outputs.qml comment "Generated values override only launcher hosting"].
- `ComponentSpec.validRules` allows only the keys `name`, `app`, `appId`, `appMatch`, `match`, `mute`, `hide`, `reveal`, `sound`; `name` is required; strings and booleans are type-checked; `sound` must be an absolute `.wav`, `.ogg` or `.oga` path; `appMatch` and `match` must compile as regular expressions [ComponentSpec.qml:validRules]. The `notifications` option `rules` is hand-written, never edited in the Ctrl+E popup.

## Verification
- Run: `make test-qml`

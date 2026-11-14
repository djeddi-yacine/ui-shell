# KColorScheme: KDE Frameworks colour-scheme library (KF6ColorScheme), with KColorUtils and KHCY maths

Source: refs/kcolorscheme (shallow clone; commit edb5ea0; branch main; KF_VERSION 6.33.0). Companion clone for the colour maths: refs/kguiaddons (commit e183b86), files `refs/kguiaddons/src/colors/kcolorutils.cpp` and `kcolorspaces.cpp`. License: library sources `LGPL-2.0-or-later` (for example `src/kcolorscheme.cpp:5`); CMake files `BSD-2-Clause` (`CMakeLists.txt:2`); `README.md.license:2` and `metainfo.yaml:2` `CC0-1.0`; autotests `LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL` (`autotests/kcolorschemetest.cpp:4`); license texts in `LICENSES/`. Scope: src/ (all .cpp/.h), src/color-schemes/, autotests/, CMakeLists.txt, src/CMakeLists.txt, autotests/CMakeLists.txt. Not studied: po/, src/*.qdoc, src/Messages.sh, KF6ColorSchemeConfig.cmake.in, metainfo.yaml body. Paths without a prefix are relative to refs/kcolorscheme.
Id prefix: KCS.

## 1. Purpose and shape
- KCS1.1 KColorScheme is a KF6 library that "expands on QPalette" with colour sets, roles and shades, and reads the colour-scheme files (`*.colors`) as KConfig files. Stated in the class comment (`src/kcolorscheme.h:24-53`) and `README.md:1-3` ("Classes to read and interact with KColorScheme"). The class comment says "five distinct sets" (`src/kcolorscheme.h:30`), but the enum has seven values (KCS3.1); see KCS6.1.
- KCS1.2 Classes: `KColorScheme` (`src/kcolorscheme.h:55`), `KStatefulBrush` (`src/kstatefulbrush.h:42`), `KColorSchemeManager` (`src/kcolorschememanager.h:59`), `KColorSchemeModel` (QAbstractListModel, `src/kcolorschememodel.h:29`), plus internal `KColorSchemePrivate`, `StateEffects` and `KColorSchemeManagerPrivate` (KCS4.x).
- KCS1.3 Layout: `src/` holds 13 sources and headers (kcolorscheme.cpp 697 lines, kcolorscheme.h 433, kcolorschememanager.cpp 342, kcolorschememanager.h 196, kstatefulbrush.cpp 101, kstatefulbrush.h 127, kcolorschememodel.cpp 112, kcolorschememodel.h 55, kcolorschemehelpers_p.h 85, kcolorschememanager_p.h), `src/color-schemes/` (BreezeDark.colors, BreezeLight.colors, ExtraDesktop.sh), `autotests/` (kcolorschemetest.cpp, kcolorschemetest.colors, CMakeLists.txt).
- KCS1.4 Build system: CMake with ECM. Project version `KF_VERSION "6.33.0"` (`CMakeLists.txt:6`); dependency version `KF_DEP_VERSION "6.32.0"` (`CMakeLists.txt:7`); `find_package(ECM 6.32.0 NO_MODULE)` (`CMakeLists.txt:11`). Only the KF6 / Qt6 line exists; no KF5 or Qt5 branch.
- KCS1.5 Minimum Qt: `REQUIRED_QT_VERSION 6.10.0` (`CMakeLists.txt:31`), `find_package(Qt6 ... CONFIG REQUIRED Gui)` (`CMakeLists.txt:32`). Qt6GuiPrivate is required when `Qt6Gui_VERSION >= 6.10.0` (`CMakeLists.txt:33-36`).
- KCS1.6 Minimum KF6 dependencies: KF6Config, KF6GuiAddons, KF6I18n, each at `KF_DEP_VERSION` 6.32.0 and REQUIRED (`CMakeLists.txt:46-48`).
- KCS1.7 Library target: `KF6ColorScheme`, alias `KF6::ColorScheme` (`src/CMakeLists.txt:4-5`); `VERSION ${KCOLORSCHEME_VERSION}` and `SOVERSION ${KCOLORSCHEME_SOVERSION}` (`src/CMakeLists.txt:8-9`). The two variables are not defined in the files read (KCS6.4).
- KCS1.8 Link set: PUBLIC `KF6::ConfigCore`, `Qt6::Gui`; PRIVATE `Qt6::GuiPrivate`, `KF6::ConfigGui` (comment: needed so QColor I/O from KConfig works), `KF6::GuiAddons` (comment: "KColorScheme uses KColorUtils"), `KF6::I18n` (`src/CMakeLists.txt:49-57`).
- KCS1.9 Bundled resources: `qt_add_resources(KF6ColorScheme "color_schemes" PREFIX "/org.kde.kcolorscheme" ...)` with `color-schemes/BreezeDark.colors` and `color-schemes/BreezeLight.colors` (`src/CMakeLists.txt:20-24`). `ExtraDesktop.sh` is a helper script (`find -name \*.colors -print`, `src/color-schemes/ExtraDesktop.sh`), not a scheme and not in the resource list.
- KCS1.10 Export and deprecation: `ecm_generate_export_header` with `DEPRECATION_VERSIONS 6.6 6.19` (`src/CMakeLists.txt:37-45`). Deprecated members are guarded with `KCOLORSCHEME_ENABLE_DEPRECATED_SINCE(6, 6)` (`src/kcolorschememanager.h:63`) and `(6, 19)` (`src/kcolorschememanager.h:101`, `src/kcolorschememanager.cpp:293`).
- KCS1.11 Public headers installed: KColorScheme, KColorSchemeManager, KColorSchemeModel, KStatefulBrush (`ecm_generate_headers` at `src/CMakeLists.txt:60`, `install(FILES ...)` at `:72`).

## 2. Theme input (scheme files, config keys, how settings reach the library)
- KCS2.1 A scheme is a KConfig (INI-style) file with the extension `.colors`. The model keys entries by file name without `.colors` (`src/kcolorschememodel.cpp:68`), so the id is the base name, for example `BreezeLight`.
- KCS2.2 Discovery: `QStandardPaths::locateAll(GenericDataLocation, "color-schemes", LocateDirectory)` (`src/kcolorschememodel.cpp:47`). Android uses `assets:/share/color-schemes` instead (`:49`). The bundled resource directory `:/org.kde.kcolorscheme/color-schemes` is appended last (`:53`).
- KCS2.3 Collision rule: all `*.colors` names go into a `std::map<QString, QString>` keyed by file name, and `map.insert` is used (`:56-62`). `std::map::insert` does not replace an existing key, so the first entry in the search order wins. The code comment says the `$HOME` copy overrides the system copy (`:44-46`). With `locateAll` returning user directories first (Qt behaviour, not verified in refs/qtbase), the bundled resource loses to any file on disk with the same name.
- KCS2.4 Display name: `[General] Name`, default = file base name (`src/kcolorschememodel.cpp:66-67`). Row 0 is always an entry with empty id and path, named "Default" and icon `edit-undo` (`:73`).
- KCS2.5 Scheme file opening: the model uses `KSharedConfig::openConfig(path, KConfig::SimpleConfig)` (`src/kcolorschememodel.cpp:65`). Palette activation uses `KSharedConfig::openConfig(colorSchemePath)` without `SimpleConfig` (`src/kcolorschememanager.cpp:64`). The preview uses `SimpleConfig` (`src/kcolorschememanager.cpp:101`).
- KCS2.6 Keys read from a scheme file are listed in KCS3.2. Group names: `Colors:View`, `Colors:Window`, `Colors:Button`, `Colors:Selection`, `Colors:Tooltip`, `Colors:Complementary`, `Colors:Header`, and optional `[<group>][Inactive]` subgroups (`src/kcolorscheme.cpp:289-404`; example `src/color-schemes/BreezeLight.colors:71`).
- KCS2.7 Effect keys read from `[ColorEffects:Inactive]` and `[ColorEffects:Disabled]`: `Enable`, `IntensityEffect`, `IntensityAmount`, `ColorEffect`, `ColorAmount`, `Color`, `ContrastEffect`, `ContrastAmount` (`src/kcolorscheme.cpp:36-49`). `[ColorEffects:Inactive]` also has `ChangeSelectionColor` (`src/kcolorscheme.cpp:307`).
- KCS2.8 Contrast: `[KDE] contrast` integer, default 7 (`src/kcolorscheme.cpp:526`). Frame contrast: `[KDE] frameContrast` double, default 0.2, clamped 0..1 (`src/kcolorscheme.cpp:532`, `:538`). Bundled schemes set `contrast=4` (`src/color-schemes/BreezeLight.colors:193`, `BreezeDark.colors:194`).
- KCS2.9 Active scheme path: the application property `KDE_COLOR_SCHEME_PATH` (a QString). `activateSchemeInternal` sets it before the palette change (`src/kcolorschememanager.cpp:55-61`, comment at `:57-59`: the property must be set before the palette change because it is checked on ApplicationPaletteChange). Read in `defaultConfig()` (`src/kcolorschemehelpers_p.h:26`) and in `init()` and `automaticColorSchemeId()` (`src/kcolorschememanager.cpp:70`, `:157`).
- KCS2.10 `defaultConfig()` (`src/kcolorschemehelpers_p.h:20-35`): caches a `static thread_local` KSharedConfigPtr; returns a null pointer (system palette path, KCS3.14) when the property is empty and `contrastPreference() == HighContrast` (`:28-30`); otherwise opens `KSharedConfig::openConfig(colorSchemePath)` (`:32-33`). An empty path is used to mean the default config. This is the code comment's reading ("equivalent to openConfig()", `:24-25`); the KSharedConfig behaviour was not traced in refs/kconfig.
- KCS2.11 Application-level selection: `KColorSchemeManager::init()` reads `[UiSettings] ColorScheme` from `KSharedConfig::openConfig()` (`src/kcolorschememanager.cpp:172-176`). A value that is not an id is treated as a legacy scheme name and re-saved as an id (`:177-184`). Empty value: automatic (`:186-198`), unless a platform theme already set `KDE_COLOR_SCHEME_PATH` (`:190-196`). Otherwise the stored path is applied (`:199-205`).
- KCS2.12 Automatic choice: `automaticColorSchemeId()` returns empty for KDE platform theme or when the property is already set (`src/kcolorschememanager.cpp:70-73`), empty for high contrast (`:75-77`), `getDarkColorScheme()` when `styleHints()->colorScheme() == Dark` (`:79-81`), else `getLightColorScheme()` (`:83`). Defaults `BreezeLight` and `BreezeDark` (`src/kcolorschememanager_p.h:45-46`).
- KCS2.13 Manual selection: `activateScheme(index)` (`src/kcolorschememanager.cpp:254-270`) and `activateSchemeId(id)` (`:273-290`) set the activated id and, when `m_autosaveChanges` is on, call `saveSchemeIdToConfigFile` (`:305-315`), which writes `[UiSettings] ColorScheme` (or reverts it to default when empty).
- KCS2.14 Change tracking: the manager reconnects `styleHints()::colorSchemeChanged` and `accessibility()::contrastPreferenceChanged` to re-apply the automatic scheme unless a scheme was set by hand (`src/kcolorschememanager.cpp:161-170`).
- KCS2.15 Environment variables: `qgetenv("XDG_CURRENT_DESKTOP")` only, inside `isKdePlatformTheme()` (`src/kcolorschememanager.cpp:38-53`, env read at `:46`). No other env var is read in this tree.

## 3. Colour and style model
### 3.1 Enumerations (numeric values follow declaration order)
- KCS3.1 ColorSet: View=0, Window=1, Button=2, Selection=3, Tooltip=4, Complementary=5, Header=6, NColorSets (`src/kcolorscheme.h:92-100`). Meanings: View (frames, input fields, `:67`), Window (non-editable window elements such as menus, `:71`), Button (`:75`), Selection (selected items, `:79`), Tooltip (`:83`), Complementary (`:88`), Header (`:92-93`).
- KCS3.2 BackgroundRole: NormalBackground=0, AlternateBackground=1, ActiveBackground=2, LinkBackground=3, VisitedBackground=4, NegativeBackground=5, NeutralBackground=6, PositiveBackground=7 (`src/kcolorscheme.h:138-146`).
- KCS3.3 ForegroundRole: NormalText=0, InactiveText=1, ActiveText=2, LinkText=3, VisitedText=4, NegativeText=5, NeutralText=6, PositiveText=7 (`src/kcolorscheme.h:196-204`).
- KCS3.4 DecorationRole: FocusColor=0, HoverColor=1 (`src/kcolorscheme.h:224-226`).
- KCS3.5 ShadeRole: LightShade=0, MidlightShade=1, MidShade=2, DarkShade=3, ShadowShade=4 (`src/kcolorscheme.h:249-255`). Shades are "neither foreground nor background"; they are for 3D elements and not for text (`src/kcolorscheme.h:236-238`).
- KCS3.6 Out-of-range accessors return the NormalBackground, NormalText or FocusColor brush (`src/kcolorscheme.cpp:468-493`).

### 3.2 Serialized colour keys (per group)
- KCS3.7 Foreground keys: `ForegroundNormal`, `ForegroundInactive`, `ForegroundActive`, `ForegroundLink`, `ForegroundVisited`, `ForegroundNegative`, `ForegroundNeutral`, `ForegroundPositive`. Background keys: `BackgroundNormal`, `BackgroundAlternate`. Decoration keys: `DecorationFocus`, `DecorationHover` (`src/kcolorscheme.cpp:251-278`). Values are `r,g,b` integers (`src/color-schemes/BreezeLight.colors:31-41` for `[Colors:Button]`).
- KCS3.8 Built-in fallback tables for each set: `defaultViewColors` (`src/kcolorscheme.cpp:122`), `defaultWindowColors` (`:135`), `defaultButtonColors` (`:148`), `defaultSelectionColors` (`:161`), `defaultTooltipColors` (`:174`), `defaultComplementaryColors` (`:187`), `defaultHeaderColors` (`:200`), `defaultDecorationColors` (`:213`, Focus 61,174,233; Hover 147,206,233). Values are from BreezeLight (comment `src/kcolorscheme.cpp:119-120`).
- KCS3.9 Fallback values for a missing key: the table in KCS3.8 (`loadSerializedColors`, `src/kcolorscheme.cpp:251-270`; `loadDecorationColors`, `:272-278`).

### 3.3 Per-set group selection (`initFromConfig`, `src/kcolorscheme.cpp:289-404`)
- KCS3.10 View -> `Colors:View`; Window -> `Colors:Window`; Button -> `Colors:Button`; Tooltip -> `Colors:Tooltip`; Complementary -> `Colors:Complementary`; NColorSets falls through to View with a warning (`src/kcolorscheme.cpp:296-342`).
- KCS3.11 Header: group `Colors:Header`, but its fallback colours are read from `Colors:Window` with `defaultHeaderColors` as the last fallback, and its decoration fallbacks are read from `Colors:Window` (`src/kcolorscheme.cpp:330-334`).
- KCS3.12 Selection, state Active: `Colors:Selection`. State Inactive with `ChangeSelectionColor` false (default: value of `[ColorEffects:Inactive] Enable`, default true; `:307`): `Colors:Selection`. State Inactive with `ChangeSelectionColor` true: `Colors:Window` plus a tint colour read from `Colors:Selection BackgroundNormal` (default 61,174,233) (`src/kcolorscheme.cpp:304-321`). Disabled: `Colors:Window` without tint (`:318-320`).
- KCS3.13 Inactive subgroup: if state is Inactive and the group `<group>][Inactive` exists, its keys replace the group (`src/kcolorscheme.cpp:346-352`; `hasInactivePalette` set at `:350`). Example in the bundled file: `[Colors:Header][Inactive]` (`src/color-schemes/BreezeLight.colors:71`).
- KCS3.14 System palette path: when `defaultConfig()` returns null (high contrast and no scheme path, KCS2.10), `initFromSystemPalette` uses `qApp->palette()` (`src/kcolorscheme.cpp:408-466`). Mapping per set: Button -> ButtonText/Button, Tooltip -> ToolTipText/ToolTipBase, Selection -> HighlightedText/Highlight, View -> Text/Base, Window/Complementary/Header -> WindowText/Window (`:417-438`). Links use Link and LinkVisited; AlternateBackground uses AlternateBase (`:452-456`); focus and hover both use Highlight (`:462-463`). Contrast uses `contrastF({})` (`:448`).

### 3.4 Tint for inactive selection
- KCS3.15 When the tint branch of KCS3.12 applies, `NormalBackground` and `AlternateBackground` are each replaced by `KColorUtils::tint(bg, tintColor, 0.4)` (`src/kcolorscheme.cpp:375-378`). This happens before state effects.

### 3.5 State effects (`StateEffects`)
- KCS3.16 Enum codes (`src/kcolorschemehelpers_p.h:57-79`): Intensity: 0 none, 1 Shade, 2 Darken, 3 Lighten. Color: 0 none, 1 Desaturate, 2 Fade, 3 Tint. Contrast: 0 none, 1 Fade, 2 Tint.
- KCS3.17 Defaults when the group has no `Enable` key (`src/kcolorscheme.cpp:39-49`). `Enable` defaults to true only for Disabled (`:40`).
  - Disabled: IntensityEffect 2 (Darken), IntensityAmount 0.10; ColorEffect 0 (none), ColorAmount 0.0; ContrastEffect 1 (Fade), ContrastAmount 0.65; effect colour 56,56,56 (`:41-49`).
  - Inactive: IntensityEffect 0 (none), IntensityAmount 0.0; ColorEffect 1 (Desaturate), ColorAmount -0.9; ContrastEffect 2 (Tint), ContrastAmount 0.25; effect colour 112,111,110 (`:41-49`).
  - Effect colour is read only if ColorEffect is above 0 (`:47-48`).
- KCS3.18 Shipped values (`src/color-schemes/BreezeLight.colors:9-27`): Disabled: ColorEffect 0, IntensityEffect 2, IntensityAmount 0.1, ContrastEffect 1, ContrastAmount 0.65. Inactive: Enable=false, ColorEffect 2 (Fade), ColorAmount 0.025, ContrastEffect 2 (Tint), ContrastAmount 0.1, IntensityEffect 0. With `Enable=false` the Inactive effects are not applied.
- KCS3.19 Background brush effect, in order (`src/kcolorscheme.cpp:54-80`):
  1. Intensity Shade: `c' = KColorUtils::shade(c, amount)` (ky=amount, kc=0). Darken: `darken(c, amount)` (kc default 1.0). Lighten: `lighten(c, amount)` (kc default 1.0) (`:56-64`).
  2. Color Desaturate: `c' = darken(c, 0.0, 1.0 - amount)`, that is chroma multiplied by `1 - amount` (with the default -0.9 this multiplies chroma by 1.9) (`:66-70`). Fade: `mix(c, effectColour, amount)` (`:71-73`). Tint: `tint(c, effectColour, amount)` (`:74-76`).
- KCS3.20 Foreground and decoration brush effect (`src/kcolorscheme.cpp:82-97`): first Contrast: Fade `c' = mix(fg, bg, amount)`; Tint `c' = tint(fg, bg, amount)`; then the background-style chain of KCS3.19 is applied to the result. `bg` is `NormalBackground` after tint (`src/kcolorscheme.cpp:380-388`).
- KCS3.21 Application order inside `initFromConfig` (`src/kcolorscheme.cpp:380-391`): the condition is `state != Active || (state == Inactive && !hasInactivePalette)`. Because the second disjunct is contained in the first, the condition is true for every non-Active state, including Inactive when an `[Inactive]` subgroup was read. The subgroup therefore does not suppress state effects in the code as written. Each foreground and decoration brush gets the contrast effect against NormalBackground; NormalBackground and AlternateBackground get the background chain.
- KCS3.22 Calculated backgrounds (`src/kcolorscheme.cpp:393-404`): ActiveBackground, LinkBackground, VisitedBackground, NegativeBackground, NeutralBackground and PositiveBackground are each `KColorUtils::tint(NormalBackground, fg, 0.3)` where fg is ActiveText, LinkText, VisitedText, NegativeText, NeutralText, PositiveText respectively. The tint amount 0.3 is the default of the 3-argument KColorUtils::tint (`refs/kguiaddons/src/colors/kcolorutils.h:172`).

### 3.6 Shade maths (`KColorScheme::shade`, `src/kcolorscheme.cpp:556-616`)
- KCS3.23 Public entry points: `shade(role)` uses `background().color()` and the set's contrast (`:556-559`); `shade(color, role)` uses `contrastF()` with the global config (`:561-564`); `shade(color, role, contrast, chromaAdjust=0.0)` is the core (`src/kcolorscheme.h:351`, `src/kcolorscheme.cpp:566`).
- KCS3.24 Contrast clamp: `contrast = (1.0 > contrast ? (-1.0 < contrast ? contrast : -1.0) : 1.0)` (`:569`). NaN maps to 1.0 (the comparison is false, so the `: 1.0` branch is taken). Matches the comment in the same function (`:569`) "nan -> 1.0".
- KCS3.25 Luma and inverse: `y = KColorUtils::luma(color)` (`:570`), `yi = 1 - y` (`:571`). `luma` is defined in KCS3.31.
- KCS3.26 Very dark branch, `y < 0.006` (`:574-586`). Each call is `KColorUtils::shade(color, ky, chromaAdjust)` with:
  - LightShade: ky = 0.05 + 0.95*c (`:577`)
  - MidShade: ky = 0.01 + 0.20*c (`:579`)
  - DarkShade: ky = 0.02 + 0.40*c (`:581`)
  - MidlightShade and ShadowShade (default branch): ky = 0.03 + 0.60*c (`:583`)
  where c is the clamped contrast.
- KCS3.27 Very light branch, `y > 0.93` (`:588-598`):
  - MidlightShade: ky = -0.02 - 0.20*c (`:591`)
  - DarkShade: ky = -0.06 - 0.60*c (`:593`)
  - ShadowShade: ky = -0.10 - 0.90*c (`:595`)
  - LightShade and MidShade (default branch): ky = -0.04 - 0.40*c (`:597`)
- KCS3.28 General branch, `0.006 <= y <= 0.93` (`:601-615`):
  - lightAmount = (0.05 + y*0.55) * (0.25 + c*0.75) (`:602`)
  - darkAmount = (-y) * (0.55 + c*0.35) (`:603`)
  - LightShade: shade(color, lightAmount) (`:606`)
  - MidlightShade: shade(color, (0.15 + 0.35*yi) * lightAmount) (`:608`)
  - MidShade: shade(color, (0.35 + 0.15*y) * darkAmount) (`:610`)
  - DarkShade: shade(color, darkAmount) (`:612`)
  - ShadowShade (default): darken(shade(color, darkAmount, chromaAdjust), 0.5 + 0.3*y) with default chroma gain 1.0 (`:614`).
- KCS3.29 `chromaAdjust` is passed as the chroma argument (kc) of every `KColorUtils::shade` call in KCS3.26-3.28 (for example `:577`, `:606`). The Shadow branch's `darken` call uses its default chroma gain 1.0 (`refs/kguiaddons/src/colors/kcolorutils.h:140`).

### 3.7 KColorUtils and KHCY maths (refs/kguiaddons)
- KCS3.30 Helpers: `normalize(a) = (a < 1.0 ? (a > 0.0 ? a : 0.0) : 1.0)` (`refs/kguiaddons/src/colors/kguiaddons_colorhelpers_p.h:13-16`). For NaN the code returns 1.0 (the comparison `a < 1.0` is false), but the comment above it says NaN returns 0.0 (`:11-12`). This is a comment/code mismatch, recorded in KCS6.6. `mixQreal(a,b,t) = a + (b-a)*t` (`refs/kguiaddons/src/colors/kcolorutils.cpp:19-22`). `wrap(a, d=1) = r where r = fmod(a,d); r<0 -> d+r; r>0 -> r; else 0` (`refs/kguiaddons/src/colors/kcolorspaces.cpp:16-19`).
- KCS3.31 Luma: `KColorUtils::luma(c) = KHCY::luma(c) = 0.2126*g(R) + 0.7152*g(G) + 0.0722*g(B)`, with `g(n) = normalize(n)^2.2`, where R,G,B are `redF()` etc. Constants: `HCY_REC 709` (`refs/kguiaddons/src/colors/kcolorspaces.cpp:25`), `yc = {0.2126, 0.7152, 0.0722}` (`:28-29`); gamma 2.2 (`:34-37`); `KHCY::luma` at `:160-162`. The 601 set (0.299, 0.587, 0.114) and Qt set (0.34375, 0.5, 0.15625) are compiled out (`:26-31`).
- KCS3.32 Inverse gamma `igamma(n) = normalize(n)^(1/2.2)` (`refs/kguiaddons/src/colors/kcolorspaces.cpp:39-42`).
- KCS3.33 KHCY(QColor) constructor (`refs/kguiaddons/src/colors/kcolorspaces.cpp:57-87`): r,g,b = gamma(channel); a = alpha; y = 0.2126*r + 0.7152*g + 0.0722*b (`:65`). p = max(r,g,b), n = min(r,g,b), d = 6*(p-n). Hue h: if n==p then 0; else if r==p then (g-b)/d; else if g==p then (b-r)/d + 1/3; else (r-g)/d + 2/3 (`:67-80`). Chroma: if r==g==b then 0; else c = max((y-n)/y, (p-y)/(1-y)) (`:81-86`). The hue is not wrapped in the constructor; `KHCY::hue` wraps it with `wrap` (`:150-152`), and `getHcy` adds 1.0 to negative hue (`refs/kguiaddons/src/colors/kcolorutils.cpp:40-52`).
- KCS3.34 KHCY -> QColor (`refs/kguiaddons/src/colors/kcolorspaces.cpp:89-148`): h = wrap(h); c = normalize(c); y = normalize(y); hs = 6*h. Sector constants th and tm:
  - hs < 1: th = hs; tm = yc0 + yc1*th
  - hs < 2: th = 2 - hs; tm = yc1 + yc0*th
  - hs < 3: th = hs - 2; tm = yc1 + yc2*th
  - hs < 4: th = 4 - hs; tm = yc2 + yc1*th
  - hs < 5: th = hs - 4; tm = yc2 + yc0*th
  - else: th = 6 - hs; tm = yc0 + yc2*th
  (`:97-120`, the `tm` line for hs<1 at `:102`.)
- KCS3.35 Sorted channels (`:122-135`): if tm >= y: tp = y + y*c*(1-tm)/tm; to = y + y*c*(th-tm)/tm; tn = y - y*c. Else: tp = y + (1-y)*c; to = y + (1-y)*c*(th-tm)/(1-tm); tn = y - (1-y)*c*tm/(1-tm).
- KCS3.36 Channel order per sector (`:137-148`): hs<1: (tp,to,tn); hs<2: (to,tp,tn); hs<3: (tn,tp,to); hs<4: (tn,to,tp); hs<5: (to,tn,tp); else (tp,tn,to). Each channel goes through `igamma` into `QColor::fromRgbF`.
- KCS3.37 `KColorUtils::lighten(c, ky, kc=1.0)` (`refs/kguiaddons/src/colors/kcolorutils.cpp:73-79`; default in header `refs/kguiaddons/src/colors/kcolorutils.h:121`): y' = 1 - normalize((1-y)*(1-ky)); c' = 1 - normalize((1-c)*kc).
- KCS3.38 `darken(c, ky, kc=1.0)` (`:81-87`; header default `kcolorutils.h:140`): y' = normalize(y*(1-ky)); c' = normalize(c*kc).
- KCS3.39 `shade(c, ky, kc=0.0)` (`:89-95`; header default `kcolorutils.h:156`): y' = normalize(y+ky); c' = normalize(c+kc).
- KCS3.40 `contrastRatio(c1,c2) = (Ya+0.05)/(Yb+0.05)` with the larger luma first (`refs/kguiaddons/src/colors/kcolorutils.cpp:59-70`).
- KCS3.41 `mix(c1, c2, bias=0.5)` (`refs/kguiaddons/src/colors/kcolorutils.cpp:144-166`; default `kcolorutils.h:189`). bias <= 0 returns c1; bias >= 1 returns c2; NaN returns c1 (`:146-153`). a = alpha1 + (alpha2-alpha1)*bias (`:156`). Each channel X: X' = clamp(X1*alpha1 + (X2*alpha2 - X1*alpha1)*bias, 0, 1) / a (`:157-163`). Result `QColor::fromRgbF(r,g,b,a)`; if a <= 0 the result is transparent. The mix is linear, on gamma-encoded channel values, premultiplied by alpha.
- KCS3.42 `tint(base, color, amount=0.3)` (`refs/kguiaddons/src/colors/kcolorutils.cpp:113-142`; default `kcolorutils.h:172`). amount <= 0 returns base; amount >= 1 returns color; NaN returns base (`:114-121`). Steps:
  1. baseLuma = luma(base); ri = contrastRatio of luma(base) and luma(color) (`:122-123`).
  2. rg = 1 + (ri + 1) * amount^3 (`:127`).
  3. Bisection of a in [l=0, u=1], start a=0.5, 12 iterations (`:128-139`). Each step: a = (l+u)/2; resultLuma = luma(mix(base, color, a^0.3)) then blended as `baseLuma + (resultLuma - baseLuma)*a` (`:105-110`); ra = contrast ratio of baseLuma vs resultLuma; if ra > rg then u = a else l = a (`:135-138`).
  4. Return KHCY(mix(base, color, a^0.3)) with its Y replaced by `baseLuma + (Y - baseLuma)*a` (`:97-103`, `:141`). Hue and chroma come from the mixed colour; luma is the bisected value.
- KCS3.43 `KColorUtils::hcyColor`, `getHcy`, `hue`, `chroma` are thin wrappers over KHCY (`refs/kguiaddons/src/colors/kcolorutils.cpp:25-66`).

### 3.8 Frame contrast and global contrast
- KCS3.44 `contrastF(config)`: returns 0.7 if no config (`src/kcolorscheme.cpp:519-523`); otherwise `0.1 * [KDE] contrast` with default 7 (`:524-526`). The result is not clamped here; `shade()` clamps (KCS3.24). The test expects `contrast=5` to give 0.5 (`autotests/kcolorschemetest.cpp:98`, `autotests/kcolorschemetest.colors:213`).
- KCS3.45 `frameContrast(config)`: default 0.2 (`src/kcolorscheme.cpp:532`); if no config, returns the default (`:533-535`); else `std::clamp([KDE] frameContrast, 0.0, 1.0)` (`:537-538`). The header doc says it overrides the contrast "of frames in using styles (Breeze)" (`src/kcolorscheme.h:409-410`). The comment in the function says "Keep this in sync with Kirigami platformtheme.cpp" (`:531`). No consumer exists in this tree (see KCS6.7).

### 3.9 Palette adjustment helpers
- KCS3.46 `adjustBackground(palette, newRole, color, set, config)` and `adjustForeground(...)` set the given QPalette role for Active, Inactive and Disabled from `KColorScheme(state, set, config).background(newRole)` / `.foreground(newRole)` (`src/kcolorscheme.cpp:618-630`).
- KCS3.47 `isColorSetSupported(config, set)` returns `hasGroup("Colors:<Set>")` for each set; NColorSets returns false (`src/kcolorscheme.cpp:632-654`). Header and Tooltip use the same pattern. Used to detect whether a scheme defines a set.
- KCS3.48 `createApplicationPalette(config)` (`src/kcolorscheme.cpp:656-695`). Tooltip is always built with `QPalette::Active` for all states (`:661`, comment `:659-660`: "TT thinks tooltips shouldn't use active"). For each of Active, Inactive, Disabled (`:664`), View, Window, Button and Selection schemes are built with that state. Mapping:
  - WindowText <- Window.foreground(NormalText); Window <- Window.background(NormalBackground) (`:670-671`)
  - Base <- View.background(NormalBackground); Text <- View.foreground(NormalText)
  - Button <- Button.background(NormalBackground); ButtonText <- Button.foreground(NormalText)
  - Highlight <- Selection.background(NormalBackground); HighlightedText <- Selection.foreground(NormalText)
  - ToolTipBase <- Tooltip.background(NormalBackground); ToolTipText <- Tooltip.foreground(NormalText)
  - PlaceholderText <- View.foreground(InactiveText) (`:680`); Accent <- Selection.background(NormalBackground) (`:681`)
  - Light, Midlight, Mid, Dark, Shadow <- Window.shade(LightShade ... ShadowShade) as QColor (`:683-687`)
  - AlternateBase <- View.background(AlternateBackground) (`:689`); Link <- View.foreground(LinkText); LinkVisited <- View.foreground(VisitedText) (`:690-691`)
  (Lines 670-691 cover the whole mapping; the exact line for each entry was not individually checked beyond the ones cited.)

### 3.10 KStatefulBrush
- KCS3.49 KStatefulBrush holds one QBrush per QPalette::ColorGroup (`std::array<QBrush, QPalette::NColorGroups>`, `src/kstatefulbrush.cpp:14-16`, `:19`). Constructors from (set, ForegroundRole), (set, BackgroundRole), (set, DecorationRole) fill Active, Disabled and Inactive from `KColorScheme(state, set, config).<role>` (`src/kstatefulbrush.cpp:26-49`). The default constructor leaves brushes unset (`:19-22`).
- KCS3.50 Constructors from a plain QBrush (`src/kstatefulbrush.cpp:51-71`): Active = brush; Disabled and Inactive = `StateEffects(state, config).brush(brush)` or `.brush(brush, background)` (with the background form adding the contrast effect of KCS3.20). `config` defaults to `defaultConfig()`.
- KCS3.51 `brush(ColorGroup)` returns the stored brush for valid groups and Active otherwise (`src/kstatefulbrush.cpp:89-96`). `brush(const QPalette&)` uses `pal.currentColorGroup()` (`:98-100`).
- KCS3.52 Usage in the Darkly tree (cross-reference only, cited from `features/studies/theming/Darkly.md` DK3.3 and not re-read here): `KStatefulBrush` for view focus, hover, negative text and window alternate background.

### 3.11 KColorScheme object
- KCS3.53 `KColorScheme(ColorGroup state = Normal, ColorSet set = View, KSharedConfigPtr config = {})` (`src/kcolorscheme.h:277`); the private data is built from `config ? config : defaultConfig()` (`src/kcolorscheme.cpp:508-511`). The object is explicitly shared through `QExplicitlySharedDataPointer<KColorSchemePrivate> d` (`src/kcolorscheme.h:428`).
- KCS3.54 Equality: same `_contrast` and same brush arrays (`src/kcolorscheme.cpp:513-516`).
- KCS3.55 `background(role)`, `foreground(role)`, `decoration(role)` delegate to the private data (`src/kcolorscheme.cpp:541-554`).

## 4. Architecture (classes, extension points, entry points)
- KCS4.1 `KColorSchemePrivate : QSharedData` (`src/kcolorscheme.cpp:221-249`) stores `Brushes` (three arrays: fg[NForegroundRoles], bg[NBackgroundRoles], deco[NDecorationRoles]) and `_contrast`. Constructor chooses `initFromConfig` when config is non-null, else `initFromSystemPalette` (`:280-287`).
- KCS4.2 Entry points for a caller: `KColorScheme(state, set, config)` (`src/kcolorscheme.cpp:508`), `KColorScheme::createApplicationPalette(config)` (`:656`), `KColorScheme::shade` (`:556`, `:561`, `:566`), `KColorScheme::frameContrast` (`:529`), `KColorScheme::contrastF` (`:519`), `KStatefulBrush` constructors (`src/kstatefulbrush.cpp:26-71`).
- KCS4.3 Manager: `KColorSchemeManager` is a QObject singleton via `instance()` (`src/kcolorschememanager.cpp:332-340`) with two constructors (`:135-148`). `init()` (`:155-207`) wires change signals and applies the saved scheme (KCS2.11). Public API: `model()` (`:209-212`), `indexForSchemeId` (`:234`), `indexForScheme` (`:239`), `activateScheme` (`:254`), `activateSchemeId` (`:273`), `saveSchemeIdToConfigFile` (`:305`), `activeSchemeId` (`:318`), `activeSchemeName` (`:322`).
- KCS4.4 `KColorSchemeManagerPrivate` (`src/kcolorschememanager_p.h:15-47`) holds `model`, `m_activatedScheme`, `m_autosaveChanges`, the light and dark defaults, and the static `contrastPreference()` (`src/kcolorschememanager.cpp:327-330`, enum at `src/kcolorschememanager_p.h:30-33`: NoPreference, HighContrast).
- KCS4.5 Model: `KColorSchemeModel` (`src/kcolorschememodel.h:29`) with roles NameRole, PathRole, IdRole (`src/kcolorschememodel.h:34-37`). Rebuilds on `reset` by scanning directories (`src/kcolorschememodel.cpp:36-74`, KCS2.2-2.4).
- KCS4.6 Extension points: (a) new schemes as `.colors` files in any `GenericDataLocation/color-schemes` directory (KCS2.2); (b) bundled schemes via the application's Qt resource at `:/org.kde.kcolorscheme/color-schemes` (KCS1.9, KCS2.2); (c) the `KDE_COLOR_SCHEME_PATH` property (KCS2.9) lets an application or platform theme set the scheme file; (d) `QStyleHints` and accessibility signals drive automatic switching (KCS2.14).
- KCS4.7 Shared state: `defaultConfig()` uses a `static thread_local` cache (`src/kcolorschemehelpers_p.h:23`). `KSharedConfig` instances are shared by name.
- KCS4.8 Qt metatype: `KColorScheme` is declared as a metatype (`src/kcolorscheme.h:431`); `KStatefulBrush` similarly (`src/kstatefulbrush.h:125`).

## 5. Build, dependencies, tests
- KCS5.1 Runtime deps: Qt6::Gui (+ Qt6GuiPrivate on Qt >= 6.10), KF6::ConfigCore, KF6::ConfigGui, KF6::GuiAddons (for KColorUtils; the colour maths in section 3.7 lives there), KF6::I18n (`src/CMakeLists.txt:49-57`).
- KCS5.2 Build-time: ECM (`CMakeLists.txt:11`), Qt6 Gui (`:32`), KF6 Config, GuiAddons, I18n (`:46-48`). Qt resource compiler for bundled schemes (`src/CMakeLists.txt:20`).
- KCS5.3 Tests: built only when `BUILD_TESTING` is on (`CMakeLists.txt:59-61`). `autotests/CMakeLists.txt:4` finds Qt6 Test; `:10` adds `kcolorschemetest` linked to `Qt6::Test` and `KF6::ColorScheme`.
- KCS5.4 Test functions in `autotests/kcolorschemetest.cpp`: `benchConstruction()` (`:35`), `readColors()` (`:57`), `readContrast()` (`:95`). `QTEST_MAIN(KColorSchemeTest)` (`:102`). `readContrast` checks `contrastF` = 0.5 for `autotests/kcolorschemetest.colors` (`:98`, file `:213`: `contrast=5`). `readColors` compares `KColorScheme` brush colours against a `QColor(colorSet, role, group)` helper (macros at `:65-89`; helper not read, KCS6.8).
- KCS5.5 The test scheme file `autotests/kcolorschemetest.colors` has all seven sets plus `[Inactive]` subgroups for each (`:152-194` for View, Window), `[ColorEffects:Inactive]` (`:208`) and `[KDE] contrast=5` (`:212-213`).
- KCS5.6 Not built or run in this study (read-only rule).

## 6. Gaps and unverified items
- KCS6.1 Doc/enum mismatch: class comment says "five distinct sets" (`src/kcolorscheme.h:30`); the enum has seven plus NColorSets (`:92-100`).
- KCS6.2 `KColorUtils::luma` and `shade` mapping to KHCY are read; the Qt-side `QColor::fromRgbF` clamping was not traced in refs/qtbase.
- KCS6.3 `KSharedConfig::openConfig("")` returning the default config (KCS2.10) follows the code comment; refs/kconfig not read.
- KCS6.4 `KCOLORSCHEME_VERSION` and `KCOLORSCHEME_SOVERSION` (used at `src/CMakeLists.txt:8-9`) are not defined in the files read.
- KCS6.5 Qt's `QStandardPaths::locateAll` ordering (KCS2.3) is taken from the code comment ("$HOME overrides"), not from Qt source.
- KCS6.6 `normalize` NaN behaviour: comment says NaN -> 0.0 (`refs/kguiaddons/src/colors/kguiaddons_colorhelpers_p.h:11-12`), code returns 1.0 (`:13-16`). A reimplementation must pick one; the code's behaviour is the one that runs.
- KCS6.7 `frameContrast` has no consumer in refs/kcolorscheme (KCS3.45). The Kirigami sync comment (`src/kcolorscheme.cpp:531`) points to code outside this tree.
- KCS6.8 The test helper `QColor(colorSet, role, group)` used by `readColors` (`autotests/kcolorschemetest.cpp:65-89`) was not read.
- KCS6.9 Not traced: how `KStatefulBrush` consumers in the Darkly tree use `Inactive` and `Disabled` (only the construction side is in KCS3.49).
- KCS6.10 `ExtraDesktop.sh` is a helper script for listing `.colors` files; its use by packagers was not traced.
- KCS6.11 The model's `QIcon` for the Default entry (`src/kcolorschememodel.cpp:73`) comes from the theme (`edit-undo`); whether this affects non-KDE platforms was not traced.
- KCS6.12 No build, run or test of any kind was done (read-only study).

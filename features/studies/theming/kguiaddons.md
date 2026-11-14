# KGuiAddons: Qt GUI helper library (colour maths, colour collections, fonts, text, util)

Source: refs/kguiaddons (shallow clone; commit e183b86, 2026-11-07; branch main; KF version 6.33.0 per `CMakeLists.txt:3`). License: file headers carry `LGPL-2.0-or-later` (`src/colors/kcolorutils.cpp:6`, `src/colors/kcolorspaces.cpp:5`) and `LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL` (`src/colors/kcolorcollection.cpp:4`); the `LICENSES/` directory holds the texts. Top-level license declaration: UNVERIFIED (`README.md` and `README.md.license` contain no SPDX line that was found). Scope: src/colors/ (read in full except kcolorschemewatcher_*.cpp, kwindowinsetscontroller.*, kcolormimedata.*), src/fonts/kfontutils.h, src/text/, src/util/ (headers only), src/qml/kcolorutilssingleton.h, autotests/kcolorutilstest.cpp (function list only). Not studied: src/systemclipboard/, src/recorder/, src/android/, src/geo-scheme-handler/, python/, most of src/util/ bodies.
Id prefix: KGA.

## 1. Purpose and shape
- KGA1.1 KGuiAddons is an add-on library to QtGui for KDE Frameworks. Metadata: `description: Addons to QtGui`, `tier: 1`, `type: functional` (`metainfo.yaml:1-5`).
- KGA1.2 Build system: CMake, `cmake_minimum_required(VERSION 3.30)` (`CMakeLists.txt:1`); ECM `6.32.0` (`CMakeLists.txt:7`); project version `KF_VERSION "6.33.0"` (`CMakeLists.txt:3`).
- KGA1.3 Minimum Qt: `set(REQUIRED_QT_VERSION 6.10.0)` (`CMakeLists.txt:42`). Qt6Gui is required (`CMakeLists.txt:44`). No Qt5 `find_package` was seen in the Qt6 block at `CMakeLists.txt:42-100` (a repository-wide Qt5 check was not run).
- KGA1.4 Library target: `KF6GuiAddons`, alias `KF6::GuiAddons` (`src/CMakeLists.txt:4`). Colour sources are listed in `src/colors/CMakeLists.txt:13-20`; colour headers in `src/colors/CMakeLists.txt:37-40`. Colour classes are installed as `KColorUtils`, `KColorCollection`, `KColorMimeData`, `KColorSchemeWatcher` (`src/CMakeLists.txt:163-166`).
- KGA1.5 Optional platform backends: Wayland (`CMakeLists.txt:32`, option `WITH_WAYLAND`, default ON), X11 (`CMakeLists.txt:35`, `WITH_X11`), DBus (`CMakeLists.txt:76`, `USE_DBUS`), Android (`CMakeLists.txt:88`, needs Gradle), Python bindings (`CMakeLists.txt:90`, `BUILD_PYTHON_BINDINGS`, needs Shiboken6 and PySide6 at lines 98-100), geo: URI handler (`CMakeLists.txt:29`, `BUILD_GEO_SCHEME_HANDLER`).
- KGA1.6 Public API version markers: `KColorUtils::hue/chroma` are marked `\since 5.68`, `getHcy` `\since 5.0`, `hcyColor` `\since 5.68` (`src/colors/kcolorutils.h:31-44`, `:71`, `:84`).

## 2. Theme input (configuration, environment, how settings reach it)
- KGA2.1 `KColorUtils` (all functions in `kcolorutils.h`) takes no configuration file, no environment variable and no global setting. All inputs are the function arguments (`src/colors/kcolorutils.h:26-206`). An environment-variable search in `src/colors/` returned only `kcolorschemewatcher_xdg.h` include-guard text (no `getenv` call).
- KGA2.2 `KColorUtils` defaults are the only tunables: `lighten(amount=0.5, chromaInverseGain=1.0)` (`kcolorutils.h:121`), `darken(amount=0.5, chromaGain=1.0)` (`:140`), `shade(lumaAmount, chromaAmount=0.0)` (`:156`), `tint(amount=0.3)` (`:172`), `mix(bias=0.5)` (`:189`), `hcyColor(alpha=1.0)` (`:86`), `overlayColors(comp=CompositionMode_SourceOver)` (`:206`).
- KGA2.3 The QML wrapper `KColorUtilsSingleton` exposes the same functions as `Q_INVOKABLE` with the same default values: `hue`, `chroma`, `luma`, `hcyColor(alpha=1.0)`, `contrastRatio`, `lighten(0.5, 1.0)`, `darken(0.5, 1.0)`, `shade(lumaAmount, 0.0)`, `tint(0.3)`, `mix(0.5)` (`src/qml/kcolorutilssingleton.h:16-25`).
- KGA2.4 `KColorCollection` reads palette files from the generic config location: `QStandardPaths::locate(GenericConfigLocation, "colors/" + name)` (`src/colors/kcolorcollection.cpp:51`). `installedCollections()` lists files in every `colors` directory of that location (`kcolorcollection.cpp:102-113`).
- KGA2.5 `KColorCollection::save()` writes to `writableLocation(GenericConfigLocation) + "/colors/" + name` (`kcolorcollection.cpp:127`), through `QSaveFile` (`:128`, `:148`).

## 3. Color and style model
Notation: all values are in `qreal`. `normalize(a)` is defined in `src/colors/kguiaddons_colorhelpers_p.h:13-16` as `a < 1.0 ? (a > 0.0 ? a : 0.0) : 1.0`, i.e. clamp to [0, 1]. `mixQreal(a, b, t) = a + (b - a) * t` (`src/colors/kcolorutils.cpp:19-22`). `KHCY` is the internal colour record (h, c, y, a) from `src/colors/kcolorspaces_p.h:20-35`.

### 3a. Linearisation and luma (HCY, Rec. 709)
- KGA3.1 Gamma constant: `gamma(n) = pow(normalize(n), 2.2)`; the inverse is `igamma(n) = pow(normalize(n), 1.0/2.2)` (`src/colors/kcolorspaces.cpp:34-42`). Exponent is the plain 2.2 power, not the piecewise sRGB transfer curve.
- KGA3.2 Luma weights: `#define HCY_REC 709`, selecting `yc = {0.2126, 0.7152, 0.0722}` (`kcolorspaces.cpp:25-29`). Alternatives in the same block: Rec. 601 `{0.299, 0.587, 0.114}` (`:27`), Qt `{0.34375, 0.5, 0.15625}` (`:31`), selected only when `HCY_REC` is set to 601 or to another value.
- KGA3.3 Luma: `y = r*0.2126 + g*0.7152 + b*0.0722` where `r,g,b = gamma(redF), gamma(greenF), gamma(blueF)` (`kcolorspaces.cpp:44-47`, `:59-65`). `KColorUtils::luma(c)` returns `KHCY::luma(c)` = `lumag(gamma(r), gamma(g), gamma(b))` (`kcolorspaces.cpp:160-163`); range 0 (black) to 1 (white) (`kcolorutils.h:49-51`).
- KGA3.4 Alpha is taken directly as `a = color.alphaF()` (`kcolorspaces.cpp:62`).

### 3b. Hue, chroma (forward conversion QColor -> KHCY)
- KGA3.5 With `p = max(r,g,b)` and `n = min(r,g,b)`, the hue numerator is `d = 6.0 * (p - n)` (`kcolorspaces.cpp:68-70`).
- KGA3.6 Hue cases (`kcolorspaces.cpp:71-79`): if `n == p` then `h = 0.0`; else if `r == p` then `h = (g - b) / d`; else if `g == p` then `h = (b - r) / d + 1/3`; else (blue is max) `h = (r - g) / d + 2/3`. The raw `h` is not wrapped in the constructor (`:57-79`).
- KGA3.7 Chroma (`kcolorspaces.cpp:81-86`): if `r == g && g == b` then `c = 0.0`; else `c = max((y - n) / y, (p - y) / (1 - y))`. Here `n` and `p` are gamma-linear min and max, `y` is the linear luma of KGA3.3.
- KGA3.8 `KColorUtils::hue(c)` returns `wrap(KHCY(c).h)` (`kcolorspaces.cpp:150-153`, `kcolorutils.cpp:25-28`). `wrap(a, d=1.0)`: `r = fmod(a, d)`; `r < 0 ? d + r : (r > 0 ? r : 0)` (`kcolorspaces.cpp:16-20`). Result range [0, 1).
- KGA3.9 `KColorUtils::chroma(c)` returns `KHCY(c).c` unwrapped (`kcolorspaces.cpp:155-158`). Range 0 (none) to 1 (full) per `kcolorutils.h:39-40`.
- KGA3.10 `KColorUtils::getHcy(c, h, c, y, a)` returns `h = KHCY.h + (KHCY.h < 0.0 ? 1.0 : 0.0)` (`kcolorutils.cpp:40-52`). It does not call `wrap`. It returns nothing if any of `h`, `c`, `y` is null (`:42-44`). Alpha is written only when the pointer is non-null (`:49-51`).

### 3c. Reverse conversion KHCY -> QColor (`KHCY::qColor`, `kcolorspaces.cpp:89-148`)
- KGA3.11 Input sanitising: `_h = wrap(h)`, `_c = normalize(c)`, `_y = normalize(y)` (`kcolorspaces.cpp:92-94`). `_hs = _h * 6.0` (`:97`).
- KGA3.12 Sector table (`kcolorspaces.cpp:100-118`), with `yc0 = 0.2126`, `yc1 = 0.7152`, `yc2 = 0.0722`:
  - `_hs < 1`: `th = _hs`, `tm = yc0 + yc1 * th`;
  - `_hs < 2`: `th = 2 - _hs`, `tm = yc1 + yc0 * th`;
  - `_hs < 3`: `th = _hs - 2`, `tm = yc1 + yc2 * th`;
  - `_hs < 4`: `th = 4 - _hs`, `tm = yc2 + yc1 * th`;
  - `_hs < 5`: `th = _hs - 4`, `tm = yc2 + yc0 * th`;
  - else: `th = 6 - _hs`, `tm = yc0 + yc2 * th`.
- KGA3.13 Sorted channel values (`kcolorspaces.cpp:124-132`):
  - if `tm >= _y`: `tp = _y + _y*_c*(1 - tm)/tm`; `to = _y + _y*_c*(th - tm)/tm`; `tn = _y - _y*_c`;
  - else: `tp = _y + (1 - _y)*_c`; `to = _y + (1 - _y)*_c*(th - tm)/(1 - tm)`; `tn = _y - (1 - _y)*_c*tm/(1 - tm)`.
- KGA3.14 Channel order per sector (`kcolorspaces.cpp:135-147`), output via `QColor::fromRgbF(igamma(...), igamma(...), igamma(...), a)`:
  - `_hs < 1`: (tp, to, tn); `_hs < 2`: (to, tp, tn); `_hs < 3`: (tn, tp, to); `_hs < 4`: (tn, to, tp); `_hs < 5`: (to, tn, tp); else (tp, tn, to).
- KGA3.15 `KColorUtils::hcyColor(h, c, y, a)` returns `KHCY(h, c, y, a).qColor()` (`kcolorutils.cpp:54-57`). Hue is cyclical (wrapped); chroma and luma are clamped (`kcolorutils.h:76-80`). Note: `qColor()` applies `igamma` (1/2.2 power) to the linear channels, so the output is sRGB.

### 3d. Contrast ratio
- KGA3.16 `contrastRatioForLuma(y1, y2) = (max + 0.05) / (min + 0.05)` (`kcolorutils.cpp:59-66`). WCAG-style offset 0.05 (`kcolorutils.h:88-96`).
- KGA3.17 `KColorUtils::contrastRatio(c1, c2) = contrastRatioForLuma(luma(c1), luma(c2))` (`kcolorutils.cpp:68-71`). Range 1 to 21 (`kcolorutils.h:94-96`). Test asserts black/white = 21.0 and identical colours = 1.0 (`autotests/kcolorutilstest.cpp:112-115`, function `testContrast` at `:110`). Luma here uses the power-2.2 gamma of KGA3.1, which is not the WCAG sRGB transfer curve.

### 3e. Lighten, darken, shade (luma and chroma in HCY space)
- KGA3.18 `lighten(c, ky, kc)` (`kcolorutils.cpp:73-79`): `y' = 1 - normalize((1 - y) * (1 - ky))`; `c' = 1 - normalize((1 - c) * kc)`. Then `qColor()`. The hue is unchanged. `ky = 1` gives luma 1 (white). `kc = 0` gives chroma 1 (maximum). `kc = 1` leaves chroma unchanged.
- KGA3.19 `darken(c, ky, kc)` (`kcolorutils.cpp:81-87`): `y' = normalize(y * (1 - ky))`; `c' = normalize(c * kc)`. `ky = 1` gives luma 0 (black). `kc = 0` gives chroma 0.
- KGA3.20 `shade(c, ky, kc)` (`kcolorutils.cpp:89-95`): `y' = normalize(y + ky)`; `c' = normalize(c + kc)`. Additive, unlike KGA3.18/KGA3.19. Header: `-1.0` makes anything black, `1.0` makes anything white (`kcolorutils.h:145-152`).
- KGA3.21 Header-documented luma-doubling identities (not tested in the file): `lighten(amount=-1)` gives `luma = 1 - 2*(1 - luma)` (`kcolorutils.h:110-111`); `darken(amount=-1)` gives `luma = 2*luma` (`:131-132`). The code (`KGA3.18`, `KGA3.19`) satisfies these: `ky = -1` yields `1 - (1 - y)*2` and `y*2`.
- KGA3.22 Test coverage: `testShading` at `autotests/kcolorutilstest.cpp:129`; `testHCY` at `:94`; `testMix` at `:55`; `testOverlay` at `:9`.

### 3f. Tint (contrast-targeted blend)
- KGA3.23 Early exits (`kcolorutils.cpp:113-123`): `amount <= 0` returns `base`; `amount >= 1` returns `color`; NaN returns `base`.
- KGA3.24 Target contrast: `baseLuma = luma(base)`; `ri = contrastRatioForLuma(baseLuma, luma(color))` (`:125-126`); `rg = 1.0 + (ri + 1.0) * amount^3` (`:127`).
- KGA3.25 Search: bisection on `a` over `[l, u] = [0, 1]`, initial `a = 0.5` (`:128-130`). 12 iterations (`:131`): `a = 0.5*(l + u)`; `resultLuma = tintHelperLuma(base, baseLuma, color, a)`; `ra = contrastRatioForLuma(baseLuma, resultLuma)`; if `ra > rg` set `u = a`, else set `l = a` (`:132-139`).
- KGA3.26 Helper `tintHelperLuma(base, baseLuma, color, t) = mixQreal(baseLuma, luma(mix(base, color, t^0.3)), t)` (`kcolorutils.cpp:105-111`). The exponent `pow(amount, 0.3)` is the constant 0.3 (`:107`).
- KGA3.27 Helper `tintHelper(base, baseLuma, color, t)`: `result = KHCY(mix(base, color, t^0.3))`; then `result.y = mixQreal(baseLuma, result.y, t)` (`kcolorutils.cpp:97-103`). The result is returned as `tintHelper(base, baseLuma, color, a).qColor()` after the search (`:141`).
- KGA3.28 Default `amount = 0.3` (`kcolorutils.h:172`). The comment states that low `amount` keeps the luma of `base` and inherits hue and chroma of `color` (`:158-163`).

### 3g. Mix (linear blend, premultiplied alpha, sRGB space)
- KGA3.29 `mix(c1, c2, bias)` (`kcolorutils.cpp:144-166`): `bias <= 0` returns `c1`; `bias >= 1` returns `c2`; NaN returns `c1` (`:146-154`). Default `bias = 0.5` (`kcolorutils.h:189`).
- KGA3.30 Alpha: `a = mixQreal(c1.alphaF(), c2.alphaF(), bias)`; if `a <= 0` return `Qt::transparent` (`kcolorutils.cpp:156-159`).
- KGA3.31 Channels: `ch = qBound(0, mixQreal(c1.ch * c1.alpha, c2.ch * c2.alpha, bias), 1) / a` for `ch` in R, G, B (`kcolorutils.cpp:161-163`), output by `QColor::fromRgbF(r, g, b, a)` (`:165`). The blend is linear on the gamma-encoded (sRGB) channel values, weighted by alpha (premultiplied). No gamma conversion is applied.
- KGA3.32 Test: `testMix` asserts that a 0.01-opacity colour has little influence on the result (`autotests/kcolorutilstest.cpp:89-91`).

### 3h. Overlay (Qt composition modes)
- KGA3.33 `overlayColors(base, paint, comp)` (`kcolorutils.cpp:168-181`): creates a 1x1 `Format_ARGB32_Premultiplied` `QImage`; fills it with `base` forced to alpha 255 (`:172-176`); sets `comp` (`:177`); fills with `paint` (`:178`); returns the pixel (`:180`). Default `comp = QPainter::CompositionMode_SourceOver` (`kcolorutils.h:206`). The `base` alpha is ignored (`kcolorutils.h:200`).
- KGA3.34 Test: `testOverlay` at `autotests/kcolorutilstest.cpp:9`; checks that the result equals `color2` when `color2` is opaque (`:14`, `:34-43`).

### 3i. Other colour inputs
- KGA3.35 `KColorUtils::getHcy` and `hcyColor` are the public HCY access points (KGA3.10, KGA3.15).
- KGA3.36 Colour collections (`KColorCollection`, deprecated, see KGA4.6): palette entries are `QColor` plus name `QString` (`kcolorcollection.cpp:28-36`).
- KGA3.37 Colour-scheme watching and MIME colour transfer exist in `src/colors/kcolorschemewatcher*.cpp` and `kcolormimedata.*`; not read in this study (see KGA6.5).

## 4. Architecture (classes, extension points, entry points)
- KGA4.1 `KColorUtils` is a namespace of free functions (`src/colors/kcolorutils.h:26`). Each is `KGUIADDONS_EXPORT`, so it is part of the shared library ABI.
- KGA4.2 `KColorSpaces::KHCY` is a private value class (`src/colors/kcolorspaces_p.h:18-35`). Its public-looking members `h, c, y, a` are plain `qreal` fields. Constructors: from `QColor` (`:23`) and from `(h, c, y, a=1.0)` (`:24`). Static helpers: `hue`, `chroma`, `luma` (`:27-29`). Private static helpers: `gamma`, `igamma`, `lumag` (`:32-34`). The header is under `_p.h`, so it is not an installed API.
- KGA4.3 Entry points in order of use by the other functions: `KHCY(QColor)` (KGA3.5-3.7) feeds `hue`, `chroma`, `getHcy`, `lighten`, `darken`, `shade`, `tint` (via `tintHelper`); `KHCY::qColor()` (KGA3.11-3.14) feeds `hcyColor`, `lighten`, `darken`, `shade`, `tint`.
- KGA4.4 Helper `normalize` is a `static inline` in a private header (`kguiaddons_colorhelpers_p.h:13`). Its comment (`:11-12`) says NaN returns 0.0, but the code (`:15`) returns 1.0 for NaN, because `NaN < 1.0` is false. Observed in source; not executed.
- KGA4.5 `tint` calls `luma()` once per call for `base` ("cache value because luma call is expensive", `kcolorutils.cpp:125`) and calls `luma(mix(...))` 12 times in the bisection loop (KGA3.25, KGA3.26).
- KGA4.6 `KColorCollection` (`src/colors/kcolorcollection.h:35`) is `KGUIADDONS_DEPRECATED_VERSION(6, 3, "unused")`. Its doc says "Unused and backing data no longer available" (`kcolorcollection.h:30-34`). The implementation is compiled only when `KGUIADDONS_BUILD_DEPRECATED_SINCE(6, 3)` is true (`kcolorcollection.cpp:11`, end `:245`).
- KGA4.7 `KColorCollection` storage: `QSharedDataPointer<KColorCollectionPrivate> d` (`kcolorcollection.h:224`); private data holds `QList<ColorNode>`, `name`, `desc`, `editable` (`kcolorcollection.cpp:20-42`).
- KGA4.8 `KColorCollection` file format on load: first line must not contain `" Palette"`, else the load returns early (`kcolorcollection.cpp:64-69`). Comment lines start with `#` and are appended to the description (`:73-79`). Colour lines are parsed with `sscanf("%d %d %d%n")` (`:90`); components are clamped to 0..255 with `qBound` (`:91-93`); the rest of the line after the three numbers, trimmed, is the entry name (`:94-95`).
- KGA4.9 `KColorCollection::save()` writes the header `KDE RGB Palette` (`kcolorcollection.cpp:138`), the description with each line prefixed by `#` (`:135-139`), then one `r g b name` line per entry (`:140-146`), committed atomically through `QSaveFile::commit` (`:148`).
- KGA4.10 Observed conflict: the loader rejects a file whose first line contains `" Palette"` (`kcolorcollection.cpp:67-68`), while the comment at `:65` says the expected header is `GIMP Palette`, and `save()` writes `KDE RGB Palette` (`:138`). As written, a file produced by `save()` fails the load check. Not executed.
- KGA4.11 `KColorCollection::editable` is an enum `Editable { Yes, No, Ask }` (`kcolorcollection.h:113-117`). The private constructor does not initialise `editable` (`kcolorcollection.cpp:44-49`), so `editable()` returns an unset value until `setEditable` is called (`:171-179`).
- KGA4.12 Index semantics: `color(i)`, `name(i)` return a default `QColor` or `QString` for an out-of-range index (`kcolorcollection.cpp:188-195`, `:207-214`). `findColor` returns the first index with `==` colour equality, or -1 (`:197-205`). `addColor` appends and returns the new index (`:221-225`). `changeColor(index, ...)` returns -1 for an invalid index (`:227-238`). `changeColor(oldColor, ...)` looks up the index first (`:240-243`).
- KGA4.13 QML wrapper `KColorUtilsSingleton` (`src/qml/kcolorutilssingleton.h:16-25`) forwards to the same `KColorUtils` functions. The file header of that class is not read.
- KGA4.14 Public header for colour maths: `kcolorutils.h`, with `KGUIADDONS_EXPORT` on each function (for example `kcolorutils.h:36`, `:189`, `:206`).

## 5. Build, dependencies, tests
- KGA5.1 Colour code depends on Qt6 Gui only (`QColor`, `QImage`, `QPainter`) and on `QtNumeric` (`kcolorutils.cpp:12-14`, `kcolorspaces.cpp:10`). The Qt6Gui package is `REQUIRED` (`CMakeLists.txt:44`).
- KGA5.2 Colour headers listed in `src/colors/CMakeLists.txt:37-40`: `kcolorspaces_p.h` (`:37`, private, `_p` suffix), `kcolorutils.h` (`:38`), `kcolorcollection.h` (`:39`), `kcolormimedata.h` (`:40`). `kguiaddons_colorhelpers_p.h` is a private header that is not in that list (`kcolorutils.cpp:9`, `kcolorspaces.cpp:8` include it).
- KGA5.3 Tests: `ecm_add_tests` with `kcolorutilstest.cpp` (`autotests/CMakeLists.txt:7-9`). Test functions: `testOverlay` (`autotests/kcolorutilstest.cpp:9`), `testMix` (`:55`), `testHCY` (`:94`), `testContrast` (`:110`), `testShading` (`:129`). The test for `hcy.c == 0` on grey colours is at `:120-126`.
- KGA5.4 Test run, build and output were not performed (read-only study).

## 6. Gaps and unverified items
- KGA6.1 The HCY forward and inverse formulas (KGA3.5-3.14) are transcribed from source and not checked by round-trip. Constants were copied from `kcolorspaces.cpp:25-32`.
- KGA6.2 `KColorUtils::overlayColors` composition modes other than the default `SourceOver` were not analysed beyond the call at `kcolorutils.cpp:177`.
- KGA6.3 The `KColorCollection` header-check inversion (KGA4.10) and the `editable` initialisation gap (KGA4.11) were read from source and not reproduced.
- KGA6.4 The top-level licence declaration is UNVERIFIED (see the Source line).
- KGA6.5 Not read: `src/colors/kcolorschemewatcher*.cpp`, `kwindowinsetscontroller.*`, `kcolormimedata.*`, `src/qml/kcolorutilssingleton.cpp` bodies, `python/` bindings, `src/util/` bodies, `src/systemclipboard/`, `src/recorder/`, `src/android/`, `src/geo-scheme-handler/`. Other subsystems below are listed from headers only.
- KGA6.6 The `wrap` path for hue values in `KHCY::hue` (`kcolorspaces.cpp:150-153`) and in `getHcy` (`kcolorutils.cpp:47`) differ: `hue()` wraps with `fmod`, `getHcy()` adds 1 to negatives only. Both were derived from source; the ranges are reasoned, not measured.
- KGA6.7 Test assertions for `lighten`, `darken`, `shade`, `tint` numeric values were not read (only the function names at `kcolorutilstest.cpp:129` and the file-level list).

## 7. Other subsystems (one line each, from headers)
- KGA7.1 Fonts: `namespace KFontUtils` with `adaptFontSize(painter, text, width, height, maxFontSize=28.0, minFontSize=1.0)` overloads (`src/fonts/kfontutils.h:23`, `:65-70`, `:76`), the size search itself not read.
- KGA7.2 Text: `KWordWrap` class for word wrapping (`src/text/kwordwrap.h:42`).
- KGA7.3 Text: `KDateValidator`, a `QValidator` subclass for date input (`src/text/kdatevalidator.h:26`).
- KGA7.4 Util: `KSystemInhibitor` (`src/util/ksysteminhibitor.h:19`), a `QObject` for system sleep/idle inhibition, with DBus, Windows, Android and dummy backends (`src/util/ksysteminhibitor_*.cpp`).
- KGA7.5 Util: `KModifierKeyInfo` (`src/util/kmodifierkeyinfo.h:38`) with an XCB and a Wayland provider (`src/util/kmodifierkeyinfoprovider_xcb.h`, `..._wayland.h`).
- KGA7.6 Util: `KCursorSaver` (`src/util/kcursorsaver.h:29`), a helper that stores and restores the cursor shape.
- KGA7.7 Util: `KLocalImageCacheImplementation` (`src/util/klocalimagecacheimpl.h:27`) and `kimagecache.h` for image caching; `KIconUtils` in `src/util/kiconutils.h`.
- KGA7.8 Util: `KCountryFlagEmojiIconEngine` (`src/util/kcountryflagemojiiconengine.h:27`), a `QIconEngine` that renders country flags as emoji.
- KGA7.9 Util, private: `KUrlHandler` (`src/util/kurlhandler_p.h:16`), a `QObject` that handles URL opening.
- KGA7.10 Other directories (headers not read): `src/systemclipboard/` (`KSystemClipboard`, `src/systemclipboard/ksystemclipboard.h`), `src/recorder/` (`KKeySequenceRecorder`, `src/recorder/kkeysequencerecorder.h`), `src/qml/` (`SystemInhibitor` and the colour singleton), `src/geo-scheme-handler/` (a `geo:` URI handler binary, `src/geo-scheme-handler/main.cpp`), `src/android/` (Java classes under `org/kde/guiaddons/`).

# Theming engines (one per toolkit version)

* **Author:** djeddi-yacine
* **Date:** 2026-11-13
* **Status:** brainstorm brief, draft 2 (expanded with requirements, per-engine sheets and a re-study map). The Goldfish review was skipped by the owner to save tokens. Open decisions are at the end. Next step: `/egm-draft` per engine, starting with the engine the owner picks.

Input: the 51 studies in `features/studies/theming/` and the Arch wiki pages in `refs/archwiki/`. Study ids such as `BR3.5` mean `breeze.md`, section 3, entry 5; a bare prefix is listed in the first lines of each study (`Id prefix:`). This file records what we chose from them and what each design must be able to do. It does not copy the studies; designs cite them.

Prefix collisions: `LA` is both libadwaita and lxappearance, `KL` is both Klassy and KvLibadwaita, `QC` is both QtCurve and qtquickcontrols2. Where a bare id could mean either, this file names the study file.

The owner will re-study Darkly and Breeze (and other drawing styles) at design time and take ideas and code logic from them. This brief therefore lists, per engine, what to re-study and what question the re-study must answer, so the engines do not end up with a smaller surface than the toolkit allows.

## Overview

GTK and Qt apps should follow the shell's palette, which is extracted from the wallpaper. The usual approach is one theme for one toolkit and "compatibility" layers that make the others imitate it (QGnomePlatform, qt6gtk2, qt5-styleplugins, adwaita-qt). We reject that. We build one engine per toolkit version: GTK2, GTK3, GTK4, Qt4, Qt5, Qt6, plus a libadwaita variant. Each engine lives in its own repository under `projects/`.

An engine reads one config file in its own format. It does not know where the colors came from. It turns that config into whatever its toolkit consumes: a platform theme plugin, a widget style plugin, a theme engine `.so`, generated CSS or rc files, or a mix. It exposes every setting its toolkit allows, so the engine owns the whole look of that toolkit. Toolkits differ, so the schemas differ.

A bridge script per engine sits between the shell and the engine. It is the only code that knows both sides. It reads the shell's palette and writes the engine's config in the engine's own terms (file, environment variable, gsettings key). "Engine" means any theming backend, not only toolkit plugins. A Flatpak engine (overrides, mounts and environment so sandboxed apps see the host theme) and a portal Settings engine (color-scheme, accent) are later engines that the bridge talks to the same way.

Changes apply when an app starts. No live reload in the first version.

Each toolkit also gets a demo app, copied into its own isolated repo, so every widget can be seen themed. The demo is the first milestone for each engine.

## Analysis

Points that count against or complicate the plan, from most to least serious.

1. **Drawing widgets is a different order of work from setting a palette.** A palette-only engine overlaps with `qtengine` (JSON config, KDE `.colors`, Qt5 and Qt6 builds; QE) and with `qt6ct` (archived; Q6). A drawing style engine is Kvantum, Breeze, Oxygen, Darkly or QtCurve scale work (BR, DK, OX, QC). The owner wants both. They are separate deliverables per toolkit with separate designs and separate acceptance checks.
2. **There is no standard channel for a palette.** The portal Settings interface carries `color-scheme`, `accent-color` (one RGB triple), `contrast` and `reduced-motion` only (XP3.2). The GTK backend publishes only `color-scheme` and `contrast` (XG3.4). The GNOME backend adds `accent-color` and `reduced-motion`, but maps the accent to a fixed libadwaita enum (XN3.1). So each engine needs its own delivery path: `@define-color` in `gtk.css` (KG4.1, GR), `gtk-color-scheme` for GTK2 (lxappearance.md §3, unverified entry), a color scheme file for Qt (Q6, QE).
3. **libadwaita has a fixed accent palette** (XN3.1). Recoloring it through `~/.config/gtk-4.0/gtk.css` applies to every GTK4 app and cannot be scoped per app. The libadwaita variant (patch or fork; see `libadwaita-without-adwaita`, LW) avoids this only for apps linked against it, and it needs a rebuild after each libadwaita update. The owner accepts rebuilds.
4. **Flatpak apps do not see host plugins or home config.** The Flatpak engine must expose theme files and engine plugins through overrides and mounts. Qt apps in KDE runtimes use the runtime's own Qt. This is a separate design, not a side effect of the host engines. `nwg-look` shows the override commands people use today (`flatpak override --user --env GTK_THEME=...`, NL4.9).
5. **Electron and Chromium apps** read GTK settings and the portal `color-scheme`. Coverage by the GTK engines was not studied in `refs/`. It needs a study before the acceptance check can be written.
6. **GTK2 and Qt4 run under XWayland** on this Hyprland setup. `xsettingsd` publishes XSETTINGS and is X11 only (XS5.1), which is what GTK2 and GTK3-on-X11 read. GTK2 reads rc files (`gtk-color-scheme`, engine `.so`), Qt4 reads `QSettings("Trolltech")` and its style plugins (Q4). Both are stable targets because upstream is dead.
7. **Qt5 and Qt6 plugins couple to Qt.** Platform theme plugins use private headers (`Qt6::GuiPrivate` in QE; QAdwaitaDecorations), and `qt6ct` refuses to load on a Qt major.minor mismatch (Q6). This is the rebuild cost the owner accepted.
8. **Live reload is costly.** GTK3 needs a `GTK_MODULES` plugin with a file monitor (KG4.1); Qt uses file watchers (QE). Deferring it removes most per-toolkit differences in apply logic.
9. **"Every setting" has no fixed list.** Settings differ by toolkit and a drawing style adds its own (Breeze's `breeze.kcfg`, Darkly's 375-line `darkly.kcfg`: BR2.1, DK2.1). The schema must therefore be extensible without a rewrite of the engine (see R3 and R4).

What holds up: one config file per engine with a single reader keeps each engine testable alone. User-level paths cover every target the owner named (GTK, Qt, Flatpak, Electron; no root apps). Keeping the engines unaware of the wallpaper source means the shell can change its palette extractor (matugen, wallust and pywal16 all produce named color roles: MG, WL, PW) without touching an engine.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * An engine per toolkit version (GTK2, GTK3, GTK4, Qt4, Qt5, Qt6) plus a libadwaita variant, each in its own repo under `projects/`.
  * Each engine has its own native config and exposes every setting its toolkit allows, in both modes: palette on top of an existing style, and widget drawing.
  * A bridge script per engine, written by us, that speaks the engine's language.
  * A Flatpak engine; a portal engine later.
  * Demo apps per toolkit in isolated repos.
  * Qt4 fork, packaged as our own provider of qt4.
  * Apply on app start; user-level paths; every engine and target optional.
  * Light and dark handled inside each engine's own config and schema.
  * Each engine ships as a file layout that other engines can be added next to without edits (modular install, see R10).
* **Out-of-Scope Non-Goals:**
  * Live reload of running apps (revisit if an engine is a loadable `.so` that can change running code).
  * Root GUI apps and system-wide config, except where an old toolkit has no user-level path (later, optional).
  * One shared toolkit theme that other toolkits imitate.
  * Choosing the wallpaper palette extractor. That is the shell's job.
  * Shared role names across all schemas. The studies decide, and design stage follows.

## Requirements

Each requirement is testable. "Engine" is any one of the engines above.

**Engine contract**

* **R1. Single input.** An engine reads exactly one config file (or one directory with a fixed layout) from a fixed user-level path, and an environment variable that overrides the path for tests (the pattern used by `QTENGINE_CONFIG`, QE2, and `QTCURVE_CONFIG_FILE`, QC2). It reads nothing from the shell and does not know the palette source.
* **R2. Explicit values.** Every setting the engine uses is stated in the config or in the engine's published default table. No behaviour depends on a toolkit default that is not written down (project rule: explicit over implicit).
* **R3. Coverage list.** Each engine design carries a table of every setting its toolkit lets it change, marking each as supported, deferred or impossible, with the study id that shows how to reach it. The categories are in "Settings surface" below. A setting the toolkit offers that the engine ignores needs a written reason.
* **R4. Extension without rewrite.** The config format carries a version field, ignores keys it does not know (and logs them), and allows a raw passthrough section where a toolkit key can be set directly (an rc fragment, CSS fragment or Qt property) for settings the schema has no name for yet.
* **R5. Two modes per toolkit.** For each toolkit the design states: (a) palette mode: what the engine sets over an existing base style, and which base style; (b) drawing mode: which elements it draws (primitives, controls, complex controls, CSS nodes) and how it chooses colors, shades and states. Either mode can ship alone.
* **R6. Light and dark.** The config states the scheme explicitly. The engine does not guess it from the palette (plasma-integration guesses from a window color gray value, PI; adwaita-qt guesses from luma > 128, AQ; those guesses fail on mid-tone palettes). It also publishes the scheme to the toolkit through the toolkit's own mechanism (R9).
* **R7. States.** The schema names, for every color role that has them, the states the toolkit has: GTK2 five states (normal, active, prelight, selected, insensitive: GT2.3.2), Qt three groups (active, inactive, disabled: BR3.3), GTK3/GTK4 CSS pseudo-classes (backdrop, hover, active, focus, checked, disabled: G3 and G4), plus hover and focus blends where a drawing style computes them (BR3.6, DK3.5).
* **R8. Derived colors are computed in one place per engine,** with the formula written down in the design (for example GTK2's `_gtk_style_shade` over HLS with 1.3 and 0.7: GT2.3.6-7; Breeze's `KColorUtils::mix` factors and `Blend_Value = 0.3`: BR3.5; Darkly's literal factors: DK3.4; Fusion's lighter/darker derivation: QB). Whether derived colors may be overridden per role in the config is a design decision (open item 8).
* **R9. Publish to the toolkit's own channel.** Each engine documents how its toolkit learns the scheme and theme name: `QT_QPA_PLATFORMTHEME` for Qt5/Qt6 (QB), `GTK_THEME=name:variant` and `gtk-application-prefer-dark-theme` for GTK3 (G32.9), `gtk-interface-color-scheme` for GTK4 (G4), portal then gsettings for libadwaita (LA2.1-2), `gtk-theme-name` in rc and XSETTINGS for GTK2 (GT2.2.7-9), a Qt4 style key plus `QSettings` for Qt4 (Q4).
* **R10. Modular install.** Each engine installs into its toolkit's discovery path without touching other engines' files: GTK3 `gtk-3.N` dirs (G32.2), GTK2 `gtk-2.0` theme dirs and engine `.so` dir (GT2), Qt plugins `platformthemes/` and `styles/` (QB). Removing one engine's files leaves the others working.
* **R11. Rebuild path.** Each engine states its toolkit coupling (private headers, soname, minimum version) and carries a script or CI note for rebuilding after a toolkit update.
* **R12. No imitation.** An engine does not load another toolkit's code to draw (no QGtkStyle-style `dlopen` of GTK2 from Qt, Q4; no GTK-in-Qt bridge). Colors are shared through the bridge, not through code.

**Bridge**

* **R13. One bridge per engine.** It reads the shell's theme state (palette, scheme, fonts, cursor, icon theme) and writes only that engine's config and the environment or gsettings the engine documents. It is a script, with no daemon.
* **R14. Idempotent and reversible.** Running it twice gives the same files. It keeps a backup of anything it overwrites outside the engine's own config (the way `nwg-look` and Gradience back up `settings.ini`, `gtk.css`: NL, GR).
* **R15. Engines can be disabled.** If an engine's config is absent or marked off, its toolkit keeps its own default look and no other engine is affected.

**Other engines**

* **R16. Flatpak engine.** Reads its own config and produces `flatpak override --user` settings (filesystem access for engine config and theme dirs, `GTK_THEME` and other environment, portal access) for apps the owner lists. Qt apps in KDE runtimes need a per-runtime answer in the design.
* **R17. Portal engine (later).** Publishes `color-scheme` and `accent-color` as an `org.freedesktop.impl.portal.Settings` backend. The interface is in XP5.2; the GNOME backend (XN) and GTK backend (XG) show the two existing shapes.

**Demos and acceptance**

* **R18. Demo repo per toolkit,** copied from upstream and not modified except for build files. The first acceptance check for an engine is a screenshot set of its demo: with the engine on, with the engine off, light and dark, at least two palettes.
* **R19. Setting checklist inside a demo** is decided by complexity per demo (owner answer).
* **R20. App coverage check.** One manual check per target the owner named: a GTK2 app, a GTK3 app, a GTK4 app, a libadwaita app, a Qt4/Qt5/Qt6 widget app, a Qt Quick app, one Flatpak app, one Electron app.

**Color model (from the KDE Frameworks studies; see "What the KDE Frameworks studies fix")**

* **R21. Color toolkit library (C, GPL-3.0).** Every Qt drawing engine, and every engine that derives shades, uses one local color library that implements, with the same constants as KDE, these functions: `luma`, `contrastRatio`, `mix`, `tint`, `lighten`, `darken`, `shade` (KGA, KCS3.31-3.43) and the HCY conversion (KCS3.33-3.36). The library is a separate small repo (or a directory vendored into each engine) with unit tests whose expected values are computed from the KDE sources. Settled: the library is its own repo; engines link it or embed its logic (open item 9).
* **R22. Shade roles.** The engines that need 3D shades (Qt styles, GTK2) implement `KColorScheme::shade` for the five shade roles with the three luma branches and the `contrast` clamp (KCS3.23-3.29). GTK2's own HLS shades (1.3 and 0.7: GT2.3.6-7) stay as the GTK2 default, and the config says which model is used.
* **R23. State model.** The config can describe the three Qt color groups (active, inactive, disabled) either by listing every color, or by naming an effect (intensity, color, contrast with amounts and an effect color) applied to the active colors. The effect set and defaults follow KCS3.16-3.20 (Disabled: darken 0.10, contrast fade 0.65, effect color 56,56,56; Inactive: desaturate -0.9, contrast tint 0.25, effect color 112,111,110).
* **R24. Calculated roles.** The Active, Link, Visited, Negative, Neutral and Positive backgrounds are `tint(NormalBackground, matching foreground, 0.3)` (KCS3.22). The config may override any of them (R8, open item 8).
* **R25. Palette mapping.** The Qt palette mode builds the `QPalette` with the mapping in KCS3.48 (WindowText, Window, Base, Text, Button, ButtonText, Highlight, HighlightedText, ToolTipBase, ToolTipText, PlaceholderText, Accent, Light..Shadow, AlternateBase, Link, LinkVisited), tooltips always built from the Active group.
* **R26. Symbolic icons.** When the engine ships or selects an icon theme, symbolic SVG icons are recolored by the `current-color-scheme` stylesheet convention (`.ColorScheme-Text`, `-Background`, `-Highlight`, `-HighlightedText`, `-PositiveText`, `-NeutralText`, `-NegativeText`; KD23.17-23.24). The engine exposes the eight icon colors.
* **R27. Frame contrast and contrast.** The config has two explicit numbers, `contrast` (0-1, KDE integer 0-10 divided by 10, default 0.7 in KCS3.44) and `frameContrast` (0-1, KDE default 0.2: KCS3.45), and the Qt drawing styles read them where Breeze reads `frameContrast()` (BR3.5).

## Settings surface

Categories every design must walk through (R3). Examples cite where the studies show a toolkit or style reaching the setting.

* **Palette roles and states.** Qt: 22 `QPalette` roles in three groups (QB; Q4.3.1 lists the Qt4 set). GTK2: fg, bg, text, base per five states plus derived light, dark, mid, text_aa (GT2.3.1-5). GTK3/GTK4: named colors (`@define-color`, `theme_bg_color` and similar, KG3.1) and, in GTK4, `color-mix()` and relative colors (G4). KDE `.colors` sets: View, Window, Button, Selection, Tooltip, Complementary, Header (KG2.3, BR3.2).
* **Accent.** One accent for libadwaita (portal `(ddd)`, LA2.2) and GTK4 accent variables; KDE's `DecorationFocus`/`DecorationHover` and `KStatefulBrush` focus and hover (BR3.4); selection colors in GTK2/3/Qt.
* **Light and dark, high contrast, reduced motion.** Portal keys (XP3.2); GTK3 `gtk-application-prefer-dark-theme` (G32.9); GTK4 `gtk-interface-color-scheme` (G4); Qt 6.5+ `colorScheme()` (QG, QB); libadwaita's `Adwaita-empty` base theme with its own style manager (LA2.3).
* **Fonts and text.** `gtk-font-name`, hinting, antialiasing, RGBA order, text scaling factor (NL4.2); XSETTINGS `Xft/*` (XS2.1); Qt general, fixed and small fonts (QE keys, Q6); document and monospace fonts for libadwaita (LA2.5).
* **Icons and cursors.** `gtk-icon-theme-name`, `gtk-cursor-theme-name`, `gtk-cursor-theme-size` (NL4.2; lxappearance.md §4); Qt icon theme through the platform theme (QE, PI); Breeze builds cursors from SVG with Inkscape and `xcursorgen` as a manual script (BR4.8).
* **Metrics and shape.** GTK2 `xthickness`/`ythickness` (GT2.3.1); Breeze `Metrics::*` constants in `breezemetrics.h` (BR3.5); Darkly/Klassy options for corner radius and frame width in their kcfg (DK2.1, KL); CSS radius, padding and border in GTK3/GTK4 themes (adw-gtk3, arc-theme, materia: see their studies).
* **Shadows, blur, transparency.** `BoxShadowRenderer`, shadow helper, blur helper (BR3.8-9, DK3.7); CSS `box-shadow` in GTK themes.
* **Animation.** `AnimationDurationFactor` (BR2.4); per-widget animation engines in Darkly and Oxygen (DK3.6, OX); GTK `gtk-enable-animations` (NL4.2, XG2.2).
* **Window decorations.** KDecoration3 plugins (BR4.7, DK4.6); QAdwaitaDecorations for Qt on Wayland (`QT_WAYLAND_DECORATION`, QAdwaitaDecorations study); GTK CSD styled by `gtk.css` or by `window_decorations.css` (KG3.5); `gtk-nocsd` as the opposite option (study).
* **Dialogs and portals.** Qt file, font and color dialog helper choice (QE `dialogTheme`, QG); portal file chooser.
* **Sounds and misc.** Sound theme and event sounds (NL4.2, KG2.8), toolbar style, button and menu images (KG2.9).

## Per-engine sheet

For each engine: how the toolkit takes theme input, the study to re-read, and the question the re-study must answer. Facts are from the studies; where a fact is unverified there it says so.

* **GTK2 engine.**
  * Mechanism: rc files parsed by `gtk/gtkrc.c`; theme directories `~/.themes/<name>/gtk-2.0/gtkrc` (GT2.2.3); `GTK2_RC_FILES` replaces the default list (GT2.2.1); `~/.config/gtk-2.0/gtkrc` is not searched by default (GT2.2.2); settings precedence default < rc file < XSETTINGS < application (GT2.2.7-8); engines are `.so` modules that implement draw callbacks (gtk-engines, murrine, QtCurve GTK2 engine: QC4); per-state color arrays and HLS shading (GT2.3).
  * Re-study: `gtk2-24.md`, `murrine.md`, `gtk-engines.md`, `qtcurve.md`, `gnome-themes-extra.md`, `lxappearance.md`.
  * Question: engine `.so` (draw control, full widget drawing) or rc-only (colors and pixmaps)? The owner has said both are acceptable.
* **GTK3 engine.**
  * Mechanism: CSS themes in `gtk-3.N/` directories searched from the running minor version downward (G32.2); priorities THEME 200, SETTINGS 400, APPLICATION 600, USER 800; `settings.ini` read from system, XDG and user dirs (G32.7); `GTK_THEME=name:variant` (G32.9); `gtk-modules` for plugins (KG4.4). No theme engines in GTK3 (CSS only, per the study).
  * Re-study: `gtk3.md`, `adw-gtk3.md`, `arc-theme.md`, `materia-theme.md`, `mint-themes.md`, `breeze-gtk.md`, `gtk3-classic.md`.
  * Question: pure CSS theme generated from the engine config (with `@define-color`), or CSS plus a `GTK_MODULES` helper?
* **GTK4 engine.**
  * Mechanism: CSS with `color-mix()` and variants (`gtk-dark.css`), user `~/.config/gtk-4.0/gtk.css`, color-scheme setting (`gtk.md` G4). `linkGtk4Stuff` in `nwg-look` shows the symlink layout people use (NL4.6).
  * Re-study: `gtk.md`, `adw-gtk3.md` (port to GTK4), `libadapta.md`, `Gradience.md`.
* **libadwaita variant.**
  * Mechanism: resource stylesheet inside the library, fixed accent enum, portal then gsettings for scheme and accent, `Adwaita-empty` theme set at start (`libadwaita.md` LA2). `libadwaita-without-adwaita` is one patch on `adw-style-manager.c` (LW). `libadapta` is an existing fork with its own changes (`libadapta.md`).
  * Question: patch only the style manager (small, rebased per release) or fork the stylesheet and palette (larger, full control)? Open item 4.
* **Qt4 engine.**
  * Mechanism: `QStylePlugin` with `Q_EXPORT_PLUGIN2`, `QSettings("Trolltech")`, `QGtkStyle` that `dlopen`s GTK2 (Q4). No color-scheme concept in Qt4. Qt4 is forked and packaged by us, so the platform side (what reads the config) can be changed in the fork itself.
  * Re-study: `qt4.md`, `qtcurve.md` (Qt4 style), `oxygen.md` (historical Qt4 support, UNVERIFIED), `qtstyleplugins.md`.
* **Qt5 engine.**
  * Mechanism: `QPlatformThemePlugin` (IID `...QPlatformThemeFactoryInterface.5.1`, subdir `platformthemes`), `QStyleFactory` (subdir `styles`), `QT_QPA_PLATFORMTHEME`, `QT_QUICK_CONTROLS_STYLE` and conf file (QB, QD). Private headers are needed for some theme hooks.
  * Re-study: `qtbase.md`, `qtdeclarative.md`, `qtengine.md`, `qt5ct-kde.md`, `qtstyleplugins.md`, `Kvantum.md`, `breeze.md`, `oxygen.md`, `qtcurve.md`.
* **Qt6 engine.**
  * Mechanism: as Qt5, plus `colorScheme()` and `QStyleHints::setColorScheme` (QB), KColorScheme-based palette loading in QE and `qt6ct-kde` (`KColorScheme::createApplicationPalette`), and Quick Controls style order (QD).
  * Re-study: `qtbase.md`, `qtdeclarative.md`, `qtengine.md`, `qt6ct.md`, `qt6ct-kde.md`, `plasma-integration.md`, `qqc2-desktop-style.md`, `breeze.md`, `Darkly.md`, `klassy.md`, `Kvantum.md`, `QGnomePlatform.md`, `QAdwaitaDecorations.md`.
* **Flatpak engine.**
  * Re-study: `nwg-look.md` (NL4.9-10), `xdg-desktop-portal.md`, `kde-gtk-config.md`. Gap: no study of Flatpak's own theme extension mechanism (open item 6).
* **Portal engine (later).** Re-study: `xdg-desktop-portal.md`, `-gtk.md`, `-gnome.md`.

## Re-study map for the drawing styles

What the owner will take from Breeze and Darkly, and what the re-study must settle, using what the studies already show.

* **Structure that both share (BR, DK).** A `QStyle` plugin (`Q_PLUGIN_METADATA` with `org.qt-project.Qt.QStyleFactoryInterface`, a JSON with `Keys`; BR4.1-2, DK4.1-2); a Style class that overrides `polish`/`unpolish` and the three draw families (BR4.3); a Helper object that owns config and every color function (BR4.5, DK4.4); a separate window decoration plugin with its own config file (BR7.1, DK4.6); a `.colors` scheme (BR3.1, DK3.1); a KCM config UI (DK4.8); animation engines per widget (DK3.6); shadow and blur helpers (BR3.8-9, DK3.7).
* **The color logic.** Both compute colors from `QPalette` roles per state using `KColorUtils::mix`. Breeze takes the frame factor from `KColorScheme::frameContrast()` (BR3.4-5); Darkly hard-codes factors such as 0.25, 0.3, 0.15 (DK3.4, DK7.2); Klassy uses `frameContrast()` on Qt6 and 0.2 on Qt5 (klassy.md). Hover and focus use an `opacity` from an animation and blend with `mix(focus, hover, opacity)` (BR3.6, DK3.5).
* **Dependency on KDE.** Breeze needs KStyle, KColorScheme, KSharedConfig and KDecoration3 (BR5.4). Darkly falls back to `QCommonStyle` without KF (DK1.4, DK7.3). The KDE Frameworks sources are in `refs/` and studied: `kcolorscheme.md` (KCS: `KColorScheme`, `KStatefulBrush`, the exact `shade()` branches at y<0.006, y>0.93 and the general case, `frameContrast()` default 0.2, `.colors` keys, `createApplicationPalette`), `kguiaddons.md` (KGA: `KColorUtils` mix/lighten/darken/shade/tint and the HCY conversion with Rec. 709 weights), `kconfig.md` (KCF: kconfig and kconfigwidgets, config lookup, `.kcfg` compiler; it holds no color formulas), `frameworkintegration.md` (KFI: `KStyle` overrides only pixelMetric, styleHint, polish, standardPalette and standardIcon; its `standardPalette()` calls `createApplicationPalette`; its plugin is a KMessageBox add-on, not a platform theme), and `kdecoration.md` (KD2: KDecoration3 API and kiconthemes). The color math is therefore small and fully specified (KCS3.24-3.28, KGA), so a local copy with attribution is practical; linking KF stays possible because it is LGPL. Gaps recorded there: the default config file behind `KSharedConfig::openConfig()` and the platform-theme call into `standardPalette()` are not in these trees.
* **What the re-study must answer for a Qt style engine.** (1) The list of `QStyle` elements overridden and the ones left to the base (DK4.5 says the list was not enumerated). (2) How each element's color is chosen per state. (3) Which settings are exposed in config (`breeze.kcfg`, `darkly.kcfg`). (4) How the style cooperates with the platform theme plugin (palette from one, drawing from the other). (5) Quick Controls: how `qqc2-desktop-style` draws QML controls through the app `QStyle` (QDS), so a widget style also reaches Qt Quick.
* **Other styles in the set.** `Kvantum` (SVG + `.kvconfig`, `[GeneralColors]`; KvLibadwaita swaps 92 hex placeholders from `dev/colors.json`), `QtCurve` (shared color/shade code for GTK2 and Qt4/5/6, shading modes Simple/HSL/HSV/HCY, 6 shades by 11 contrast levels: QC3), `Oxygen` (KStyle, 48 config entries, `configurationChanged()`: OX), `Klassy` (Breeze derivative with a system icon generator: KL), `adwaita-qt` (SCSS to `@define-color` to resource tables).
* **Answers from the KF studies.** Question (3) for KDE-based styles: a style's config file is a KConfig INI with a `.kcfg` schema (KCF), which a non-KDE engine can mimic or replace. Question (4): a platform theme supplies the palette and the `KDE_COLOR_SCHEME_PATH` property; the style draws from `QPalette` plus its own `KStatefulBrush` colors (KCS3.49-3.52, KCS2.9). Question (2) still needs the Breeze and Darkly re-study.
* **Rule for reuse.** License is checked per source before code is copied: Breeze, Darkly and QtCurve are GPL-family (DK7.5 for Darkly; the others per their studies), `qtengine` is BSD-2, Kvantum is GPL. If our engines are published, the license of each engine follows the code it takes. Ideas and formulas can be reused freely; copied code carries its license.

## What the KDE Frameworks studies fix

These are facts the designs can rely on. Ids point into the studies.

* **Color math is small and complete.** KDE's colors are three layers: `KColorUtils` (KGA) defines the primitives; `KColorScheme` (KCS) defines sets, roles, effects and shades on top; `createApplicationPalette` maps them to a `QPalette`. No other KF repo adds color math (KCF has none; KD23.5 says KDecoration has none; KFI says KStyle has none). The primitives are:
  * `luma(c) = 0.2126 g(R) + 0.7152 g(G) + 0.0722 g(B)` with `g(n) = clamp01(n)^2.2` (KCS3.31); inverse gamma `n^(1/2.2)` (KCS3.32).
  * `lighten(c, ky, kc=1)`: `y' = 1 - clamp01((1-y)(1-ky))`, `c' = 1 - clamp01((1-c) kc)`. `darken`: `y' = clamp01(y(1-ky))`, `c' = clamp01(c kc)`. `shade(c, ky, kc=0)`: `y' = clamp01(y+ky)`, `c' = clamp01(c+kc)` (KCS3.37-3.39). `y` and `c` are HCY luma and chroma.
  * `mix(c1, c2, bias=0.5)`: alpha-weighted per-channel linear blend; `bias<=0` gives c1, `>=1` gives c2 (KCS3.41). `tint(base, color, amount=0.3)`: 12-step bisection that keeps hue and chroma of `mix(base, color, a^0.3)` and sets luma by contrast ratio (KCS3.42). `contrastRatio = (Ya+0.05)/(Yb+0.05)` (KCS3.40).
  * HCY: Rec. 709 weights, gamma 2.2, six hue sectors (KCS3.33-3.36). A known mismatch: `normalize(NaN)` returns 1.0 though a comment says 0.0 (KCS3.30); the engines pick one behavior and test it.
  * `shade(color, role, contrast, chromaAdjust)`: contrast clamped to [-1, 1]; very dark colors (`y<0.006`), very light (`y>0.93`) and the general case each have their own per-role formula (KCS3.24-3.28). The ShadowShade is `darken(shade(...), 0.5 + 0.3 y)`.
* **KDE has no accent concept in its sets.** `Accent` in the palette is the Selection background (KCS3.48); DecorationFocus and DecorationHover are the two decoration colors per set (KCS3.4). The engines treat "accent" as a role of their own and say which KDE color it feeds.
* **Scheme file format** is INI with groups `Colors:View|Window|Button|Selection|Tooltip|Complementary|Header`, optional `[<group>][Inactive]`, `ColorEffects:Inactive|Disabled`, and `[KDE] contrast|frameContrast` (KCS2.6-2.8, KCS3.7). Each key is `r,g,b[,a]` decimal (KCF3.1) or `#rrggbb` (KCF3.2). Every group has 8 foreground keys, 2 background keys and 2 decoration keys, with built-in fallbacks per set (KCS3.7-3.9). The engine can read this format as an import path, which makes every KDE scheme usable as an engine input (open item 10).
* **INI grammar to copy if we write the same format** (KCF2.23-2.33): `#` comments, `[A][B]` nested groups, `key[$i]` immutable, `key[locale]`, escapes `\s \t \n \r \\`, an error limit of 100. Lookup: `kdeglobals` first, then app files (KCF2.8-2.14); `XDG_CONFIG_HOME/XDG_CONFIG_DIRS` are resolved by Qt, not KDE (KCF2.15, unverified). An engine that wants no KDE parse code can use a stricter INI subset.
* **`KStyle` is thin** (KFI): it overrides `pixelMetric`, `styleHint`, `polish`, `standardPalette` and `standardIcon`; seven style hints (including `Widget_Animate` and `SubMenuSloppyCloseTimeout` 300); and it offers the `new*`/`custom*` helper methods for custom style elements, enabled by the class-info key `X-KDE-CustomElements`. Our Qt styles can derive from `QCommonStyle` and implement the same list directly; the helpers exist only for apps that use KDE's custom elements.
* **How a KDE scheme reaches an app** (KCS2.9-2.14): the app property `KDE_COLOR_SCHEME_PATH` carries the path; `KColorSchemeManager` sets it before the palette change; automatic choice follows Qt's `colorScheme()` and the high-contrast preference. Darkly reads the same property (DK2.4). A non-KDE platform theme can set the same property to make Breeze-family styles follow its scheme. The `[UiSettings] ColorScheme` key stores the choice (KCS2.11).
* **KDecoration is for KWin.** Its plugin API is a compositor-facing proxy (KD24.11). Hyprland does not load it, so the Breeze and Darkly decoration plugins have no use on this setup (inference, not tested). For Qt apps under Hyprland, window frames come from Qt's own client-side decoration plugins (QAdwaitaDecorations: QAD) and for GTK from CSD CSS. The engines' decoration work targets those two, and it takes from KDecoration only the data model: border radius (four corners), border outline (thickness, color, radius), shadow, blur region (KD23.6-23.8, KD24.4).
* **kiconthemes:** the icon theme lookup, the `FollowsColorScheme` flag, the 8-color stylesheet and the selected-state color swap (KD22.6-22.17, KD23.17-23.24). The 0.85 accent tint in the selected state is the one fixed constant (KD23.20).
* **Gaps that remain:** the default config file behind `KSharedConfig::openConfig()`; the call that sends a platform theme palette into `standardPalette()`; exact `XDG_CONFIG_DIRS` precedence (all noted in KFI, KCF).

## Alternatives Weighed

* **One theme, compatibility layers for the rest** (QGnomePlatform, qt6gtk2, qt5-styleplugins, adwaita-qt). Rejected by author: no scoped control per toolkit, and the layers lag behind each toolkit's own changes.
* **Extend an existing engine** (`qtengine`, Kvantum, `qt6ct-kde`). Not rejected as a source of code. The owner treats them as reference material to read and reuse. Not rejected as a base for the Qt palette mode; the designs decide.
* **Generate GTK CSS only (Gradience style).** Rejected by author for GTK4/libadwaita as the only mechanism: it cannot scope per app (Analysis point 3), and Gradience is archived (GR).
* **Live reload from day one.** Rejected by author for now: static config at app start is enough.
* **Hand-run shell scripts instead of separate repos.** Rejected by author: "yes each one his own repo".
* **A shared palette schema defined now.** Rejected by author for now: "depend on the studies". See open item 2.

## Demo apps

All demos are copied locally from their upstream and kept in their own repos, separate from the engine repos, so several engines of one toolkit can share one demo (owner decision: isolate for flexibility).

| Toolkit | Demo found in `refs/` |
|---|---|
| GTK2 | `gtk2-24/demos` (`gtk-demo`), `gtk2-24/tests` (`testgtk`, `testrc`, `testgtkrc`) |
| GTK3 | `gtk3/demos` (`widget-factory`, `gtk-demo`, `icon-browser`) |
| GTK4 | `gtk/demos` (`widget-factory`, `gtk-demo`, `icon-browser`, `node-editor`) |
| libadwaita | `libadwaita/demo` (`adwaita-demo`) |
| Qt4 | `qt4/examples/widgets`, `qt4/demos`; no single gallery app |
| Qt5 | `qtbase-5.15/examples/widgets/gallery`, `qtquickcontrols2-5.15/examples/quickcontrols2/gallery` and `flatstyle` |
| Qt6 | `qtbase/examples/widgets/gallery`, `qtdeclarative/examples/quickcontrols/gallery` and `flatstyle` |

The libadwaita demo shows Adwaita's fixed accents until the libadwaita variant exists. Quick Controls and Widgets apps follow different style paths (QD), so a Qt engine needs a demo for each. There is no Flatpak or Electron demo. "Fork" here is a local copy, because `gh` is not installed and the upstreams are not on GitHub. The Qt4 demo set needs assembly (one app that shows every widget class).

## Key Decisions & Staging for Next Steps

Settled with the owner (also in brain page `toolkit-theming-engines`):

1. One engine per toolkit version, one repo each under `projects/`; no master theme.
2. The engine reads a config file and does not know the palette source.
3. Both palette mode and drawing mode are wanted.
4. Apply at app start; static config is accepted.
5. User-level scope; every engine and target modular and optional.
6. The bridge speaks each engine's language; the portal and Flatpak are engines too.
7. Each engine exposes every setting it can; design stays flexible for later edits; Breeze and Darkly will be re-studied at design time for ideas and code logic.
8. Demo apps copied into isolated repos; per-demo setting checklist depends on complexity.
9. Qt4 is forked and packaged by us; the libadwaita variant is planned; rebuilds are accepted.
10. Naming: the brand is `rice`, with a toolkit suffix: `rice-qt4`, `rice-qt5`, `rice-qt6`, `rice-gtk2`, `rice-gtk3`, `rice-gtk4`, `rice-adw` (libadwaita variant), `rice-flatpak`, `rice-electron`, `rice-colors` (color library). The bridge scripts stay in the shell repo. Names are lowercase ASCII with no spaces because they become the Qt style key, the plugin filename and the GTK theme folder. Open: whether the visible theme name is plain `rice` in every toolkit or carries the suffix.

Open, to settle before or during `/egm-draft`:

1. **First engine.** Not chosen. Earlier lean: Qt6 and GTK4, since their demos are the most complete.
2. **Shared role names across schemas.** Decided by the studies; a short comparison of role sets (QPalette's 22 roles in QB, the GTK named colors in KG3, KColorScheme sets in BR3.2) is the input.
3. **Delivery form per engine** (compiled plugin, generated files, or both).
4. **Libadwaita variant:** one-patch fork or a fuller fork (LW, `libadapta.md`).
5. **Electron and Chromium coverage:** needs a study.
6. **Flatpak engine design:** extension versus override-only, per toolkit; needs a study of Flatpak's theme extensions.
7. **Base style for palette-only mode** per Qt version (Fusion or another).
8. **Derived colors:** computed only by the engine, or overridable per role in config (R8).
9. **KDE dependency for Qt drawing styles: settled direction.** The color math is isolated in its own repo as a color library (R21), independent of KDE. An engine either links the library or embeds its logic (vendored copy); the engine design picks per engine. KDE Frameworks is a reference for the math, not a dependency. The library is written in C (owner: no other option) and licensed GPL-3.0. GPL-3 can take LGPL KDE code, and Darkly's source headers say "version 2 of the License, or (at your option) any later version" (`refs/Darkly/kstyle/darklystyle.cpp:6`, `COPYING:304`), so both are compatible. Check each file's header before copying any other source (Breeze and QtCurve are unchecked).
10. **Config format per engine** (INI, JSON, KConfig-style). The studies show INI for GTK2/GTK3/Qt4 and Kvantum, JSON for `qtengine`, KConfig for KDE styles.

Next steps: `/egm-draft` for the first engine (the owner picks), reading the studies cited above; `/egm-bootstrap` for `EGM.md` contracts once code exists. Settled decisions already stand in the brain.

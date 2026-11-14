---
id: toolkit-theming-engines
title: "One theming engine per toolkit version, each in its own repo under projects/"
category: decision
status: active
tags: [theme, gtk, qt, engines]
created: "2026-11-13T05:41:36"
updated: "2026-11-14T04:55:41"
---

<!-- compiled_truth -->
# Decision (owner direction, scope settled, designs open)

We build **one theming engine per toolkit version**: GTK2, GTK3, GTK4, Qt4, Qt5, Qt6. We do NOT build one theme for a single toolkit and make the others imitate it (no QGtk3Theme / qt6gtk2 / qt5-styleplugins-style bridges as the design). Each engine owns scoped control of its toolkit, has its own native theme config, and turns that config into whatever its toolkit consumes.

- Each engine lives in its own repository under `projects/` (many repos).
- Shell side: special bridge scripts sit between the shell (palette, profiles) and the engines. The shell does not know toolkit internals. Whether the six engines share one config schema is decided later by the studies, not now.
- Implementation language and form are not constrained: C, C++, Vala, plain text config, or a mix. The goal is full integrity of the theme with its toolkit, not minimal code.
- Qt4 is in scope. Its upstream being dead is a feature (stable base): fork it, add theme control, and package it as our own provider of qt4.
- Plan to build a libadwaita variant (in the spirit of libadwaita-without-adwaita) so GTK4/libadwaita apps follow our engine.
- Rebuilding an engine after a toolkit update (notably Qt5 private-header coupling) is accepted by design.
- Existing code in installed and cloned packages (qtengine, qt5ct/qt6ct, Kvantum, gtk, libadwaita, libadapta, adw-gtk3, ...) is reference material: read and plan, reuse where it fits.

Process: reference studies decide the config schema and delivery form per engine; then reqs, designs, code (see EGM flow). Related: [[shared-style-and-toolkit-integration]] (separate GTK/Qt adapters were already anticipated there), [[xdg-runtime-and-theme-schema]].



## Engine contract (owner answers, brainstorm 2026-11-13)

- **Source-agnostic:** an engine reads its palette from one specific config file and does not know where the colors came from (wallpaper extraction is the shell's business).
- **Two modes, both wanted:** an engine can draw widgets itself (style/engine plugin) and can also just set the palette on top of an existing style. Which engine ships which mode is decided per toolkit.
- **Apply at app start:** theme changes take effect when an app restarts; static config is accepted. Live reload is not required for now (revisit only if an engine is a loadable `.so` that can change running code).
- **Targets:** every GTK and Qt app, Flatpak apps and Electron apps, for the user only. Root GUI apps are out of scope. Use user-level config paths; system-wide paths only where an old toolkit offers nothing else, and then later and optional.
- **Modular and optional:** each engine and each target is independent and can be left out.
- **Bridge:** the bridge speaks each engine's own language (writes its config, sets its env/gsettings). It is the only thing that knows both the shell and an engine.
- **"Engine" means any theming backend**, not only toolkit plugins. A portal Settings backend (color-scheme, accent) can be added later as one more engine that the bridge talks to the same way.


## Timeline

- time: 2026-11-13T05:41:36
  kind: decision
  summary: "Created this page: One theming engine per toolkit version, each in its own repo under projects/"
  source: owner chat 2026-11-13
  affects: [toolkit-theming-engines]

- time: 2026-11-13T05:41:36
  kind: decision
  summary: "Owner direction: per-toolkit-version engines, no master toolkit theme"
  source: owner chat 2026-11-13
  affects: [toolkit-theming-engines]

- time: 2026-11-13T15:24:49
  kind: decision
  summary: "Owner answers: source-agnostic config-file contract, draw+palette modes, apply at app start, user-level modular targets, bridge speaks engine language, portal as a future engine"
  source: "owner chat 2026-11-13 (egm-brainstorm)"
  affects: [toolkit-theming-engines]

- time: 2026-11-13T15:30:22
  kind: decision
  summary: "Owner: Flatpak gets its own engine (overrides, mounts, env) so host theming is accepted; each engine exposes every setting its toolkit allows (complete control), modular and ready for future edits; shared role names decided by studies; first step is forked per-toolkit demo apps to see every widget themed"
  source: "owner chat 2026-11-13 (egm-brainstorm)"
  affects: [toolkit-theming-engines]

- time: 2026-11-13T15:35:17
  kind: decision
  summary: "Owner: forked per-toolkit demo apps live in their own isolated repos (separate from engine repos) for flexibility; a theme-setting checklist in the demo is decided by complexity; Qt5 reference sources (5.15 LTS) cloned into refs/ for study"
  source: "owner chat 2026-11-13 (egm-brainstorm)"
  affects: [toolkit-theming-engines]

- time: 2026-11-13T15:52:10
  kind: note
  summary: "KDE Frameworks sources added to refs/ (kcolorscheme, kguiaddons, kconfig, kconfigwidgets, kiconthemes, kdecoration, frameworkintegration) so Breeze/Darkly color formulas and KStyle can be studied; KF study precedes design; link-vs-copy stays open"
  source: "owner: bring kde framework also"
  affects: [toolkit-theming-engines]

- time: 2026-11-13T16:01:07
  kind: evidence
  summary: "KDE Frameworks studies written (kcolorscheme, kguiaddons, kconfig, frameworkintegration, kdecoration); KColorScheme::shade math is fully specified in KCS3.24-3.28 and spot-checked against source; KStyle only supplies standardPalette, so a local copy of the color math with attribution is practical"
  source: features/studies/theming
  affects: [toolkit-theming-engines]

- time: 2026-11-14T01:02:25
  kind: note
  summary: "Reqs now carry R21-R27 (local color library with KDE shade/mix/tint/HCY math, shade roles, state effects, calculated roles, palette mapping, symbolic icon recolor, contrast/frameContrast) and a KDE Frameworks findings section; copy-with-attribution proposed, owner not yet decided; KDecoration judged unusable under Hyprland (inference)"
  source: features/reqs/theming-engines.md
  affects: [toolkit-theming-engines]

- time: 2026-11-14T01:04:50
  kind: decision
  summary: "Color math (KDE-style luma/mix/tint/shade/HCY, state effects) is isolated as a separate color library repo, independent of KDE; each engine links it or embeds its logic; KDE Frameworks is reference only, not a dependency"
  source: "owner: isolate it as a separate app which links to the engine or adds its logic"
  affects: [toolkit-theming-engines]

- time: 2026-11-14T01:10:07
  kind: decision
  summary: "Color library is written in C and licensed GPL-3.0; demos must be ready before the first engine is picked"
  source: owner
  affects: [toolkit-theming-engines]

- time: 2026-11-14T04:07:46
  kind: note
  summary: "Owner plans to complete the Qt engines (Qt4/5/6) before the GTK engines, judging GTK easier; which Qt engine goes first is still open."
  source: Owner chat 2026-11-14
  affects: [toolkit-theming-engines]

- time: 2026-11-14T04:35:05
  kind: decision
  summary: "Brand is 'rice' with a toolkit suffix (rice-qt4/5/6, rice-gtk2/3/4, rice-adw, rice-flatpak, rice-electron, rice-colors); bridge scripts stay in the shell repo. Names are lowercase ASCII because they become the Qt style key, plugin filename and GTK theme folder."
  source: Owner chat 2026-11-14
  affects: [toolkit-theming-engines]

- time: 2026-11-14T04:55:41
  kind: decision
  summary: "Owner checked Qt4/Qt5/Qt6 demos visually: all fine. Kvantum themed Widgets apps but not Quick apps, confirming QD: every Qt engine needs both a Widgets path and a Qt Quick path"
  source: "owner chat 2026-11-14 (demo visual check)"
  affects: [toolkit-theming-engines]

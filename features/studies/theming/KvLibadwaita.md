# KvLibadwaita: Kvantum theme pair (light and dark) that imitates libadwaita, with KDE color files

Source: refs/KvLibadwaita (git clone; HEAD 1f4e0be, dated 2025-09-13; branch main). Citations are `path:line` relative to the repo root. The README says the project is not actively maintained (`README.md`, "Whoops it's an info dump" section). Scope of this study: theme files only (the `.kvconfig`, `.svg`, `.colors` files and the scripts that build or install them). Kvantum engine behaviour is covered by the Kvantum study (`features/studies/theming/Kvantum.md`, id prefix KV).
Id prefix: KL.

## 1. Purpose and shape
- KL.1 The repo ships a Kvantum theme named `KvLibadwaita` in two variants (light and dark). `README.md:3` describes it as a "Libadwaita style theme for Kvantum", "originally based on Colloid-kde".
- KL.2 Repo layout (25 files counted by `rg --files`): `src/KvLibadwaita/` (2 `.kvconfig`, 2 `.svg`), `src/Colors/` (2 KDE `.colors`), `dev/` (build script, two JSON maps, and a `dev/KvLibadwaita/` folder of drafts), `images/` (5 PNG previews), `install.sh`, `uninstall.sh`, `README.md`, `CREDITS`, `LICENSE`.
- KL.3 The `.kvconfig` author line is `author=Vince Liuice, based on KvAdapta by Tsu Jan` (`src/KvLibadwaita/KvLibadwaita.kvconfig:2`).

## 2. Theme input
- KL.4 Each theme variant is a pair of files: `<Name>.svg` and `<Name>.kvconfig`. Shipped files: `src/KvLibadwaita/KvLibadwaita.kvconfig` (570 lines), `src/KvLibadwaita/KvLibadwaitaDark.kvconfig` (568 lines), `src/KvLibadwaita/KvLibadwaita.svg`, `src/KvLibadwaita/KvLibadwaitaDark.svg`.
- KL.5 Kvantum lookup for these files is the same as for any theme: a user folder under `~/.config/Kvantum/<Name>/` or a system folder (see KV.8 in the Kvantum study). `install.sh:9` copies `./src/*` to `~/.config/Kvantum/` for a user install; `install.sh:20` copies to `/usr/share/Kvantum/` when run as root.
- KL.6 The shipped `src/KvLibadwaita/` folder holds the two `.kvconfig` and two `.svg` files directly. It is installed as-is: `install.sh` has no build step.
- KL.7 `.kvconfig` section list (44 section headers in `KvLibadwaita.kvconfig`): `[%General]` (`:1`), `[GeneralColors]` (`:78`), `[Hacks]` (`:99`), `[PanelButtonCommand]` (`:127`), ..., `[StatusBar]` (`:559`), `[Window]` (`:564`). The same group names as the Kvantum default file (`Kvantum/style/themeconfig/default.kvconfig`).
- KL.8 `[%General]` key values set this theme's behaviour, for example `x11drag=menubar_and_primary_toolbar` (`KvLibadwaita.kvconfig:4`), `composite=true` (`:13`), `menu_shadow_depth=16` (`:14`), `slider_handle_width=23` (`:22`), `toolbutton_style=1` (`:30`), `blurring=false` (`:33`).
- KL.9 Element references: `frame.element=button` (`KvLibadwaita.kvconfig:129`, under `[PanelButtonCommand]`), `interior.element=button` (`:135`), `indicator.element=arrow` (`:145`, `:156`). Element names are the SVG element IDs.

## 3. Color and style model
- KL.10 Colors are set in `[GeneralColors]` (`KvLibadwaita.kvconfig:78`). Light values: `window.color=#F5F5F5` (`:79`), `base.color=#ffffff` (`:80`), `highlight.color=#3c84f7` (`:87`), `text.color=#444444` (`:89`). Dark file: `window.color=#2c2c2c` (`KvLibadwaitaDark.kvconfig:79`), `highlight.color=#3584e4` (`:87`), `text.color=#dfdfdf` (`:89`).
- KL.11 The two `.kvconfig` files differ only in the `[GeneralColors]` values and a few flags. The dark file's `composite=true` (`KvLibadwaitaDark.kvconfig:13`) and `blurring=false` (`:33`) match the light file. Line-by-line diff was not computed.
- KL.12 KDE color files: `src/Colors/Libadwaita Light.colors` (147 lines; `Name=LibadwaitaLight` at `:135`) and `src/Colors/Libadwaita Dark.colors` (146 lines; `Name=LibadwaitaDark` at `:135`). Each has sections `[ColorEffects:Disabled]`, `[ColorEffects:Inactive]`, `[Colors:Button]`, `[Colors:Complementary]`, `[Colors:Header]`, `[Colors:Header][Inactive]`, `[Colors:Selection]`, `[Colors:Tooltip]`, `[Colors:View]`, `[Colors:Window]`, `[General]`, `[KDE]`, `[WM]` (light file section lines `:1`, `:10`, `:21`, `:35`, `:49`, `:63`, `:77`, `:91`, `:105`, `:119`, `:133`, `:138`, `:141`).
- KL.13 `[Colors:Window]` in the light file: `BackgroundNormal=250,250,250` (`src/Colors/Libadwaita Light.colors:121`), `DecorationFocus=28,113,216` (`:122`). The `.colors` files are plain KDE color scheme files; they are not read by the `.kvconfig` files.

## 4. Output and rendering path
- KL.14 The SVG files hold the artwork. Element IDs are `id="..."` attributes: 1,219 in `KvLibadwaita.svg` and 1,229 in `KvLibadwaitaDark.svg` (counted by `rg -o`). Most frequent suffix families in the light file: `-normal`, `-pressed`, `-toggled` (for example `tbutton-normal`, `tbutton-pressed`, `tbutton-toggled`, `menubar-normal`, `progress-normal`, `tooltip-normal`, `tooltip-shadow`, `mask`).
- KL.15 The state-suffix fallback that uses these names is implemented in the Kvantum engine (refs/Kvantum: `Kvantum/style/rendering.cpp:57-62`, see KV.22). This theme depends on those names existing.
- KL.16 Hex value `#00037f` is removed from SVG output by the build script: `dev/build.py:27`, `:61`, `:62` replace `#00037f` with `none`.

## 5. Extension and integration points
- KL.17 Build pipeline (dev only): `dev/build.py` (69 lines) reads `dev/colors.json` (`:53`), and for each entry replaces the placeholder hex `ref` with `light` in the light SVG and `.kvconfig` text, and with `dark` in the dark text (`:53-59`). It writes `KvLibadwaita.svg`, `KvLibadwaitaDark.svg`, `KvLibadwaita.kvconfig` and `KvLibadwaitaDark.kvconfig` into `~/.config/Kvantum/KvLibadwaitaDraft/` (`:9` `dst`, `:15-18` output paths).
- KL.18 `dev/colors.json` is a map from element names to `{ "ref", "light", "dark" }` objects (example: `"button-normal"` with `ref` `#c64600`, `light` `#d9d9d9`, `dark` `#444444`, `dev/colors.json:2-6`). The file has 92 `"ref"` entries.
- KL.19 `dev/color-assignment.json` (93 lines) is not read by `build.py` (its use is commented out at `dev/build.py:31`).
- KL.20 Packaging: `install.sh` and `uninstall.sh` (27 lines each) are the only install paths. `uninstall.sh` was not read in full.

## 6. Data and tooling
- KL.21 Tooling: Python 3 (`dev/build.py`), bash (`install.sh`, `uninstall.sh`). No Makefile, CMake file or CI config in the repo.
- KL.22 The `dev/KvLibadwaita/` folder holds `KvLibadwaita.kvconfig`, `KvLibadwaitaDark.kvconfig`, `KvLibadwaitaDraft.kvconfig`, plus SVG files (6 files in total). `dev/build.py:11-12` reads `KvLibadwaitaDraft.svg` and `KvLibadwaitaDraft.kvconfig` from `here/KvLibadwaita` (the source folder path differs from `dev/KvLibadwaita`; see KL.23).
- KL.23 Path mismatch: `dev/build.py:8` sets `src = os.path.join(here, 'KvLibadwaita')`, where `here` is the current working directory. Running the script from `dev/` therefore looks for `dev/KvLibadwaita/`. This matches the folder name in the repo.
- KL.24 `images/` holds 5 PNG preview images (`images/light.png`, `dark.png`, `combo.png`, `sliders-light.png`, `sliders-dark.png`), referenced from `README.md`.

## 7. Facts of note
- KL.25 The shipped `.kvconfig` and `.svg` files contain no `#c64600` placeholder (the first `ref` in `dev/colors.json`); the build output replaces it. `rg -c "#c64600"` on `src/KvLibadwaita/` returned no matches.
- KL.26 `install.sh` branches on `$EUID` (`install.sh:3`): as user it copies to `~/.config/Kvantum/` (`install.sh:9`), as root it copies to `/usr/share/Kvantum/` (`install.sh:20`). Both branches are gated by a `y/n` prompt (`install.sh:5`, `:16`).
- KL.27 `README.md:19-20` (section "Installation") lists the same manual copy: `copy src/KvLibadwaita into ~/.config/Kvantum`.

## 8. Not covered
- KL.28 `uninstall.sh` was not read in full.
- KL.29 The `.svg` artwork was not rendered or inspected visually. Element geometry was not read.
- KL.30 The 44 `.kvconfig` keys were sampled, not listed key by key. A full key table was not produced.
- KL.31 Kvantum engine behaviour for each key was not verified; see the Kvantum study.
- KL.32 `CREDITS` and `LICENSE` were not read.
- KL.33 No build, install or run was done. No commands were run inside `refs/`.

# mint-themes: Linux Mint Mint-X and Mint-Y theme sources and generator scripts

Source: refs/mint-themes (shallow clone; commit 6c6095d; branch master). License: GPL-3+, `debian/copyright:8`. Scope: `src/Mint-Y/` (gtk-2.0, gtk-3.0, gtk-4.0, libadwaita-1.5/1.7/1.9, libadapta-1.5, variations/), `src/Mint-X/theme/Mint-X/` (gtk-3.0, gtk-4.0 sass only), root scripts `constants.py`, `colorize.py`, `generate-themes.py`, `update-variations.py`, `README.md`, `Makefile`. Cinnamon, xfwm4, openbox, metacity and flatpak parts were not studied.
Id prefix: MT.

## 1. Purpose and shape
- MT1.1 Two families of GTK themes, Mint-X and Mint-Y, each with GTK2, GTK3 and GTK4 outputs plus other desktops. `generate-themes.py:4-6,104-113`
- MT1.2 Mint-Y is built from `src/Mint-Y/` by `src/Mint-Y/build-themes.py`. Mint-X is built from `src/Mint-X/theme/Mint-X/` directly inside `generate-themes.py`. `generate-themes.py:29-41`, `src/Mint-Y/build-themes.py:58-61`
- MT1.3 Language: Python 3 scripts (`generate-themes.py`, `update-variations.py`, `build-themes.py`, `colorize.py`), with `os.system` shell-outs to `pysassc` (libsass), `sed`, `find`, `cp`, `inkscape`, `optipng`. `generate-themes.py:31`, `src/Mint-Y/build-themes.py:14`, `src/Mint-Y/gtk-3.0/render-assets.sh:3-4`
- MT1.4 Top-level layout that matters:
  - `constants.py`: accent and color tables for Mint-X and Mint-Y. `constants.py:4-30,34-` 
  - `colorize.py`: PNG hue-shift tool (see MT4.8). `colorize.py:1-89`
  - `generate-themes.py`: whole-build driver. `generate-themes.py:1-224`
  - `update-variations.py`: regenerates `src/Mint-Y/variations/<Color>/`. `update-variations.py:42-81`
  - `src/Mint-Y/`: Mint-Y sources (see MT2). `src/Mint-Y/build-themes.py`
  - `src/Mint-X/theme/Mint-X/`: Mint-X sources. `src/Mint-X/theme/Mint-X/gtk-3.0/sass/_colors.scss:10`
  - `files/usr/share/themes/`: hand-made `index.theme` and thumbnails per variant (for example `Mint-Y-Dark`). `files/usr/share/themes/Mint-Y-Dark/index.theme:1-10`
  - `debian/`, `flatpak/`: packaging. `debian/control:13` (Description: Mint themes)
- MT1.5 Build entry: `Makefile` target `buildthemes` runs `./generate-themes.py`; `clean` removes `usr`. `Makefile:1-8`

## 2. Theme input (how configuration reaches it)
- MT2.1 Input is source files, not a runtime config. Color data lives in Sass variables and in GTK2 `gtkrc` text files. `src/Mint-Y/gtk-3.0/sass/_colors.scss:1-28`, `src/Mint-Y/gtk-2.0/gtkrc:1`
- MT2.2 Accent colors are hard-coded hex strings in `constants.py`. Mint-X: `X_HEX_ACCENTS = ["#9ab87c", "#accd8a"]` and `X_RGB_ACCENTS = ["172, 205, 138", "#accd8a"]`. `constants.py:4,18`. Mint-Y: `Y_HEX_ACCENT1 = ["#35a854"]` (base) and `Y_HEX_ACCENT2 = ["#35a854"]` (dark). `constants.py:34-35`
- MT2.3 Per-variant accent tables: `x_hex_colors[name]`, `x_rgb_colors[name]` (Mint-X, 10 names: Aqua, Blue, Brown, Grey, Orange, Pink, Purple, Red, Sand, Teal) at `constants.py:6-30`. `y_hex_colors1[name]`, `y_hex_colors2[name]` (Mint-Y) at `constants.py:37-` (for example Red `#e82127` at line 58).
- MT2.4 Variation selection: `generate-themes.py` loops over `os.listdir("src/Mint-X/variations")` (line 44) and `y_hex_colors1.keys()` (line 116). Mint-Y variation source directories are under `src/Mint-Y/variations/<Color>/`. `src/Mint-Y/variations/` contains Aqua, Blue, Grey, Orange, Pink, Purple, Red, Sand, Teal.
- MT2.5 Mint-Y variant names: `VARIATIONS = ["Mint-Y", "Mint-Y-Dark"]`. `src/Mint-Y/build-themes.py:5-6`. Derived names are `Mint-Y-<Color>` and `Mint-Y-Dark-<Color>`. `generate-themes.py:116-124`
- MT2.6 Mint-X variant names: `Mint-X-<Color>`, derived by copying `Mint-X` and copying `src/Mint-X/variations/<Color>/*` over it. `generate-themes.py:47-49`
- MT2.7 Output destination: `DEST = '../../usr/share/themes'` for Mint-Y (relative to `src/Mint-Y`). `src/Mint-Y/build-themes.py:8`. Mint-X and Mint-Y derivations write to `usr/share/themes/` under the repo root. `generate-themes.py:25,41,47`

## 3. Color and style model
- MT3.1 Mint-Y palette: the same GNOME/Adwaita-style 45-color table as adw-gtk3 (`$blue_1` ... `$dark_5`), but expressed as `--name: hex` CSS custom properties and `@define-color` lines. `src/Mint-Y/libadwaita-1.9/gtk.css:1` (one `:root` line with the palette), `:3-7` (define-color)
- MT3.2 Mint-Y GTK3/GTK4 Sass color model (`_colors.scss`): a block of `null` declarations for the named colors that the rest of the theme uses (`$opposite`, `$base_color`, `$text_color`, `$bg_color`, `$borders_color`, `$header_bg`, `$osd_bg_color`, `$fg_color`, `$button_bg`, `$trough_color`, `$wm_*`, and so on). `src/Mint-Y/gtk-3.0/sass/_colors.scss:1-27`
- MT3.3 Light and dark are selected by `$variant` with `@if $variant == 'light' { ... } @else { ... }`. `src/Mint-Y/gtk-3.0/sass/_colors.scss:29-`. The variant is set at the top of each entry file: `$variant: 'light';` in `gtk.scss` and `'dark'` in `gtk-dark.scss`. `src/Mint-Y/gtk-3.0/sass/gtk.scss:1`, `src/Mint-Y/gtk-4.0/sass/gtk-dark.scss:1`
- MT3.4 Light-variant derivations use libsass color functions: `$bg_color: lighten($header_bg, 5%)`, `$borders_color: darken($bg_color, 18%)`, `$header_bg_backdrop: lighten($header_bg, 3%)`. `src/Mint-Y/gtk-3.0/sass/_colors.scss:34-38`. Also `transparentize(...)` and `opacify`-style alpha in `_colors.scss:112-113`.
- MT3.5 Accent in Sass: `$accent_color: #35A854;`, `$selected_bg_color: $accent_color;`, `$selected_fg_color: #FFFFFF;`, `$selected_borders_color: darken($selected_bg_color, 15%);`. `src/Mint-Y/gtk-3.0/sass/_colors.scss:118-122`. The GTK4 `_colors.scss` has the same accent at line 119. `src/Mint-Y/gtk-4.0/sass/_colors.scss:119`
- MT3.6 Mint-X accent in Sass: `$accent_color: #9ab87c;` and `$selected_bg_color: if($variant == 'light', $accent_color, darken($accent_color, 15%));`. `src/Mint-X/theme/Mint-X/gtk-3.0/sass/_colors.scss:10-11`
- MT3.7 GTK2 colors are in `gtkrc` as a `gtk-color-scheme` string of `name:#hex` pairs separated by `\n`: `base_color`, `fg_color`, `text_color`, `bg_color`, `selected_bg_color:#35a854`, `tooltip_bg_color`, `menu_bg`, and others. `src/Mint-Y/gtk-2.0/gtkrc:1`. The dark file is `gtkrc-dark` with the same keys and dark values (for example `bg_color:#2e2e33`). `src/Mint-Y/gtk-2.0/gtkrc-dark:1`
- MT3.8 GTK3 and GTK4 accent colors in libadwaita overrides are `@define-color accent_color`, `accent_bg_color`, `destructive_bg_color`, `success_bg_color` and similar, switched by `prefers-color-scheme`. `src/Mint-Y/libadwaita-1.9/gtk.css:98,101`. The `accent_color` there is `oklab(from @accent_bg_color min(l, 0.5) a b)`. `src/Mint-Y/libadwaita-1.9/gtk.css:61`
- MT3.9 Per-state handling is in the widget Sass (`_common.scss`, `_applications.scss`, `_drawing.scss`, plus `_colors.scss` values); these files were not read in detail (see section 8).
- MT3.10 Shades and states in GTK3 are written with libsass functions (`lighten`, `darken`, `transparentize`), not with GTK `shade()`/`mix()`. `src/Mint-Y/gtk-3.0/sass/_colors.scss:34-38,112-122`

## 4. Output and rendering path
- MT4.1 Sass compile step (libsass via `pysassc`): each `gtk-N.0/` directory has `sass/gtk.scss` and `sass/gtk-dark.scss`, compiled to `gtk.css` and `gtk-dark.css` in place. `src/Mint-Y/gtk-3.0/parse-sass.sh:3-4`, `src/Mint-Y/build-themes.py:13-24`
- MT4.2 The GTK3 Sass entry is `@import`-based: `gtk.scss` imports `colors`, `drawing`, `common`, `applications`, `lightdm`, `ubiquity`, `colors-public`, `libhandy`. `src/Mint-Y/gtk-3.0/sass/gtk.scss:1-10` (the file is 10 lines)
- MT4.3 GTK4 Sass entry: `gtk.scss` sets `$variant: 'light'` and imports `colors`, `drawing`, `common`, `colors-public`. `src/Mint-Y/gtk-4.0/sass/gtk.scss:1-6`. The GTK4 dark entry sets `$variant: 'dark'`. `src/Mint-Y/gtk-4.0/sass/gtk-dark.scss:1`
- MT4.4 Compiled GTK3 and GTK4 CSS is also checked in: `src/Mint-Y/gtk-3.0/gtk.css` (about 4249 lines), `src/Mint-Y/gtk-4.0/gtk.css` (about 3205 lines); these are rebuilt by `build-themes.py`. `wc -l` was run; no line citations for the checked-in CSS body.
- MT4.5 Mint-Y output tree (built by `build-themes.py`, `Mint-Y` variant):
  - `gtk-2.0/`: `assets/` (from `gtk-2.0/assets`), `*.rc`, `gtkrc`. `src/Mint-Y/build-themes.py:65-70`
  - `gtk-3.0/`: `assets/`, `gtk.css`, `gtk-dark.css`, `thumbnail.png`. `src/Mint-Y/build-themes.py:71-77`
  - `gtk-4.0/`: `assets/`, `gtk.css`, `gtk-dark.css`. `src/Mint-Y/build-themes.py:78-83`
  - `libadwaita-*/` and `libadapta-*/` copied to the theme root. `src/Mint-Y/build-themes.py:102-103`
- MT4.6 Mint-Y-Dark output: GTK2 uses `assets-dark` renamed to `assets`, `gtkrc-dark` copied as `gtkrc`, `menubar-toolbar-dark.rc` as `menubar-toolbar.rc`. `src/Mint-Y/build-themes.py:106-114`. GTK3 and GTK4 `gtk.css` are the dark CSS copied under the name `gtk.css` (`:119`, `:126`).
- MT4.7 Mint-Y color variations: `generate-themes.py` copies the built Mint-Y theme, regenerates GTK4 and GTK3 Sass after applying `y_colorize_directory` (sed replacement of `#35a854` with the variation's hex), recompiles `gtk.css`/`gtk-dark.css`, removes `sass/` and `parse-sass.sh` from the output, and substitutes the accent in GTK2 rc files and libadwaita defaults. `generate-themes.py:116-190`. The substitution is a `sed -i s'/<from>/<to>/gI'` on the file list at lines 173-190.
- MT4.8 Hue-shift of raster assets (not run by the build): `colorize.py` maps a color name to an HSV hue (`HUE["Red"] = 2`, etc., lines 7-16), converts RGB to HSV (`rgb_to_hsv`, line 18), sets hue (`shift_hue`, line 64) and writes the PNG back (`colorize.py:83-89`). The only in-repo reference to it is `README.md:5` ("Add new hue to `colorize.py`"). No call site was found in the scripts (`rg colorize`).
- MT4.9 Asset generation: SVG sources (`assets.svg`) are rendered to PNG by `render-assets.sh` using `inkscape --export-id` for each id in `assets.txt`, then `optipng`. `src/Mint-Y/gtk-3.0/render-assets.sh:3-20`. Dark GTK2 assets use `render-dark-assets.sh` in `gtk-2.0/`. `src/Mint-Y/build-themes.py:33`
- MT4.10 Variation assets: `update-variations.py` renders each color's assets by calling the `render-assets.sh` scripts through `subprocess.Popen`. `update-variations.py:23-32`. It copies the variation's `assets.svg` and `assets.txt` files from `src/Mint-Y/` into `src/Mint-Y/variations/<Color>/`. `update-variations.py:52-81`
- MT4.11 Mint-X output: `generate-themes.py` compiles Mint-X GTK4 and GTK3 Sass (`pysassc`), copies `src/Mint-X/theme/*` to `usr/share/themes/`, then for each variation copies the base theme and sed-replaces the accent. `generate-themes.py:29-65`. Mint-X GTK2 accent is replaced in `gtk-2.0/gtkrc` and `gtk-3.0/settings.ini` among other files. `generate-themes.py:53-54`
- MT4.12 Call chain for Mint-Y GTK3: `constants.py` (accent hex) -> `generate-themes.py` (`y_colorize_directory` sed on `gtk-3.0/sass`) -> `pysassc sass/gtk.scss gtk.css` -> `usr/share/themes/Mint-Y-<Color>/gtk-3.0/gtk.css`. Then the GTK3 engine reads that CSS. `generate-themes.py:145-160`
- MT4.13 Call chain for Mint-Y GTK2: `constants.py` (accent hex) -> sed on `gtk-2.0/gtkrc` and `main.rc` and other `.rc` files -> GTK2 reads `gtkrc` which `include`s `main.rc`, `apps.rc`, `panel.rc`, `menubar-toolbar.rc`. `generate-themes.py:172-190`, `src/Mint-Y/gtk-2.0/gtkrc:7-10`
- MT4.14 GTK2 engine usage: `main.rc` uses `engine "pixmap"` (lines 101, 549, 690, 722, 906, 957, 999) and `engine "adwaita"` (line 535). The pixmap engine draws from PNG files in `assets/`. `src/Mint-Y/gtk-2.0/main.rc:101,535,549`. The GTK2 README says the theme "is heavily based on the pixmap engine". `src/Mint-Y/gtk-2.0/README.md:8`

## 5. Extension and integration points
- MT5.1 Installed location: `/usr/share/themes/<name>/` (the `files/` tree is copied to `/`). `files/usr/share/themes/Mint-Y-Dark/index.theme:1-10`. Derived themes are generated under `usr/share/themes/` in the repo before packaging. `generate-themes.py:25`
- MT5.2 `index.theme` `GtkTheme=` and `MetacityTheme=`, `IconTheme=` keys (Mint-Y-Dark). `files/usr/share/themes/Mint-Y-Dark/index.theme:3,8-10`
- MT5.3 Engine coupling: GTK2 needs the `pixmap` and `adwaita` engines; `main.rc` names them directly. `src/Mint-Y/gtk-2.0/main.rc:101,535`
- MT5.4 libadwaita override directories are named by version: `libadwaita-1.5`, `libadwaita-1.7`, `libadwaita-1.9`, `libadapta-1.5`. `src/Mint-Y/build-themes.py:102-103`, `generate-themes.py:57-62,179-184`. `libadwaita-1.9` contains only `gtk.css` and assets (no `defaults-*.css`). `src/Mint-Y/libadwaita-1.9/` (file list)
- MT5.5 Adding a variation (documented steps): add color to `constants.py`, add hue to `colorize.py`, add name to lists in `update-variations.py`, run `update-variations.py <Color>`, create theme directory under `files/usr/share/themes`, run `generate-themes.py`. `README.md:1-16`

## 6. Data and tooling
- MT6.1 Python scripts: `generate-themes.py` (224 lines), `update-variations.py` (132 lines), `src/Mint-Y/build-themes.py` (145 lines), `colorize.py` (89 lines), `constants.py`, `list-green-colors.py` (not read).
- MT6.2 Sass compiler: `pysassc` (libsass Python binding) is invoked by name. `generate-themes.py:31`. No pinned version in the repo.
- MT6.3 Image tools: `inkscape` at `/usr/bin/inkscape`, `optipng` at `/usr/bin/optipng` hardcoded. `src/Mint-Y/gtk-3.0/render-assets.sh:3-4`
- MT6.4 Asset manifests: `assets.txt` per gtk/xfwm directory lists export ids. `src/Mint-Y/gtk-3.0/assets.txt`, `src/Mint-Y/gtk-2.0/assets.txt`
- MT6.5 Docs: `README.md` (variation how-to), `src/Mint-Y/gtk-3.0/README.md` (libsass, edit `_common.scss` and `_applications.scss`, "Never edit any of the .css files manually"), `src/Mint-Y/gtk-2.0/README.md` (pixmap assets, inkscape). `src/Mint-Y/gtk-3.0/README.md:1,5-9`
- MT6.6 Tests: `test-mint-x` and `test-mint-y` exist at repo root (not read). Packaging: `debian/` (`rules`: `dh $@`, `debian/rules:3-4`).

## 7. Facts of note
- MT7.1 The accent for Mint-Y is a single hex, `#35a854`, that is string-replaced across all GTK2 rc files, GTK3/GTK4 `_colors.scss`, and libadwaita defaults. Replacement is by `sed`, case-insensitive (`gI`). `generate-themes.py:173-190`, `y_colorize_directory` at `generate-themes.py:14-18`
- MT7.2 The accent replacement is textual: any occurrence of the source hex in the copied files is replaced. This is the mechanism; no parser is involved. `generate-themes.py:8-18`
- MT7.3 Mint-Y GTK3 and GTK4 Sass comment: "Never edit any of the .css files manually." `src/Mint-Y/gtk-3.0/README.md:1`
- MT7.4 The generator removes the Sass sources from the output (`rm -rf sass parse-sass.sh`), so the shipped theme contains only compiled CSS. `generate-themes.py:72,79,141,159`
- MT7.5 Known build-time comment: a commented-out `sed` to switch "no-tint" to "tint" in GTK3 sass exists but is disabled. `generate-themes.py:148-149`
- MT7.6 `generate-themes.py` removes `metacity-theme-3.xml` from each derived theme; comment says it uses GTK colors. `generate-themes.py:192-193`
- MT7.7 `build-themes.py` writes GTK4 dark as `gtk.css` (not a separate dark file) for the dark variant. `src/Mint-Y/build-themes.py:126`
- MT7.8 License: GPL-3+. `debian/copyright:8`

## 8. Not covered
- Widget-level Sass: `_common.scss`, `_applications.scss`, `_drawing.scss`, `_lightdm.scss`, `_ubiquity.scss`, `_libhandy.scss` in `gtk-3.0/sass/` and `gtk-4.0/sass/` were not read.
- Mint-X `gtk-2.0` rc files and Mint-X `gtk-3.0/sass` partials were not read.
- Cinnamon, xfwm4, openbox, metacity, and the `flatpak/` directory were not read.
- `libadwaita-1.5`, `libadwaita-1.7`, `libadapta-1.5` CSS bodies were not read; only `libadwaita-1.7/defaults-light.css` size (61 lines) and `libadwaita-1.9/gtk.css` header lines were checked.
- `list-green-colors.py`, `test-mint-x`, `test-mint-y`, `update-variations.py` lines 1-41 and 83-132 were not read.
- The generated `usr/` output was not produced; no build was run.

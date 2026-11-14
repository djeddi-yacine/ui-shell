# adw-gtk3: unofficial GTK3 port of libadwaita, built from Sass

Source: refs/adw-gtk3 (shallow clone; commit 47922ed; branch main). License: LGPL-2.1, `LICENSE:1-2`. Scope: whole repo; the GTK3 path (`src/sass/`, `src/theme-*/`) and the checked-in GTK4 CSS copies (`src/theme-light/gtk4/`) in detail; `snap/`, `README.md` for install and usage only.
Id prefix: AG.

## 1. Purpose and shape
- AG1.1 The README describes the project as "An unofficial GTK3 port of libadwaita", with a stated caveat that it is not a 100% look-alike. `README.md:3-6`
- AG1.2 Language is Sass (SCSS), compiled by the external `sass` binary through Meson. It ships a GTK3 CSS theme and also installs a GTK4 CSS set (libadwaita copy plus a tweaks file). `src/meson.build:10`, `src/theme-light/meson.build:18-28,49-51`
- AG1.3 Version file contains `6.5`. `version:1`
- AG1.4 Top-level layout:
  - `src/sass/`: all Sass sources for GTK3 (entry points `gtk.scss`, `gtk-dark.scss`; partials; `widgets/`). `src/sass/gtk.scss`
  - `src/sass/gtk4/`: Sass for the GTK4 tweak file only. `src/sass/gtk4/libadwaita-tweaks.scss`
  - `src/theme-light/`, `src/theme-dark/`: Meson files that compile and install the outputs for each variant. `src/theme-light/meson.build`, `src/theme-dark/meson.build`
  - `src/theme-light/gtk4/`: checked-in GTK4 CSS (`gtk.css`, `gtk-dark.css`, `libadwaita.css`). `src/theme-light/gtk4/gtk.css:1-2`
  - `src/assets/`: SVG/PNG assets (checkmarks, slider marks, text selection handles, `@2` and `-dark` variants). `src/assets.txt:1-5`
  - `src/index.theme.in`: template for `index.theme`. `src/index.theme.in:2,6`
  - `snap/snapcraft.yaml`, `README.md`, `src/README.md`: packaging and docs.
- AG1.5 Build dependencies: `ninja`, `git`, `meson`, and `dart-sass` (or `sass` via npm). `src/README.md:7-10`. Meson looks up the program `sass`. `src/meson.build:10`

## 2. Theme input (how configuration reaches it)
- AG2.1 There is no runtime configuration file. The theme is static CSS installed into the theme directory; selection is done by the desktop settings. Activation example: `gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'` together with `color-scheme 'prefer-dark'`. `README.md:100-108`
- AG2.2 For some GTK4 apps the README suggests a user file `~/.config/gtk-4.0/settings.ini` with `gtk-application-prefer-dark-theme=1` and `gtk-theme-name=adw-gtk3-dark`. `README.md:111-115`
- AG2.3 Build-time inputs are Meson options: `datadir` only (`get_option('datadir')`). `src/meson.build:1-2`
- AG2.4 Customization is documented as GTK named colors, via the separate project adw-colors (external, not in this repo). `README.md:121-122`
- AG2.5 Sass variables that are configurable at build time: `$variant` (set by the entry file) and `$toolkit` (set only to `gtk4` for the GTK4 tweak file). `src/sass/_settings.scss:2-3`, `src/sass/gtk4/libadwaita-tweaks.scss:4-6`

## 3. Color and style model
- AG3.1 Palette: 45 hex constants named `$<hue>_<1..5>` for blue, green, yellow, orange, red, purple, brown, light, dark (GNOME HIG-style palette). `src/sass/_palette.scss:1-45`
- AG3.2 The palette is exported as GTK named colors with `@define-color <hue>_<n> #{"" + $var}`. `src/sass/_palette.scss:50-` (one line per entry)
- AG3.3 Named colors used by apps and by the theme (`window_bg_color`, `view_bg_color`, `headerbar_bg_color`, `sidebar_bg_color`, `accent_bg_color`, `destructive_bg_color`, `success_*`, `warning_*`, `error_*`, `card_*`, `popover_*`, `dialog_*`, and matching `_fg_`, `_shade_`, `_backdrop_` variants). Defined in `src/sass/_defaults.scss`; `window_bg_color` at line 58, headerbar at 66-71, sidebar at 74-78.
- AG3.4 Light/dark handling is a compile-time switch on `$variant`, not a runtime toggle. Each named color uses `if(sass($variant == 'light'): ...; else: ...)`. `src/sass/_defaults.scss:43-55,58-78`
- AG3.5 Accent and status colors are the palette steps selected by variant: `destructive_bg_color` is `@red_3` (light) or `@red_4` (dark); `success_bg_color` is `@green_4` or `@green_5`. `src/sass/_defaults.scss:28-38`. The accent is `@blue_3` in both variants. `src/sass/_defaults.scss:24`
- AG3.6 Derived colors (`*_color` foreground/text variants) use `gtkmix(...)` against black (light, 83%) or white (dark, 60%). `src/sass/_defaults.scss:43-55`
- AG3.7 Static fallback text colors are hard-coded hex values chosen to match a translucent foreground on the light background: `$_fg_color #323233`, `$_text_color #333334`, `$_hb_fg_color #2f2f30`, with a comment saying they avoid heavy transparency in GTK3. `src/sass/_defaults.scss:16-21`
- AG3.8 Derived shades and states are in `src/sass/_colors.scss`: caret `gtkshade(view_fg,1.05|0.97)` (`:47`); `border_color` `gtkalpha(currentColor,.15)` (`:48`); `borders_color` `gtkmix(currentColor, window_bg, 15%)` (`:49`); selection colors `gtkalpha(accent_bg, .25|.32|.39)` (`:55-57`); hover/active/selected overlays `gtkalpha(currentColor, .04..0.19)` (`:53-54,68-72`); trough and progress (`:75-79`); slider `gtkmix(white, view_bg, 80%)` (`:80`).
- AG3.9 Per-state handling exists as separate named variables with `_hover_`, `_active_`, `_checked_`, `_backdrop_` suffixes (for example `adw_button_hover`, `trough_active_color`). `src/sass/_colors.scss:60-66,75-77`. Backdrop colors are the `*_backdrop_color` named colors. `src/sass/_defaults.scss:74-76`
- AG3.10 Radii, transitions and opacity are Sass constants: `$button_radius: 9px`, `$menu_radius: 9px`, `$window_radius: calc($button_radius + 6px)`, `$card_radius: 12px`, `$check_radius: 6px`, `$disabled_opacity: 0.5`, `$backdrop_transition: 200ms ease-out`. `src/sass/_settings.scss:6-17`
- AG3.11 `$asset_suffix` is `-dark` for the dark variant and empty otherwise; it selects asset file names. `src/sass/_settings.scss:5`

## 4. Output and rendering path
- AG4.1 Entry points: `src/sass/gtk.scss` sets `$variant: 'light'` (line 3) and `@use`s `colors-public`, `common`, then all `widgets/*` partials. `src/sass/gtk-dark.scss:3` sets `'dark'`; the rest of the list is the same file family.
- AG4.2 Dependency chain of named colors: `gtk.scss` -> `_colors-public.scss` (`@use 'colors' as *`, line 9) -> `_colors.scss` (uses `settings`, `functions`, `palette`, `defaults`, lines 1-4) -> `_defaults.scss` (uses `settings`, `functions`, `palette`, lines 12-14) -> `_palette.scss`.
- AG4.3 Color functions (`src/sass/_functions.scss`) switch by `$toolkit`:
  - `gtkalpha($c,$a)`: GTK3 `alpha(c,a)` (line 15); GTK4 `color-mix(in srgb, c a%, transparent)` (lines 10-17).
  - `gtkmix($c1,$c2,$r)`: GTK3 `mix(c1,c2, 1 - r/100%)` (lines 26-27); GTK4 `color-mix(in srgb, c1 r, c2)` (line 24).
  - `gtkshade($c,$s)`: GTK3 `shade(c,s)` (line 38); GTK4 `hsl(from c h calc(s*s') calc(l*s'))` (line 36).
  - `gtkcolor($c)`: returns the string `@c`, which is how Sass emits GTK named-color references (line 44).
- AG4.4 Compile step: `sass --no-source-map input output` as Meson `custom_target`s. Light: `sass/gtk.scss` -> `gtk.css` installed to `<datadir>/themes/adw-gtk3/gtk-3.0/` (`src/theme-light/meson.build:18-26`). Light dark-file: `sass/gtk-dark.scss` -> `gtk-dark.css` into the same directory (`:28-36`). Dark build: `src/theme-dark/meson.build:18-26` produces `gtk-dark.css` into `<datadir>/themes/adw-gtk3-dark/gtk-3.0/`.
- AG4.5 Each Sass target lists every `.scss` file as a dependency through `run_command('find', ..., '-name', '*.scss')`, so ninja rebuilds on any change. `src/theme-light/meson.build:9-16`
- AG4.6 `index.theme` is generated from `src/index.theme.in` with `ThemeName=adw-gtk3` and `VariantThemeName=adw-gtk3` (light, `src/theme-light/meson.build:2-6`) or `adw-gtk3-dark` (dark, `src/theme-dark/meson.build:2-6`). The template contains `[X-GNOME-Metatheme]`, `Name=`, `GtkTheme=`. `src/index.theme.in:1-6`
- AG4.7 GTK4 output (libadwaita side): the light install copies a checked-in set `gtk4/gtk.css`, `gtk4/gtk-dark.css`, `gtk4/libadwaita.css` into `<datadir>/themes/adw-gtk3/gtk-4.0/` (`src/theme-light/meson.build:49-51,65`). The dark theme meson reuses the same three files from the light directory (`src/theme-dark/meson.build:49-53`). The two `.css` entry files import `libadwaita.css` and `libadwaita-tweaks.css`. `src/theme-light/gtk4/gtk.css:1-2`
- AG4.8 `libadwaita-tweaks.css` is compiled from `sass/gtk4/libadwaita-tweaks.scss` with `$toolkit: 'gtk4'` and installed into `gtk-4.0/` (`src/theme-light/meson.build:55-62`, custom target `generate_libadwaita_tweaks_css`). The tweaks file overrides accent colors (`accent_bg_color @blue_3`, line 10) and declares `:root` CSS custom properties such as `--accent-blue`. `src/sass/gtk4/libadwaita-tweaks.scss:10-15`
- AG4.9 GTK4 assets: four SVG symbolic icons (`bullet`, `check`, `dash`, `devel`) are installed under `gtk-4.0/assets/`. `src/theme-light/meson.build:42-47,66`. The libadwaita.css references `assets/check-symbolic.svg` via `-gtk-recolor`. `src/theme-light/gtk4/libadwaita.css:586`
- AG4.10 GTK3 assets: the whole `src/assets/` directory is installed into `gtk-3.0/assets/`. `src/theme-light/meson.build:69`. Thumbnails are installed as `thumbnail.png` into `gtk-3.0/`. `src/theme-light/meson.build:70`
- AG4.11 Call chain, input to pixels (GTK3): Sass source -> `sass` compiler -> `gtk-3.0/gtk.css` (named color definitions with `@define-color`, plus widget rules) -> GTK3 CSS provider resolves `@name` references at load time. The mechanism that resolves `@name` is GTK's own CSS engine; this repo does not contain it (UNVERIFIED in this repo, standard GTK behavior).
- AG4.12 No GTK2 output is produced. The README lists a separate project for GTK2 (`adw-gtk2-colorizer`). `README.md:142`

## 5. Extension and integration points
- AG5.1 No plugin interface. Extension is through GTK named colors: apps and user CSS can override `@accent_bg_color` and other names exported by the `@define-color` lines (see section 3). `README.md:121-122`
- AG5.2 Install location for each variant: `<datadir>/themes/adw-gtk3/` (light) and `<datadir>/themes/adw-gtk3-dark/` (dark), each with `index.theme`, `gtk-3.0/`, `gtk-4.0/`. `src/meson.build:1-2,4-8`
- AG5.3 GTK version coupling: GTK3 CSS (`gtk-3.0/`) and GTK4 CSS (`gtk-4.0/`) are separate files. The GTK4 set is a copy of libadwaita CSS, so it is tied to the libadwaita version it was copied from. The version of that copy is not stated in the repo (UNVERIFIED).
- AG5.4 Discovery: the theme is found by name under `themes/` by GTK. The `index.theme` `GtkTheme=` key carries the theme name. `src/index.theme.in:6`
- AG5.5 Flatpak and snap packages exist for the theme. `README.md:59-83`. Flatpak note: the GTK4 variant does not work with non-libadwaita GTK4 apps; the README says installing into `~/.local/share/themes` helps. `README.md:63,70`

## 6. Data and tooling
- AG6.1 Sass sources: `src/sass/` (entry, partials, `widgets/` with one file per widget family). Scope: 36 widget partial files under `src/sass/widgets/` (`rg --files src/sass/widgets`).
- AG6.2 Assets: `src/assets/` (SVG and PNG, `@2` for HiDPI, `-dark` for dark). `src/assets.txt` lists base names used for installation/reference.
- AG6.3 Build: Meson (`meson.build`, `src/meson.build`, `src/theme-light/meson.build`, `src/theme-dark/meson.build`), Ninja, dart-sass. `src/README.md:7-10`
- AG6.4 Packaging: `snap/snapcraft.yaml`. Distribution packages named in the README: Fedora `adw-gtk3-theme`, Arch `adw-gtk-theme`, Manjaro `adw-gtk3`. `README.md:50-52`
- AG6.5 Tests: none found in the repo (`rg --files` shows none).

## 7. Facts of note
- AG7.1 README caveat: the port does not look identical to libadwaita because GTK3 cannot do everything libadwaita does. `README.md:6`
- AG7.2 Comment in `_palette.scss`: Sass may warn about using color variables as strings; the code uses `#{"" + $var}` to avoid the warning. `src/sass/_palette.scss:47-48`
- AG7.3 Comment in `_defaults.scss`: using too many transparent colors in GTK3 is expensive and can break some elements; static colors are used for common elements. `src/sass/_defaults.scss:16-18`
- AG7.4 Issue reference in the GTK4 tweaks: accent override is for issue 272 of the upstream repo. `src/sass/gtk4/libadwaita-tweaks.scss:9`
- AG7.5 Comment: GTK4 tweaks are "not for libadwaita apps". `src/sass/gtk4/libadwaita-tweaks.scss:2`
- AG7.6 Flatpak masking: the README says to mask the Flatpak theme to avoid conflicts. `README.md:74-75`
- AG7.7 License: LGPL-2.1. `LICENSE:1-2`

## 8. Not covered
- The `src/sass/widgets/*.scss` partials were listed but not read individually; widget-level selector content is not described here.
- The checked-in `src/theme-light/gtk4/libadwaita.css` (about 600+ lines) was sampled at one line only; its origin (which libadwaita version, whether generated elsewhere) is UNVERIFIED.
- `src/sass/_common.scss`, `_drawing.scss`, `_apps.scss`, `_libhandy.scss`, `_libgranite.scss`, `_modules.scss` were not read.
- Build was not run. No output was verified.

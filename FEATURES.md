# Features

Format: `feature — system`

This list records approved scope; it does not claim that every feature is shipped.

## Shell

- top bar — Quickshell QML
- application launcher — Quickshell desktop-entry catalog, QML search, and app2unit systemd user services
- workspace indicator and switching — Quickshell Hyprland integration and Hyprland Lua
- active window title — Quickshell Hyprland integration
- system tray — Quickshell QML and StatusNotifierItem
- clock and date — Quickshell QML
- keyboard layout indicator — Quickshell Hyprland integration
- battery indicator — Quickshell QML and UPower
- volume control — Quickshell QML and PipeWire/WirePlumber
- media controls — Quickshell QML and MPRIS
- brightness control — Quickshell QML and brightnessctl
- notification system — Quickshell notification server and QML notification store
- notification grouping — QML notification store
- notification idle mode and DND — QML notification store and hypridle state
- clipboard history — cliphist store (memory-only), Quickshell panel, wl-copy
- menu for other programs (dmenu-style, one tab per calling app) — `scripts/menu` client, request spool under the runtime directory, Quickshell QML
- session menu — Quickshell QML and systemd-login
- lock screen trigger — hyprlock
- contextual information popup (Ctrl+I) for the focused target, selected app, or wallpaper — Quickshell QML
- component usage and keybind popup (Ctrl+Space) — Quickshell QML
- component-scoped settings popup (Ctrl+E), backed by focused Bash persistence and QML configuration; optional per-monitor files — Quickshell QML and focused Bash scripts
- component-scoped `ErrorPopup.qml` with action-specific operation, message, target and details; backend failure signals present one popup per new failure — Quickshell QML and native read-only, selectable, scrollable plain-text diagnostics with explicit Copy

## Visuals and themes

- static wallpapers from an explicit folder list — `config.ini` named folders, Hyprpaper, Lua folder-ID/filename selections, and generated QML/Lua palettes
- wallpaper-to-theme draft flow across configured folders — Quickshell QML, durable profile recipe, Hyprpaper, and final Save and apply
- wallpaper color generation — matugen and Bash scripts
- generated shell theme — explicit generated QML palette and focused Bash renderers
- Theme palette definitions — one schema-2 `config.ini` per Theme with `[palette]` shell roles, complete `[colors]` slots and native `[hyprland]` border expressions under configured `paths.themes`
- lossless theme colors — named and bright slots retained across import, preview, editing, save and restart; native Hyprland gradient stops, opacity and angle preserved
- committed Theme profiles — self-contained schema-2 XDG-config recipes with complete colors, wallpaper choices, optional named Theme identity and scoped overrides; final Save and apply commits and activates
- complete compiled profile bundles — keyed XDG-cache generations with checksummed palette, QML, Hyprland and wallpaper projections; configured native renderers and optional GTK/Qt targets
- preview-first Theme editor — select a Theme palette or wallpaper-derived colors for the draft; only final Save and apply creates or updates the committed profile
- configurable Ctrl+Enter primary actions for focused popups — shared `config/Keyboard.qml` policy; explicit action per popup, with disabled/busy blocking and no parent key leakage
- live profile and wallpaper colors — native QML snapshot loaders and `ActivePalettes`, with explicit global Hyprland palette generation; no custom IPC
- offline reference-theme port — regenerates matching reference Theme IDs with explicit status mappings; unrelated/custom Themes and all profile recipes untouched; no profile compilation or activation
- per-monitor wallpaper selection — recipe selections, Hyprpaper, XDG cache palettes, and Quickshell QML
- animated shell transitions — Quickshell QML animations

## Capture and input

- screenshots — grim and slurp
- screen recording — gpu-screen-recorder
- region selection — slurp
- clipboard history — wl-clipboard and cliphist
- text extraction from screenshots — grim, slurp, and tesseract

## Hyprland integration

- monitor-aware shell surfaces — Quickshell QML and Hyprland Lua
- window rules — Hyprland Lua
- optional persistent floating/panning canvas with per-output themed HUD and minimap — Phantomat, native Lua settings and the existing generated output palette index; explicit default for unassigned displays
- optional per-workspace overview restoration (camera, zoom, search and selection; compositor-session only) — Phantomat `canvas.remember_overview` and explicit user Lua configuration
- keybinds — Hyprland Lua
- autostart — Hyprland Lua
- idle and suspend policy — hypridle
- screen sharing indicators — Quickshell QML and Wayland portal state

## Composition and configuration

- standard XDG runtime layout with explicit paths and command roles — `$XDG_CONFIG_HOME/ui-shell/config.ini` and generated native QML/Lua projections
- declarative module enablement — Quickshell QML and shell configuration
- configurable bar composition — Quickshell QML
- per-monitor overrides — shell configuration
- centralized design tokens — Quickshell QML theme singleton
- generated color intermediate — focused Bash scripts; `UI_SHELL_RUNTIME` supplies Bash with resolved JSON, while Quickshell consumes native generated QML and never reads JSON as configuration

## Explicitly out of scope for now

- weather service — not planned
- system monitor or btop-style panel — not planned
- full settings application — not planned
- network management UI — not planned
- Bluetooth management UI — not planned
- application/plugin marketplace — not planned
- custom daemon — not planned
- custom IPC protocol — not planned
- custom shell CLI — not planned

## Development tests

- isolated nested session — Bubblewrap, private HOME/XDG directories, private D-Bus, and freshly staged `ui-shell` runtime code
- explicit test resource policy — user-owned `tests/nested.conf`
- checked nested startup and shutdown — native compositor diagnostics, captured frame, protected host-file hashes, and test-child cleanup checks

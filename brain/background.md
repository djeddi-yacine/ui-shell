---
slug: background
title: Project background
role: project background
updated: "2026-09-30T19:32:32"
---

# Project background

This is a focused, greenfield Wayland shell for Hyprland and Quickshell.

The project is intentionally a configurable visual shell, not a general desktop environment. Features are controlled through `FEATURES.md` before implementation so the scope stays deliberate and bloat-free.

The implementation boundaries are explicit: Hyprland configuration belongs in `hypr/` and uses Lua; Quickshell UI belongs in `shell/` and uses QML; external system effects belong in `scripts/` and use Bash.

The shell has no custom daemon, IPC protocol, or CLI. Shared generated state is file-based, produced by small scripts for concerns such as colors and wallpaper changes, then consumed by QML.

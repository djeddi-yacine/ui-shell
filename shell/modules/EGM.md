# modules

## Overview
Feature modules of the shell. Each module is a QML package (`UiShell.*`) with a singleton state object, a `GlobalShortcut`, a per-output layer-shell surface and a panel. `bar` has no qmldir and is consumed by relative import.

## Subdirectories & Boundaries
- apps: [./apps/EGM.md](./apps/EGM.md) - application launcher
- audio: [./audio/EGM.md](./audio/EGM.md) - audio control and patchbay
- clipboard: [./clipboard/EGM.md](./clipboard/EGM.md) - clipboard history panel over cliphist
- menu: [./menu/EGM.md](./menu/EGM.md) - program menu: a card that other programs call through `scripts/menu` to choose a line
- record: [./record/EGM.md](./record/EGM.md) - screen recording panel (target, audio, countdown, Start)
- shot: [./shot/EGM.md](./shot/EGM.md) - screenshot panel (target, clipboard or file, Capture)
- bar: [./bar/EGM.md](./bar/EGM.md) - per-output bar
- themes: [./themes/EGM.md](./themes/EGM.md) - theme/palette editor
- tuning: [./tuning/EGM.md](./tuning/EGM.md) - control tuning panel
- wallpaper: [./wallpaper/EGM.md](./wallpaper/EGM.md) - wallpaper picker
- `auth/`: the polkit authentication dialog (see `auth/EGM.md`).
- `mpris/`: the media control (see `mpris/EGM.md`).

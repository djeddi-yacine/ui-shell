# modules

## Overview
Feature modules of the shell. Each module is a QML package (`UiShell.*`) with a singleton state object, a `GlobalShortcut`, a per-output layer-shell surface and a panel. `bar` has no qmldir and is consumed by relative import.

## Subdirectories & Boundaries
- apps: [./apps/EGM.md](./apps/EGM.md) - application launcher
- audio: [./audio/EGM.md](./audio/EGM.md) - audio control and patchbay
- bar: [./bar/EGM.md](./bar/EGM.md) - per-output bar
- themes: [./themes/EGM.md](./themes/EGM.md) - theme/palette editor
- tuning: [./tuning/EGM.md](./tuning/EGM.md) - control tuning panel
- wallpaper: [./wallpaper/EGM.md](./wallpaper/EGM.md) - wallpaper picker

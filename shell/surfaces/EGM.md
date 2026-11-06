# surfaces

## Overview
Layer-shell windows hosting shell UI. Currently only the top bar surface.

## Interface
- `BarSurface` [BarSurface.qml:BarSurface]: `PanelWindow` with `modelData` (screen) and required `inputState` (`Controls.InputState`); hosts `BarModule.Bar` with `screenName: modelData.name`. Anchored top/left/right, height `Config.Config.barHeight`.

## Invariants
- `visible` follows `Config.Config.barEnabled`; `exclusiveZone` is `implicitHeight` when visible else 0, `exclusionMode` Auto/Ignore accordingly [BarSurface.qml:exclusiveZone, exclusionMode].
- Layer is `WlrLayer.Top`, namespace `ui-shell-bar`, `color: "transparent"` [BarSurface.qml:WlrLayershell.namespace, WlrLayershell.layer].

## Side Effects
- Reserves screen edge space on Wayland via wlr-layer-shell exclusive zone [BarSurface.qml:exclusiveZone].

## Verification
- Run: `make test-qml`

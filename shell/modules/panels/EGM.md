# panels (Panel exclusion policy)

## Overview
Owns the rule "which panels may be open together". Package URI `UiShell.Panels` ([panels/qmldir]). Panels know nothing about each other; `shell/shell.qml` lists them in groups.

## Interface
- `PanelGroup`: `panels` (objects with a writable boolean `open`), `closeOthers(opener)` [panels/PanelGroup.qml:PanelGroup]

## Invariants
- Of the panels in one group at most one has `open == true`: setting a member's `open` to true sets every other member's to false [panels/PanelGroup.qml:closeOthers].
- Closing a member opens nothing. A panel in no group, or in another group, is never touched, so coexistence is a different list, not a flag.
- A new panel joins by adding its state to the list in `shell/shell.qml`; no other panel changes.

## Side Effects
- Writes `open = false` on the other members. No timers, files or processes.

## Verification
- Run: `make test-qml` (`tests/tst_PanelGroup.qml`)

# Qt

Qt-specific theme integration belongs here.

The implementation should consume the shared style vocabulary from [`STYLE.md`](../STYLE.md) and avoid defining an independent color, shape, or typography system.

The active contract is rectangular controls and windows with zero corner radius, visible keyboard focus, and short interruptible motion. QML shell controls explicitly use Qt Quick Controls Basic with project-owned backgrounds; application-wide Qt theme output is not implemented yet.

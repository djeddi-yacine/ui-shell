pragma Singleton
import QtQuick

// Where a panel card spawns. One rule for every panel; each panel's config
// names its own mode (`placement`), so any panel can be moved on its own.
QtObject {
    // "center" | "top" (under the bar) | "bottom" (above the screen edge).
    readonly property string defaultMode: "center"

    // The card's y inside a panel surface of `areaHeight`.
    function y(mode, areaHeight, cardHeight, barHeight, margin) {
        if (mode === "top")
            return barHeight + margin
        if (mode === "bottom")
            return areaHeight - cardHeight - margin
        return Math.round((areaHeight - cardHeight) / 2)
    }
}

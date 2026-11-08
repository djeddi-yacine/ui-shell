import QtQuick
import QtQml.Models

// One exclusion policy: of the panels listed here at most one is open. Opening a member
// closes every other member. A panel in no group (or in another group) is untouched, so
// a coexistence rule is a different list, not a flag on the panel. Declare one per policy.
QtObject {
    id: root
    // Objects with a writable boolean `open` (the panel state singletons).
    property var panels: []

    function closeOthers(opener) {
        for (const panel of root.panels) {
            if (panel !== opener && panel.open) panel.open = false
        }
    }

    property Instantiator links: Instantiator {
        model: root.panels
        delegate: Connections {
            id: link
            required property var modelData
            target: link.modelData
            function onOpenChanged() { if (link.modelData.open) root.closeOthers(link.modelData) }
        }
    }
}

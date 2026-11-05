pragma Singleton
import QtQuick

// The live control-colour model. Defaults come from GeneratedControlTuning
// (rendered by scripts/render-control-tuning, which owns the schema), a saved
// user file layers on top, and the tuning panel's unsaved draft on top of that,
// so every control recolours while a slider moves. Nothing here is hand-edited.
QtObject {
    readonly property var schema: GeneratedControlTuning.schema
    readonly property var defaults: GeneratedControlTuning.values
    // Named presets (tonal, wash, ...) over the knobs, and the one the saved file uses.
    readonly property var modes: GeneratedControlTuning.modes
    property string mode: GeneratedControlTuning.mode
    // Values a mode produces: generated defaults with the mode's preset on top.
    function presetValues(key) {
        const entry = modes.find(item => item.key === key)
        return Object.assign({}, defaults, entry ? entry.values : {})
    }
    // The mode in effect: the panel's draft while it previews, else the saved one.
    property string draftMode: ""
    readonly property string activeMode: draftMode.length > 0 ? draftMode : mode
    // What controls do in that mode: per-state fill/foreground/border roles and flags.
    readonly property var behavior: (modes.find(entry => entry.key === activeMode) ?? modes[0]).behavior
    // Saved overrides (set by the control-tuning adapter from the user's file).
    property var overrides: ({})
    // Unsaved preview from the tuning panel; empty when it is not editing.
    property var draft: ({})
    readonly property var values: Object.assign({}, defaults, overrides, draft)
}

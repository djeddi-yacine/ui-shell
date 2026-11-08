pragma Singleton
import QtQuick

// The control-colour tuning panel: its own surface, like the launcher and the picker.
QtObject {
    // Spawn position: "center", "top" (under the bar) or "bottom".
    readonly property string placement: Placement.defaultMode
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "control-tuning"
    readonly property bool asynchronousPanelLoad: true
    readonly property int maximumWidth: 860
    readonly property int outerMargin: 24
    // The width of a knob's name, so the sliders line up.
    readonly property int labelWidth: 170
}

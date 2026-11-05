pragma Singleton
import QtQuick

// The control-colour tuning panel: its own surface, like the launcher and the picker.
QtObject {
    readonly property string shortcutAppId: "ui-shell"
    readonly property string shortcutName: "control-tuning"
    readonly property int maximumWidth: 860
    readonly property int outerMargin: 24
}

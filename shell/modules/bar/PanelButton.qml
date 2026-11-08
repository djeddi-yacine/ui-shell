import QtQuick
import "../../components" as Controls
import "../../theme" as Theme

// A labelled bar button that toggles one panel on this output. `panelState` is the panel's
// state singleton: it has `open`, `screenName` and `show(output)`.
Controls.ShellButton {
    id: root
    required property string screenName
    required property var panelState
    emphasis: Theme.Interaction.barEntryEmphasis
    selected: panelState.open && panelState.screenName === screenName
    Accessible.name: text
    onClicked: {
        if (selected) panelState.open = false
        else panelState.show(screenName)
    }
}

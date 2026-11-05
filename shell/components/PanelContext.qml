pragma ComponentBehavior: Bound
import QtQuick
import "../adapters" as Adapters
import "../config" as Config

ContextPopup {
    id: root
    required property Adapters.ComponentSettings settings
    property string infoTitle: ""
    property string infoDescription: ""
    property var infoDetails: []
    required property var bindings
    readonly property ComponentSettingsEditor editor: kind === "settings" && pane.status === Loader.Ready
        ? pane.item as ComponentSettingsEditor : null
    primaryAction: editor ? editor.primaryAction : null
    objectName: "panelContext"

    contentItem: FocusScope {
        id: body
        implicitHeight: pane.implicitHeight
        focus: true
        // Unhandled popup keys stop here, never at the panel's launch/apply handler.
        Keys.onPressed: event => {
            root.inputState.keyboardUsed()
            if (!root.handleShortcut(event) && event.key === Config.Keyboard.cancelKey) root.close()
            event.accepted = true
        }
        Loader {
            id: pane
            width: parent.width
            active: root.visible
            sourceComponent: root.kind === "settings" ? settingsPane : root.kind === "help" ? helpPane : infoPane
            onLoaded: Qt.callLater(function() {
                if (root.editor) root.editor.begin()
                else body.forceActiveFocus()
            })
        }
    }
    Component {
        id: settingsPane
        ComponentSettingsEditor {
            settings: root.settings
            style: root.style
            inputState: root.inputState
            onSaved: root.close()
        }
    }
    Component {
        id: helpPane
        ContextHelp { style: root.style; bindings: root.bindings }
    }
    Component {
        id: infoPane
        ContextDetails { style: root.style; title: root.infoTitle; description: root.infoDescription; details: root.infoDetails }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../adapters" as Adapters
import "../config" as Config

ContextPopup {
    id: root
    // Null for a panel without component settings (its own controls are the settings).
    property Adapters.ComponentSettings settings: null
    property string infoTitle: ""
    property string infoDescription: ""
    property var infoDetails: []
    required property var bindings
    readonly property ComponentSettingsEditor editor: kind === "settings" && pane.status === Loader.Ready
        ? pane.item as ComponentSettingsEditor : null
    primaryAction: editor ? editor.primaryAction : null
    objectName: "panelContext"
    // Unsaved settings: only the exit dialog may close this popup (see STYLE.md).
    readonly property bool unsaved: editor !== null && editor.dirty
    closePolicy: unsaved ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    ExitDialog {
        id: exit
        owner: root.owner
        style: root.style
        inputState: root.inputState
        message: qsTr("Your settings are not saved.")
        onConfirmed: root.close()
    }

    contentItem: FocusScope {
        id: body
        implicitHeight: pane.implicitHeight
        focus: true
        // Unhandled popup keys stop here, never at the panel's launch/apply handler.
        Keys.onPressed: event => {
            root.inputState.keyboardUsed()
            if (!root.handleShortcut(event) && event.key === Config.Keyboard.cancelKey)
                exit.request(root.unsaved, root.Window.window ? root.Window.window.activeFocusItem : null)
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

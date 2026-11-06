pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config

Controls.ContextPopup {
    id: root
    objectName: "themeEditorPopup"
    required property string screenName
    property string targetOutput: ""
    property var wallpaperSelection: null
    signal applied()
    readonly property ThemeEditor editor: editorBody
    readonly property Adapters.ThemeProfiles profileModel: profiles
    readonly property Controls.ErrorPopup errorPopup: failures
    primaryAction: root.editor.primaryAction
    property var focusedInformation: ({ title: "", description: "", details: [] })
    shortcutsEnabled: false
    width: Math.max(0, Math.min(owner.width - Config.ContextPanels.outerMargin * 2, Config.ThemeEditor.maximumWidth))
    height: Math.max(0, Math.min(implicitHeight, owner.height - Config.ThemeEditor.verticalMargin * 2,
        Config.ThemeEditor.maximumHeight))
    // With unsaved edits only the dialog below may close it, so a stray Esc or click loses nothing.
    closePolicy: profiles.busy || root.editor.dirty ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: root.editor.begin(root.wallpaperSelection)
    onClosed: { colorContext.close(); root.editor.colorPicker.close(); failures.close() }

    function begin(selection, previousFocus) {
        wallpaperSelection = Object.assign({}, selection)
        targetOutput = selection.id
        show("theme", previousFocus)
    }
    function resetDraft() {
        close()
        profiles.reset()
        root.editor.resetDraft()
        wallpaperSelection = null
    }

    function disclose(kind) {
        root.inputState.keyboardUsed()
        root.focusedInformation = root.editor.focusedInfo()
        colorContext.show(kind, root.owner.Window.window.activeFocusItem)
    }
    function handleKey(event) {
        if (event.key === Config.Keyboard.cancelKey) {
            if (failures.visible) failures.close()
            else if (root.editor.colorPicker.visible) root.editor.colorPicker.requestClose()
            else if (colorContext.visible) colorContext.close()
            else if (exit.visible) exit.confirm()
            else if (!profiles.busy) exit.request(root.editor.dirty, root.owner.Window.window.activeFocusItem)
        } else if (failures.visible && event.key === Config.ErrorPanels.copyKey
            && event.modifiers === Config.ErrorPanels.copyModifiers) failures.copyDiagnostic()
        event.accepted = true
    }
    Adapters.ThemeProfiles {
        id: profiles
        screenName: root.screenName
        onFailed: failure => failures.present(failure, root.owner.Window.window.activeFocusItem)
    }
    contentItem: Item {
        id: popupContent
        Keys.onPressed: event => { if (event.key === Config.Keyboard.cancelKey) handleKey(event) }
        implicitHeight: editorBody.implicitHeight
        ThemeEditor {
            id: editorBody
            anchors.fill: parent
            profileModel: profiles
            style: root.style
            inputState: root.inputState
            screenName: root.screenName
            onSaved: { root.close(); root.applied() }
            onBack: root.close()
        }
    }
    Controls.ExitDialog {
        id: exit
        owner: root.editor
        style: root.style
        inputState: root.inputState
        message: qsTr("Your color edits are not applied.")
        onConfirmed: root.close()
    }
    Controls.ErrorPopup {
        id: failures
        owner: root.editor
        style: root.style
        inputState: root.inputState
    }
    Controls.ContextPopup {
        id: colorContext
        owner: root.editor
        style: root.style
        inputState: root.inputState
        shortcutsEnabled: false
        contentItem: Loader {
            sourceComponent: colorContext.kind === "help" ? help : information
        }
    }
    Component {
        id: information
        Controls.ContextDetails {
            style: root.style
            title: root.focusedInformation.title
            description: root.focusedInformation.description
            details: root.focusedInformation.details
        }
    }
    Component {
        id: help
        Controls.ContextHelp {
            style: root.style
            bindings: [
                { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
                { key: Qt.Key_Tab, modifiers: Qt.ShiftModifier, action: qsTr("Previous control") },
                { key: Config.Keyboard.applyKey, modifiers: Qt.NoModifier, action: qsTr("Activate focused button") },
                ...Config.Keyboard.popupActionKeys.map(key => ({ key: key, modifiers: Config.Keyboard.popupActionModifiers, action: qsTr("Save and apply the draft") })),
                { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Explain focused control or color") },
                { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Return without applying; closing the picker discards the draft") }
            ]
        }
    }
    Item {
        parent: popupContent
        Shortcut {
            sequence: Config.Keyboard.shortcut(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
            context: Qt.WindowShortcut
            enabled: root.visible && !failures.visible && !root.editor.colorPicker.visible && !colorContext.visible
            onActivated: root.disclose("info")
        }
        Shortcut {
            sequence: Config.Keyboard.shortcut(Config.Keyboard.helpKey, Config.Keyboard.contextModifiers)
            context: Qt.WindowShortcut
            enabled: root.visible && !failures.visible && !root.editor.colorPicker.visible && !colorContext.visible
            onActivated: root.disclose("help")
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// The control-colour tuning panel: a card on a dimmed backdrop, placed by Config.Placement.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    readonly property Item cardItem: card
    signal closed()

    function activate() {
        editor.begin()
        motion.enter()
        // The window is not yet active here, so focus the first control once it is.
        Qt.callLater(editor.focusFirst)
    }
    function requestClose() {
        editor.discard()
        motion.leave()
    }
    function showContext(kind) {
        if (kind === "info") {
            context.infoTitle = qsTr("Control tuning")
            context.infoDescription = qsTr("A mode sets how controls look and behave; the sliders fine-tune it. Changes preview live on every control. Save keeps them, Esc discards.")
            context.infoDetails = [
                { label: qsTr("Mode"), value: editor.modeEntry ? editor.modeEntry.label : "" },
                { label: qsTr("Modified"), value: editor.modified ? qsTr("Yes") : qsTr("No") },
                { label: qsTr("Behavior"), value: editor.behaviorSummary }
            ]
        }
        // Control tuning has no component settings: its sliders are the settings.
        if (kind === "settings") return
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Keys.onPressed: event => {
        inputState.keyboardUsed()
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === Config.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        // Esc leaves; with unsaved tuning it asks first, and a second Esc confirms.
        if (event.key === Config.Keyboard.cancelKey) { exit.request(editor.dirty, root.Window.window ? root.Window.window.activeFocusItem : null); event.accepted = true }
    }
    Component.onCompleted: { if (visible) activate() }
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Controls.ExitDialog {
        id: exit
        owner: root
        style: styleTokens
        inputState: root.inputState
        message: qsTr("Your tuning changes are not saved.")
        onConfirmed: root.requestClose()
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: null
        bindings: [
            { key: Qt.Key_Left, modifiers: Qt.NoModifier, action: qsTr("Lower the focused value") },
            { key: Qt.Key_Right, modifiers: Qt.NoModifier, action: qsTr("Raise the focused value") },
            { key: Qt.Key_Return, modifiers: Qt.NoModifier, action: qsTr("Choose a mode, reset, or save") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("What this panel does") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then close; with unsaved changes a second Esc confirms") }
        ]
        onRequested: kind => root.showContext(kind)
    }

    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(Config.ContextPanels.scrimOpacity)
        // Same rule as Esc: unsaved tuning asks first.
        MouseArea { anchors.fill: parent; onClicked: exit.request(editor.dirty, null) }
    }
    Rectangle {
        id: card
        width: Math.min(root.width - Config.Tuning.outerMargin * 2, Config.Tuning.maximumWidth)
        height: editor.implicitHeight + Config.ContextPanels.padding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.Placement.y(Config.Tuning.placement, root.height, card.height, styleTokens.barHeight, Config.Tuning.outerMargin)
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        transform: Translate { y: motion.offset }

        Controls.ControlTuningEditor {
            id: editor
            x: Config.ContextPanels.padding
            y: Config.ContextPanels.padding
            width: card.width - Config.ContextPanels.padding * 2
            style: styleTokens
            inputState: root.inputState
            store: Adapters.ControlTuningStore
            onSaved: motion.leave()
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import "../../adapters" as Adapters
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// The media panel's window content, in the shape of ShotPanel: the dimming, the context popups
// (keys, information, settings), the saved settings for this output, and the card. The card holds
// everything that is shown and every key; it is tested on its own.
FocusScope {
    id: root
    required property string screenName
    required property Controls.InputState inputState
    property bool open: false
    signal closed()
    readonly property int seekStep: options.option("seekStep")
    readonly property string artMode: options.option("artMode")
    readonly property var player: MprisState.selection.current
    readonly property Controls.PanelContext contextPopup: context

    function activate() {
        failures.close()
        context.close()
        options.refresh()
        motion.enter()
        Qt.callLater(focusCard)
    }
    function focusCard() { card.forceActiveFocus() }
    function showContext(kind) {
        if (failures.visible) return
        if (kind === "info") {
            const selection = MprisState.selection
            context.infoTitle = qsTr("Media control")
            context.infoDescription = qsTr("Controls the player you pin, otherwise the one that is playing, otherwise the last one that played. The media keys act on the same player.")
            context.infoDetails = [
                { label: qsTr("Player"), value: root.player ? root.player.identity : qsTr("none") },
                { label: qsTr("Pin"), value: selection.pinState === "none" ? qsTr("none") : selection.pinKey },
                { label: qsTr("Art"), value: root.artMode !== "auto" ? root.artMode : (root.player ? (Config.Mpris.artModes[selection.keyOf(root.player)] ?? Config.Mpris.artDefaultMode) : Config.Mpris.artDefaultMode) }
            ]
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    function requestClose() { motion.leave() }

    Keys.onPressed: event => {
        inputState.keyboardUsed()
        if (failures.visible) {
            if (event.key === Config.ErrorPanels.dismissKey) failures.close()
            event.accepted = true
            return
        }
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === Config.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        if (event.key === Config.Mpris.panelKeys.close) { requestClose(); event.accepted = true }
    }
    Component.onCompleted: { if (open) activate() }
    onOpenChanged: if (open) activate()
    Theme.MonitorStyle { id: styleTokens; palette: Theme.ActivePalettes.forOutput(root.screenName) }
    Controls.PointerTracker { inputState: root.inputState }
    Controls.PanelMotion { id: motion; surface: root; onClosed: root.closed() }
    Adapters.ComponentSettings {
        id: options
        component: "mpris"
        screenName: root.screenName
        onFailed: failures.present(options.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    // The open panel gives the state its art mode (several panels exist, one per output;
    // only the open one writes) and reports art faults through its error popup.
    Binding { target: MprisState; property: "artMode"; value: root.artMode; when: root.open }
    Connections {
        target: MprisState.art
        function onFaultReported(failure) {
            if (root.open) failures.present(failure, root.Window.window ? root.Window.window.activeFocusItem : null)
        }
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: options
        shortcutsEnabled: !failures.visible
        bindings: [
            { key: Config.Mpris.panelKeys.playPause, modifiers: Qt.NoModifier, action: qsTr("Play or pause") },
            { key: Config.Mpris.panelKeys.next, modifiers: Qt.NoModifier, action: qsTr("Next track") },
            { key: Config.Mpris.panelKeys.previous, modifiers: Qt.NoModifier, action: qsTr("Previous track") },
            { key: Config.Mpris.panelKeys.seekBack, modifiers: Qt.NoModifier, action: qsTr("Seek back") },
            { key: Config.Mpris.panelKeys.seekForward, modifiers: Qt.NoModifier, action: qsTr("Seek forward") },
            { key: Config.Mpris.panelKeys.pin, modifiers: Qt.NoModifier, action: qsTr("Pin or unpin the shown player") },
            { key: Config.Mpris.panelKeys.playerPrevious, modifiers: Qt.NoModifier, action: qsTr("Show the previous player") },
            { key: Config.Mpris.panelKeys.playerNext, modifiers: Qt.NoModifier, action: qsTr("Show the next player") },
            { key: Config.Keyboard.infoKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Media information") },
            { key: Config.Keyboard.helpKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: Config.Keyboard.settingsKey, modifiers: Config.Keyboard.contextModifiers, action: qsTr("Component settings") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then close panel") }
        ]
        onRequested: kind => root.showContext(kind)
    }
    Controls.ErrorPopup {
        id: failures
        owner: root
        style: styleTokens
        inputState: root.inputState
    }

    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(Config.ContextPanels.scrimOpacity)
        MouseArea { anchors.fill: parent; onClicked: root.requestClose() }
    }
    MprisCard {
        id: card
        width: Math.min(root.width - Config.Mpris.outerMargin * 2, Config.Mpris.panelSize)
        height: width
        y: styleTokens.barHeight + Config.Mpris.outerMargin
        anchors.horizontalCenter: parent.horizontalCenter
        selection: MprisState.selection
        art: MprisState.art
        seekStep: root.seekStep
        style: styleTokens
        inputState: root.inputState
        active: root.open
        transform: Translate { y: motion.offset }
        MouseArea { anchors.fill: parent; z: -1 }
    }
}

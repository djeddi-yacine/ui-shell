pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

ContextPopup {
    id: root
    objectName: "errorPopup"
    kind: "error"
    shortcutsEnabled: false
    z: 2
    width: Math.max(0, Math.min(owner.width - Config.ContextPanels.outerMargin * 2,
        Config.ErrorPanels.maximumWidth))
    property var failure: null
    property var seenSequences: ({})
    property bool copied: false
    primaryAction: dismiss
    readonly property TextArea diagnosticsControl: pane.status === Loader.Ready ? pane.item as TextArea : null
    readonly property string details: failure ? [
        qsTr("Operation: %1").arg(failure.operation),
        qsTr("Target: %1").arg(failure.target), failure.details
    ].filter(value => value.length > 0).join("\n\n") : ""
    readonly property string diagnostic: failure ? [failure.title, failure.message, details].join("\n\n") : ""
    signal copiedDiagnostic()

    function present(nextFailure, previousFocus) {
        if (!nextFailure || !nextFailure.source || !Number.isInteger(nextFailure.sequence) || nextFailure.sequence < 1
            || !nextFailure.title || !nextFailure.message || !nextFailure.operation || !nextFailure.target
            || typeof nextFailure.details !== "string")
            throw new Error("Error presentation requires an explicit failure, operation and target")
        if (nextFailure.sequence <= (seenSequences[nextFailure.source] || 0)) return false
        seenSequences = Object.assign({}, seenSequences, { [nextFailure.source]: nextFailure.sequence })
        failure = Object.assign({}, nextFailure)
        copied = false
        show("error", previousFocus)
        return true
    }
    function copyDiagnostic() {
        if (!visible || !failure) return
        // Native Qt clipboard copy; the full transcript includes the title/message.
        transcript.selectAll()
        transcript.copy()
        transcript.deselect()
        copied = true
        copiedDiagnostic()
    }
    onOpened: {
        if (Config.ErrorPanels.initialFocus === "dismiss") dismiss.forceActiveFocus()
        else if (Config.ErrorPanels.initialFocus === "copy") copy.forceActiveFocus()
        else throw new Error("Unknown ErrorPanels.initialFocus: " + Config.ErrorPanels.initialFocus)
    }
    TextEdit {
        id: transcript
        visible: false
        readOnly: true
        textFormat: TextEdit.PlainText
        text: root.diagnostic
    }
    contentItem: FocusScope {
        id: body
        implicitHeight: layout.implicitHeight
        focus: true
        Keys.onPressed: event => {
            root.inputState.keyboardUsed()
            if (event.key === Config.ErrorPanels.dismissKey) root.close()
            else if (event.key === Config.ErrorPanels.copyKey && event.modifiers === Config.ErrorPanels.copyModifiers)
                root.copyDiagnostic()
            event.accepted = true
        }
        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: Config.ContextPanels.spacing
            Text {
                Layout.fillWidth: true
                text: root.failure ? root.failure.title : ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.Interaction.readable(root.style.negative, root.style.surfaceRaised,
                    Theme.Interaction.minimumTextContrast)
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
                font.weight: root.style.emphasisWeight
                Accessible.role: Accessible.Heading
            }
            Text {
                Layout.fillWidth: true
                text: root.failure ? root.failure.message : ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.Interaction.readable(root.style.text, root.style.surfaceRaised,
                    Theme.Interaction.minimumTextContrast)
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
            ScrollView {
                id: scroll
                objectName: "errorDetailsScroll"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Math.min(Config.ErrorPanels.maximumDetailsHeight, pane.implicitHeight)
                contentWidth: availableWidth
                clip: true
                focusPolicy: Qt.NoFocus
                background: Rectangle {
                    color: root.style.surface
                    radius: Theme.Shape.controlRadius
                    border.width: Theme.Shape.borderWidth
                    border.color: root.diagnosticsControl && root.diagnosticsControl.activeFocus
                        ? root.style.controls.focus : root.style.controls.outline
                }
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    implicitWidth: Config.ErrorPanels.scrollBarWidth
                    focusPolicy: Qt.NoFocus
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: root.style.controls.outline; radius: 0 }
                    background: Item {}
                }
                Loader {
                    id: pane
                    active: root.visible
                    width: scroll.availableWidth
                    sourceComponent: TextArea {
                        id: diagnostics
                        objectName: "errorDiagnostics"
                        ContextMenu.menu: ShellEditingMenu { editor: diagnostics; style: root.style }
                        readOnly: true
                        // Reading/selecting diagnostics must not add an action Tab stop.
                        focusPolicy: Qt.ClickFocus
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.PlainText
                        text: root.details
                        wrapMode: TextEdit.WrapAnywhere
                        padding: Config.ErrorPanels.detailsPadding
                        rightPadding: padding + Config.ErrorPanels.scrollBarWidth
                        color: root.style.controls.text
                        selectionColor: root.style.controls.selection
                        selectedTextColor: root.style.controls.primaryText
                        font.family: root.style.monoFamily
                        font.pointSize: root.style.captionPointSize
                        background: Item {}
                        Accessible.name: qsTr("Failure diagnostics")
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: event => {
                            root.inputState.keyboardUsed()
                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                const backwards = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)
                                // KeyNavigation links here would add implicit reverse
                                // links from the actions back into the diagnostics.
                                const action = backwards ? dismiss : copy
                                action.forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                                event.accepted = true
                            } else event.accepted = false
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Config.ContextPanels.spacing
                ShellButton {
                    id: copy
                    objectName: "errorCopy"
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    text: root.copied ? qsTr("Copied") : qsTr("Copy")
                    Accessible.name: qsTr("Copy complete error diagnostic")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.tab: dismiss
                    KeyNavigation.backtab: dismiss
                    onClicked: root.copyDiagnostic()
                }
                Item { Layout.fillWidth: true }
                ShellButton {
                    id: dismiss
                    objectName: "errorDismiss"
                    style: root.style
                    inputState: root.inputState
                    emphasis: Theme.Interaction.buttonEmphasis
                    text: qsTr("Dismiss")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.tab: copy
                    KeyNavigation.backtab: copy
                    onClicked: root.close()
                }
            }
        }
    }
}

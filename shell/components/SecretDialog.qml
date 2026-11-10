pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../config" as Config
import "../theme" as Theme

// A request for a secret: a message, the account it is for, one field, one status line. It
// is generic; it does not know where the request comes from.
//
// The field never shows the secret in any form. The characters live in a plain buffer that no
// Text, tooltip or accessible value reads, so nothing on screen reveals the characters, the
// length or even that a key arrived. The one exception is a prompt that asks for visible input
// (visibleEcho): that field shows what is typed. While the field has focus every printable key
// is part of the secret until Enter; Backspace empties it; Ctrl chords and paste are ignored.
FocusScope {
    id: root
    property var style: Theme.Style
    property string message: ""
    // Each entry is { id, label }.
    property var accounts: []
    property int selectedIndex: 0
    property string prompt: ""
    property bool visibleEcho: false
    property string info: ""
    property string error: ""
    property bool checking: false
    property bool failed: false
    property bool refused: false
    // The password was accepted: the lock shows as checked until the dialog closes.
    property bool succeeded: false
    property int guardMs: Config.Auth.inputGuardMs

    signal submitted(string secret)
    signal cancelled()
    signal accountChosen(int index)
    signal keyAfterFailure()

    // The buffer is private: only the visible-input field and submitted() ever read it.
    property string buffer: ""
    readonly property bool guarded: guard.running
    readonly property string accountLabel: accounts.length > selectedIndex && selectedIndex >= 0 ? accounts[selectedIndex].label : ""
    // What the field's label says: the state while there is one, otherwise what is being asked.
    // What the field says in place of the lock: a state, or the label of a visible-input prompt.
    // Empty for the ordinary hidden password prompt, which shows only the lock.
    readonly property string fieldText: failed ? Config.Auth.failedText
        : refused ? Config.Auth.refusedText
        : checking ? Config.Auth.checkingText
        : visibleEcho && prompt.length > 0 ? prompt.replace(/[:：]\s*$/, "") : ""
    readonly property bool fieldIsError: failed || refused
    // An information or error line from polkit, shown under the account.
    readonly property string notice: error.length > 0 ? error : info
    readonly property bool noticeIsError: error.length > 0

    implicitWidth: Config.Auth.cardWidth
    implicitHeight: card.implicitHeight
    focus: true
    Component.onCompleted: { forceActiveFocus(); restartGuard() }
    onPromptChanged: { buffer = ""; restartGuard() }
    onCheckingChanged: if (!checking) { buffer = ""; restartGuard() }
    onSelectedIndexChanged: buffer = ""

    // Called when the dialog is shown again: an empty field, a fresh guard, and the keyboard.
    function reset() {
        buffer = ""
        restartGuard()
        forceActiveFocus()
    }
    function restartGuard() {
        guard.interval = guardMs
        guard.restart()
    }
    Timer { id: guard; repeat: false }

    function isPrintable(text) {
        if (text.length === 0) return false
        const code = text.charCodeAt(0)
        return code >= 32 && code !== 127
    }

    Keys.onPressed: event => {
        event.accepted = true
        if (succeeded) return
        if (failed) { keyAfterFailure(); return }
        if (refused) { cancelled(); return }
        if (event.key === Qt.Key_Escape) { cancelled(); return }
        if (checking || guarded) return
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (buffer.length === 0) return
            const secret = buffer
            buffer = ""
            submitted(secret)
        } else if (event.key === Qt.Key_Backspace) {
            buffer = visibleEcho ? buffer.slice(0, -1) : ""
        } else if (event.key === Qt.Key_Left && buffer.length === 0 && accounts.length > 1) {
            accountChosen((selectedIndex + accounts.length - 1) % accounts.length)
        } else if (event.key === Qt.Key_Right && buffer.length === 0 && accounts.length > 1) {
            accountChosen((selectedIndex + 1) % accounts.length)
        } else if (isPrintable(event.text)) {
            buffer += event.text
        }
    }

    // An Item has no size of its own: without these it would be drawn at 0 x 0.
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: layout.implicitHeight + root.style.cardPadding * 3
        color: root.style.popupSurface
        radius: root.style.popupRadius
        border.width: Theme.Shape.borderWidth
        border.color: root.style.popupBorder
        Accessible.role: Accessible.Dialog
        Accessible.name: root.message

        ColumnLayout {
            id: layout
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: root.style.cardPadding * 1.5 }
            spacing: root.style.spacingLoose

            // What is being asked, on one line (it shrinks to fit), and for which account.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.style.spacingTight / 2
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.message.length > 0 ? root.message : Config.Auth.titleFallback
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    fontSizeMode: Text.HorizontalFit
                    minimumPointSize: root.style.captionPointSize
                    color: root.style.text
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.bodyPointSize * Theme.Typography.scaleRatio
                    font.weight: root.style.emphasisWeight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.accountLabel.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    text: root.accounts.length > 1 ? "‹  " + root.accountLabel + "  ›" : root.accountLabel
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.style.textMuted
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.captionPointSize
                }
            }
            Text {
                Layout.fillWidth: true
                visible: root.notice.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: (root.noticeIsError ? "✕  " : "") + root.notice
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.noticeIsError ? root.style.negative : root.style.textMuted
                font.family: root.style.uiFamily
                font.pointSize: root.style.captionPointSize
                Accessible.role: Accessible.StaticText
                Accessible.name: root.notice
            }

            // A fixed box: it never changes with a key. The border is the static "live" mark and
            // the centred lock is static too, so nothing here reacts to typing. A state (checking,
            // wrong password) or a visible-input prompt's text takes the lock's place.
            Rectangle {
                id: field
                objectName: "secretField"
                Layout.fillWidth: true
                Layout.preferredHeight: Config.Auth.fieldHeight
                color: root.style.background
                radius: root.style.inputRadius
                border.width: Theme.Shape.borderWidth
                border.color: markColor
                readonly property color markColor: root.fieldIsError ? root.style.negative : root.succeeded ? root.style.positive : root.checking ? root.style.softOutline : root.style.focus
                opacity: root.checking ? 0.7 : 1
                Accessible.role: Accessible.EditableText
                Accessible.passwordEdit: !root.visibleEcho
                Accessible.name: root.fieldText.length > 0 ? root.fieldText : Config.Auth.passwordLabel

                // The lock mark (shell/icons), drawn in the field's own colour.
                Icon {
                    id: lock
                    objectName: "lockIcon"
                    anchors.centerIn: parent
                    visible: (root.fieldText.length === 0 || root.failed) && !(root.visibleEcho && root.buffer.length > 0)
                    size: Config.Auth.iconSize
                    name: root.succeeded ? "lock-checked" : root.failed ? "lock-cross" : "lock"
                    color: field.markColor
                }
                Text {
                    objectName: "fieldLabel"
                    anchors { fill: parent; leftMargin: root.style.controlPaddingX; rightMargin: root.style.controlPaddingX }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: root.fieldText.length > 0 && !root.failed && !(root.visibleEcho && root.buffer.length > 0)
                    text: (root.fieldIsError ? "✕  " : "") + root.fieldText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.fieldIsError ? root.style.negative : root.style.textMuted
                    font.family: root.style.uiFamily
                    font.pointSize: root.style.bodyPointSize
                }
                Text {
                    objectName: "visibleEcho"
                    anchors { fill: parent; leftMargin: root.style.controlPaddingX; rightMargin: root.style.controlPaddingX }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: root.visibleEcho && root.buffer.length > 0
                    text: root.visibleEcho ? root.buffer : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideLeft
                    color: root.style.text
                    font.family: root.style.monoFamily
                    font.pointSize: root.style.bodyPointSize
                }
            }
        }
    }
}

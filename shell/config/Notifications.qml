pragma Singleton
import QtQuick

// Notification behaviour constants. The shell is the only notification daemon.
QtObject {
    readonly property bool enabled: true
    // Default popup lifetime by urgency (milliseconds).
    readonly property int lowTimeoutMs: 2500
    readonly property int normalTimeoutMs: 4000
    // A sender-chosen timeout is clamped to this (milliseconds).
    readonly property int maxTimeoutMs: 15000
    readonly property bool soundEnabled: false
    // Absolute path of the sound file; empty plays nothing.
    readonly property string soundFile: ""
    // Spoiler noise speed while redacted, in shader time units per second.
    readonly property real spoilerSpeed: 1
    readonly property string popupNamespace: "ui-shell-notif"
    readonly property int popupWidth: 360
    readonly property int popupMargin: 16
    readonly property int drawerWidth: 400
    // Explicit sizes (pixels). A card never grows past its cap.
    readonly property int popupMaxHeight: 220
    readonly property int cardMaxHeight: 260
    // A collapsed stack lists only its newest item; the layers behind it are decoration.
    readonly property int collapsedStackItems: 1
    // Deck: layers drawn (top card included), pixels each shows below the one above, and the
    // scale lost per layer.
    readonly property int deckDepth: 3
    readonly property int deckPeek: 10
    readonly property real deckScaleStep: 0.05
    // How far a deleted item slides out, and how far a new one rises in, in pixels.
    readonly property int leaveSlide: 48
    readonly property int appearLift: 12
    readonly property int iconGlyphSize: 16
    readonly property int unreadDotSize: 8
    // Each deck layer behind the top card is shaded this much toward the background.
    readonly property real deckShade: 0.18
    // A card that arrived this recently, while its stack is open, rises in.
    readonly property int arrivalWindowMs: 1500
    // The drawer's open and close take the same short time.
    readonly property int drawerSlide: 24
    readonly property int iconButtonSize: 24
    readonly property int imageSlotSize: 96
    readonly property int imageButtonHeight: 28
    readonly property int summaryMaxLines: 2
    readonly property int bodyMaxLines: 4
    readonly property real backdropOpacity: 0.4
    readonly property string drawerNamespace: "ui-shell-notif-drawer"
    readonly property string shortcutDrawer: "notifications"
    readonly property string shortcutDnd: "notifications-dnd"
    readonly property string shortcutDismiss: "notifications-dismiss"
}

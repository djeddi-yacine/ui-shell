pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// One app's stack in the drawer: a header (app, expand chevron, clear group) over its cards.
// Collapsed, the cards are a z-ordered deck: the newest on top, the others peeking out behind it,
// smaller and a little lower. Expanding fans the deck out into a list with one spring, each card a
// beat after the one above it; collapsing folds it back.
Item {
    id: root
    required property var group
    required property var style
    required property var inputState
    // Id of the keyboard-selected notification, or -1.
    property int currentId: -1
    signal selected(int id)

    readonly property bool expanded: NotifCenter.isExpanded(group.appName)
    readonly property int count: group.items.length
    // Cards mounted: the deck while collapsed, every card while expanded or still moving.
    readonly property int mountedCount: cards.count
    readonly property int pad: style.spacingTight
    readonly property int depth: Config.Notifications.deckDepth
    readonly property int peek: Config.Notifications.deckPeek
    readonly property bool animated: Theme.Motion.active

    // 0 = deck, 1 = list. A spring, so it overshoots and settles.
    property real morph: expanded ? 1 : 0
    Behavior on morph {
        enabled: root.animated
        SpringAnimation {
            spring: Theme.Motion.stackSpring
            damping: Theme.Motion.stackDamping
            epsilon: Theme.Motion.stackEpsilon
        }
    }
    readonly property bool wide: expanded || morph > 0.001
    // 0 -> 1 while the whole stack is being cleared.
    property real vanish: 0
    // 0 -> 1 as a stack that has just appeared fades in; one that was already there starts at 1.
    // Owned here, not by the list's add transition, which a reshuffle can interrupt part-way.
    property real entrance: 1
    property bool entering: false
    Behavior on entrance {
        enabled: root.entering && root.animated
        NumberAnimation { duration: Theme.Motion.listFadeDuration }
    }
    Component.onCompleted: {
        // Only a stack that has just arrived fades in; the rest are simply there.
        if (Date.now() - group.items[0].time < Config.Notifications.arrivalWindowMs) entrance = 0
        entering = true
        entrance = 1
    }

    // Height of the newest card (set by it), and the deck's total height.
    property Item newest: null
    readonly property real topHeight: newest ? newest.fullHeight : 0
    readonly property real deckExtent: topHeight + peek * (Math.min(count, depth) - 1)
    readonly property real staggerSpan: Theme.Motion.stackStagger * Math.min(count - 1, Theme.Motion.stackStaggerCap)

    function lerp(a, b, t) { return a + (b - a) * t }
    function clamp01(v) { return Math.max(0, Math.min(v, 1)) }

    // Animated removal of one card; the entry leaves the centre when the slide ends.
    function dismiss(id) {
        for (let i = 0; i < cards.count; ++i) {
            const slot = cards.itemAt(i) as Slot
            if (slot && slot.entryId === id) { slot.leave(); return }
        }
        NotifCenter.clear(id)
    }
    // Animated removal of the whole stack.
    function clearAll() {
        if (!animated) { NotifCenter.clearGroup(group.appName); return }
        vanishAnimation.start()
    }
    NumberAnimation {
        id: vanishAnimation
        target: root
        property: "vanish"
        from: 0
        to: 1
        duration: Theme.Motion.stackLeaveDuration
        easing.type: Theme.Motion.listMoveEasing
        onFinished: NotifCenter.clearGroup(root.group.appName)
    }

    clip: vanish > 0
    // A cleared stack slides out through the right edge while it fades; the gap it leaves closes
    // over the second half, so the stacks below do not jump.
    opacity: (1 - vanish) * entrance
    readonly property real closing: clamp01((vanish - 0.5) * 2)
    // The trailing 2 * pad separates this stack from the next (the drawer list has no spacing).
    implicitHeight: (head.height + pad + lerp(deckExtent, column.height, morph) + pad * 2) * (1 - closing)

    RowLayout {
        id: head
        transform: Translate { x: root.vanish * root.width }
        width: parent.width
        spacing: root.pad
        Text {
            Layout.fillWidth: true
            text: root.group.appName
            color: root.style.textMuted
            font.bold: true
            elide: Text.ElideRight
        }
        Controls.ShellIconButton {
            visible: root.count > 1
            Layout.preferredWidth: Config.Notifications.iconButtonSize
            Layout.preferredHeight: Config.Notifications.iconButtonSize
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            glyph: "expand-more"
            label: root.expanded ? qsTr("Collapse stack") : qsTr("Expand stack")
            iconSize: Config.Notifications.iconGlyphSize
            // The picture turns with the fan-out, overshoot included.
            contentItem.rotation: root.morph * 180
            onClicked: NotifCenter.toggleGroup(root.group.appName)
        }
        Controls.ShellIconButton {
            Layout.preferredWidth: Config.Notifications.iconButtonSize
            Layout.preferredHeight: Config.Notifications.iconButtonSize
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            glyph: "remove"
            label: qsTr("Clear group")
            iconSize: Config.Notifications.iconGlyphSize
            onClicked: root.clearAll()
        }
    }

    // The list layout is always laid out; the deck is each card's pose mixed in by its progress.
    Column {
        id: column
        transform: Translate { x: root.vanish * root.width }
        anchors { top: head.bottom; topMargin: root.pad; left: parent.left; right: parent.right }
        spacing: 0

        Repeater {
            id: cards
            model: ScriptModel {
                values: root.wide ? root.group.items : root.group.items.slice(0, root.depth + 1)
                objectProp: "id"
            }

            component Slot: Item {
                id: slot
                required property var modelData
                required property int index
                readonly property int entryId: modelData.id

                // Position in the deck; eased so a removal or arrival slides the others.
                property real rank: index
                Behavior on rank {
                    enabled: root.animated
                    SpringAnimation {
                        spring: Theme.Motion.stackSpring
                        damping: Theme.Motion.stackDamping
                        epsilon: Theme.Motion.stackEpsilon
                    }
                }
                // Fan-out progress of this card: later cards start later; may pass 1 (the bounce).
                readonly property real delay: Theme.Motion.stackStagger * Math.min(index, Theme.Motion.stackStaggerCap)
                readonly property real progress: Math.max(0, Math.min((root.morph - delay) / (1 - delay), 1.2))
                readonly property real settled: root.clamp01(progress)

                // New cards rise in; cards that were already there do not.
                property bool live: false
                property real appear: 1
                Behavior on appear {
                    enabled: slot.live && root.animated
                    NumberAnimation { duration: Theme.Motion.listMoveDuration; easing.type: Theme.Motion.listMoveEasing }
                }
                // 0 -> 1 while this card is being deleted.
                property real gone: 0
                NumberAnimation {
                    id: leaving
                    target: slot
                    property: "gone"
                    from: 0
                    to: 1
                    duration: Theme.Motion.stackLeaveDuration
                    easing.type: Theme.Motion.listMoveEasing
                    onFinished: NotifCenter.clear(slot.entryId)
                }
                function leave() {
                    if (!root.animated) { NotifCenter.clear(entryId); return }
                    leaving.start()
                }

                // Height as a list row; the deck draws every layer at the newest card's.
                readonly property real fullHeight: face.contentHeight
                width: column.width
                height: (fullHeight + root.pad) * appear * (1 - gone)
                z: root.count - index

                Binding { target: root; property: "newest"; value: slot; when: slot.index === 0 }

                Component.onCompleted: {
                    // Only a card that has just arrived rises in; the rest are simply there.
                    if (Date.now() - modelData.time < Config.Notifications.arrivalWindowMs) { live = false; appear = 0; live = true; appear = 1 }
                    live = true
                }

                Rectangle {
                    id: face
                    // Where this card sits as a layer of the deck, relative to the top of the stack.
                    readonly property real deckLayer: Math.min(slot.rank, root.depth)
                    readonly property real deckY: deckLayer * root.peek
                    readonly property real deckScale: 1 - Config.Notifications.deckScaleStep * deckLayer
                    // Height it wants as a list row.
                    readonly property real listHeight: Math.min(card.implicitHeight + root.pad * 2, Config.Notifications.cardMaxHeight)
                    // The deck shows every layer at the top card's height.
                    readonly property real deckHeight: root.topHeight > 0 ? root.topHeight : listHeight
                    property real contentHeight: listHeight
                    Behavior on contentHeight {
                        enabled: root.animated
                        NumberAnimation { duration: Theme.Motion.listMoveDuration; easing.type: Theme.Motion.listMoveEasing }
                    }

                    // Geometry, not a scale transform, and on whole pixels: a scaled or half-pixel
                    // rectangle draws its 1px border blurred and shimmering while it moves.
                    readonly property real faceScale: root.lerp(deckScale, 1, slot.settled)
                    width: Math.round(parent.width * faceScale)
                    height: Math.round(root.lerp(deckHeight, contentHeight, slot.settled) * faceScale)
                    y: Math.round(root.lerp(deckY - slot.y, 0, slot.progress)
                        + Config.Notifications.appearLift * (1 - slot.appear))
                    x: Math.round((parent.width - width) / 2 + Config.Notifications.leaveSlide * slot.gone)
                    opacity: root.lerp(root.clamp01(root.depth - slot.rank), 1, slot.settled)
                        * slot.appear * (1 - slot.gone)
                    clip: true
                    radius: root.style.popupRadius
                    // Theme tokens only: a read card sinks toward the drawer surface, and each layer
                    // behind the top card sinks a step further; a critical one keeps a red border.
                    color: Qt.tint(slot.modelData.read ? Qt.tint(root.style.popupSurface, Qt.alpha(root.style.surface, 0.55)) : root.style.popupSurface,
                        Qt.alpha(root.style.background, Config.Notifications.deckShade * deckLayer * (1 - slot.settled)))
                    border.width: 1
                    border.color: slot.entryId === root.currentId ? root.style.focus
                        : slot.modelData.urgency === "critical" ? root.style.negative : root.style.popupBorder
                    Behavior on color { enabled: root.animated; ColorAnimation { duration: Theme.Motion.stateDuration } }

                    // Only the card on top, or any card of a spread stack, takes the pointer.
                    readonly property bool engaged: slot.rank < 0.5 || slot.settled > 0.5

                    NotifCard {
                        id: card
                        x: root.pad
                        y: root.pad
                        width: parent.width - root.pad * 2
                        entry: slot.modelData
                        style: root.style
                        inputState: root.inputState
                        showActions: true
                        interactive: true
                        enabled: face.engaged
                        // The layers behind show a bare surface; the text fades in as they spread.
                        opacity: root.lerp(root.clamp01(1 - slot.rank), 1, slot.settled)
                        onActionInvoked: identifier => NotifCenter.invoke(slot.entryId, identifier)
                        onDeleteRequested: slot.leave()
                        onReadToggled: NotifCenter.toggleRead(slot.entryId)
                        onImageRequested: NotifCenter.loadImage(slot.entryId)
                    }
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            if (face.engaged) { root.selected(slot.entryId); NotifCenter.invokeDefault(slot.entryId) }
                            else NotifCenter.toggleGroup(root.group.appName)
                        }
                    }
                }
            }
            delegate: Slot {}
        }
    }
}

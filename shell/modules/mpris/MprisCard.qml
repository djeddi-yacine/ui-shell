pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

// Everything the media panel shows and every key it handles: the backdrop, the player line with the
// pin, the title and artist (one line each, scrolling when they do not fit), the seek bar, previous,
// play or pause, next, and the one-row player selector. Every row is always present and every row
// has a fixed height, so the card never changes size when the player or the text changes.
// It takes the selection, the art and the seek step as properties and imports no adapter, so
// tests build it with fakes. The panel around it (MprisPanel) owns the settings, the context
// popups and the window.
FocusScope {
    id: root
    required property var selection
    required property var art
    required property int seekStep
    required property var style
    required property Controls.InputState inputState
    // True while the panel is shown: the position timer runs only then.
    property bool active: true

    readonly property var player: selection.current
    readonly property bool hasPlayer: player !== null && player !== undefined
    // A seek bar only makes sense when the player reports a position and a length. Without a
    // length Quickshell returns the position as the length and the bar would look full.
    readonly property bool seekable: hasPlayer && player.positionSupported && player.lengthSupported && player.length > 0
    readonly property bool canSeek: seekable && player.canSeek
    // A stream (no length) is not a track to seek in: it gets a live bar instead of a slider.
    readonly property bool stream: hasPlayer && !seekable
    readonly property bool playing: hasPlayer && player.isPlaying
    readonly property string title: !hasPlayer ? qsTr("Nothing playing") : (player.trackTitle || player.identity)
    // The pin button says what it does and what state it is in, for the accessible name.
    readonly property string pinLabel: selection.pinState === "none" ? qsTr("Pin this player")
        : selection.pinState === "active" ? qsTr("Unpin the player") : qsTr("Unpin the player, which is not running")
    readonly property real padding: Config.Mpris.outerMargin
    // Secondary text and icons. Over art they are lifted towards the main text colour so they stay
    // readable on any picture; the change fades with the art.
    readonly property bool artShown: art.state === "ready" && art.path.length > 0
    property color mutedColor: artShown ? Qt.alpha(style.text, Config.Mpris.artMutedOpacity) : style.textMuted
    Behavior on mutedColor { ColorAnimation { duration: Theme.Motion.active ? Config.Mpris.artFadeMs : 0 } }

    // A square: the height is the width, so the card never changes size with the player or the text.
    implicitHeight: width
    focus: true

    function clock(seconds) {
        const whole = Math.max(0, Math.floor(seconds))
        const minutes = Math.floor(whole / 60)
        const rest = whole % 60
        return minutes + ":" + (rest < 10 ? "0" : "") + rest
    }
    function togglePin() {
        if (selection.pinState !== "none") selection.unpin()
        else if (hasPlayer) selection.pin(selection.keyOf(player))
    }

    Keys.onPressed: event => {
        inputState.keyboardUsed()
        // Ctrl chords belong to the panel's context popups; Tab and Esc to the panel.
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        const keys = Config.Mpris.panelKeys
        // Holding a key must not flicker play and pause, skip a whole album or jump between
        // players: only seeking repeats, so a held arrow scrubs.
        const repeating = event.isAutoRepeat
        if (event.key === keys.seekBack) selection.seekBy(-seekStep)
        else if (event.key === keys.seekForward) selection.seekBy(seekStep)
        else if (event.key === keys.playPause) { if (!repeating) selection.playPause() }
        else if (event.key === keys.next) { if (!repeating) selection.next() }
        else if (event.key === keys.previous) { if (!repeating) selection.previous() }
        else if (event.key === keys.pin) { if (!repeating) togglePin() }
        else if (event.key === keys.playerPrevious) { if (!repeating) selection.showPlayer(-1) }
        else if (event.key === keys.playerNext) { if (!repeating) selection.showPlayer(1) }
        else return
        event.accepted = true
    }

    // The position is extrapolated by Quickshell and never announced, so the bar needs a tick,
    // and only while it is visible and moving: the one timer in the module.
    Timer {
        interval: Config.Mpris.positionTickMs
        repeat: true
        running: root.active && root.seekable && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        color: root.style.pickerSurface
        radius: root.style.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: root.style.pickerBorder
        clip: true
        MprisArtBackdrop {
            anchors.fill: parent
            art: root.art
            style: root.style
            // A made picture that is gone from the cache: let the adapter make it again.
            onPictureLost: path => { if (typeof root.art.lost === "function") root.art.lost(path) }
        }
    }

    ColumnLayout {
        id: layout
        x: root.padding
        y: root.padding
        width: parent.width - root.padding * 2
        height: parent.height - root.padding * 2
        spacing: root.style.spacingLoose

        // Which player this is, and the pin (top right): an icon, filled when pinned, in the
        // warning colour while the pinned player is not running.
        RowLayout {
            Layout.fillWidth: true
            spacing: root.style.spacing
            SvgIcon {
                objectName: "cassetteIcon"
                name: "tape-music-cassette"
                size: Config.Mpris.headerIconSize
                color: root.mutedColor
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? root.player.identity : qsTr("Media")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: root.mutedColor
                font.family: root.style.uiFamily
                font.pointSize: root.style.captionPointSize
                font.capitalization: Font.AllUppercase
                font.letterSpacing: root.style.labelLetterSpacing
            }
            Controls.ShellButton {
                id: pinButton
                objectName: "pinButton"
                Layout.preferredWidth: root.style.controlHeight
                enabled: root.hasPlayer || root.selection.pinState !== "none"
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                selected: root.selection.pinState !== "none"
                Accessible.name: root.pinLabel
                contentItem: Item {
                    SvgIcon {
                        centered: true
                        name: root.selection.pinState === "none" ? "pin-circle" : "pin-circle-filled"
                        size: Config.Mpris.pinIconSize
                        color: root.selection.pinState === "absent" ? root.style.warning : root.selection.pinState === "active" ? root.style.accent : root.style.text
                        opacity: pinButton.enabled ? 1 : 0.4
                    }
                }
                onClicked: root.togglePin()
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
        }

        // What is playing: one line each, scrolling when too long.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.Mpris.titleGap
            MarqueeText {
                objectName: "titleLine"
                Layout.fillWidth: true
                text: root.title
                color: root.style.text
                running: root.active
                font.family: root.style.uiFamily
                font.pointSize: root.style.displayPointSize
                font.weight: root.style.emphasisWeight
                Accessible.role: Accessible.StaticText
                Accessible.name: root.title
            }
            MarqueeText {
                objectName: "artistLine"
                Layout.fillWidth: true
                text: root.hasPlayer ? root.player.trackArtist : ""
                color: root.mutedColor
                running: root.active
                font.family: root.style.uiFamily
                font.pointSize: root.style.bodyPointSize
            }
        }

        // The free space of the square sits here, so the controls stay at the bottom.
        Item { Layout.fillHeight: true }

        // The seek bar keeps its place and its height whatever the player, so the card does not
        // change size. A track has a slider; a stream (no length) has a live bar instead, with
        // the elapsed time and "LIVE", and nothing to drag.
        RowLayout {
            objectName: "seekRow"
            Layout.fillWidth: true
            opacity: root.hasPlayer ? 1 : 0
            spacing: root.style.spacing
            Text {
                text: root.seekable ? root.clock(root.player.position)
                    : root.stream && root.player.positionSupported ? root.clock(root.player.position) : "0:00"
                opacity: root.hasPlayer && (root.seekable || root.player.positionSupported) ? 1 : 0
                color: root.mutedColor
                font.family: root.style.monoFamily
                font.pointSize: root.style.captionPointSize
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: slider.implicitHeight
                Controls.ShellSlider {
                    id: slider
                    objectName: "seekSlider"
                    anchors.fill: parent
                    visible: !root.stream
                    style: root.style
                    inputState: root.inputState
                    // The panel's keys do the stepping; the slider is for the pointer.
                    focusPolicy: Qt.NoFocus
                    enabled: root.canSeek
                    from: 0
                    to: root.seekable ? root.player.length : 1
                    stepSize: 1
                    onMoved: if (root.canSeek && root.player) root.player.position = value
                }
                // Not a permanent binding on `value`: a drag would break it.
                Binding {
                    target: slider
                    property: "value"
                    value: root.seekable ? root.player.position : 0
                    when: !slider.pressed
                }
                // The live bar: an outlined track with a segment that sweeps along it while the
                // stream plays, and rests in the middle when it stops.
                Rectangle {
                    id: liveBar
                    objectName: "liveBar"
                    anchors.fill: parent
                    visible: root.stream
                    color: "transparent"
                    clip: true
                    readonly property real trackHeight: Theme.Shape.borderWidth * 2
                    readonly property real segmentWidth: width * Config.Mpris.liveSegmentFraction
                    readonly property bool sweeping: root.active && root.stream && root.playing && Theme.Motion.active
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: liveBar.trackHeight
                        color: root.style.softOutline
                    }
                    Rectangle {
                        id: segment
                        anchors.verticalCenter: parent.verticalCenter
                        width: liveBar.segmentWidth
                        height: liveBar.trackHeight * 2
                        x: (liveBar.width - width) / 2
                        color: root.playing ? root.style.accent : root.mutedColor
                        SequentialAnimation on x {
                            running: liveBar.sweeping
                            onRunningChanged: if (!running) segment.x = (liveBar.width - segment.width) / 2
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: liveBar.width - segment.width; duration: Config.Mpris.liveSweepMs; easing.type: Easing.InOutSine }
                            NumberAnimation { from: liveBar.width - segment.width; to: 0; duration: Config.Mpris.liveSweepMs; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
            Text {
                text: root.seekable ? root.clock(root.player.length) : root.stream ? qsTr("LIVE") : "0:00"
                opacity: root.hasPlayer ? 1 : 0
                color: root.stream ? root.style.accent : root.mutedColor
                font.family: root.style.monoFamily
                font.pointSize: root.style.captionPointSize
                font.letterSpacing: root.stream ? root.style.chipLetterSpacing : 0
            }
        }

        // Previous, play or pause, next: icons, centred.
        RowLayout {
            Layout.fillWidth: true
            spacing: root.style.spacing
            Item { Layout.fillWidth: true }
            Controls.ShellButton {
                id: previousButton
                objectName: "previousButton"
                Layout.preferredWidth: Config.Mpris.transportWidth
                enabled: root.hasPlayer && root.player.canGoPrevious
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Previous track")
                contentItem: Item {
                    SvgIcon { centered: true; name: "media-previous"; size: Config.Mpris.transportIconSize; color: root.style.text; opacity: previousButton.enabled ? 1 : 0.4 }
                }
                onClicked: root.selection.previous()
                // Space belongs to play and pause, not to whichever button holds the focus.
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
            Controls.ShellButton {
                id: playButton
                objectName: "playButton"
                Layout.preferredWidth: Config.Mpris.playWidth
                enabled: root.hasPlayer && root.player.canTogglePlaying
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.primaryActionEmphasis
                text: root.playing ? qsTr("Pause") : qsTr("Play")
                Accessible.name: root.playing ? qsTr("Pause") : qsTr("Play")
                contentItem: Item {
                    SvgIcon { centered: true; name: root.playing ? "media-pause" : "media-play"; size: Config.Mpris.playIconSize; color: root.style.background; opacity: playButton.enabled ? 1 : 0.4 }
                }
                onClicked: root.selection.playPause()
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
            Controls.ShellButton {
                id: nextButton
                objectName: "nextButton"
                Layout.preferredWidth: Config.Mpris.transportWidth
                enabled: root.hasPlayer && root.player.canGoNext
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Next track")
                contentItem: Item {
                    SvgIcon { centered: true; name: "media-next"; size: Config.Mpris.transportIconSize; color: root.style.text; opacity: nextButton.enabled ? 1 : 0.4 }
                }
                onClicked: root.selection.next()
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
            Item { Layout.fillWidth: true }
        }

        // The one-row player selector: left and right buttons switch the player (and pin it),
        // and a row of small squares shows how many players there are and which one is shown.
        // The row is always there, with the buttons off when there is nothing to switch to.
        RowLayout {
            objectName: "playerSelector"
            Layout.fillWidth: true
            spacing: root.style.spacing
            Controls.ShellButton {
                id: playerPreviousButton
                objectName: "playerPreviousButton"
                Layout.preferredWidth: root.style.controlHeight
                enabled: root.selection.playerCount > 1
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Show the previous player")
                contentItem: Item {
                    SvgIcon { centered: true; name: "arrow-left"; size: Config.Mpris.arrowIconSize; color: root.style.text; opacity: playerPreviousButton.enabled ? 1 : 0.4 }
                }
                onClicked: root.selection.showPlayer(-1)
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.style.controlHeight
                Row {
                    objectName: "playerDots"
                    anchors.centerIn: parent
                    spacing: root.style.spacingTight
                    Repeater {
                        model: root.selection.listed
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool shownNow: root.hasPlayer && root.selection.keyOf(modelData) === root.selection.keyOf(root.player)
                            width: Config.Mpris.selectorDotSize
                            height: Config.Mpris.selectorDotSize
                            color: shownNow ? root.style.accent : "transparent"
                            border.width: Theme.Shape.borderWidth
                            border.color: shownNow ? root.style.accent : root.mutedColor
                        }
                    }
                }
            }
            Controls.ShellButton {
                id: playerNextButton
                objectName: "playerNextButton"
                Layout.preferredWidth: root.style.controlHeight
                enabled: root.selection.playerCount > 1
                style: root.style
                inputState: root.inputState
                emphasis: Theme.Interaction.buttonEmphasis
                Accessible.name: qsTr("Show the next player")
                contentItem: Item {
                    SvgIcon { centered: true; name: "arrow-right"; size: Config.Mpris.arrowIconSize; color: root.style.text; opacity: playerNextButton.enabled ? 1 : 0.4 }
                }
                onClicked: root.selection.showPlayer(1)
                Keys.onSpacePressed: event => { event.accepted = true; root.selection.playPause() }
            }
        }
    }
}

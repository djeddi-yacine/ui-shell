pragma Singleton
import QtQuick

// The two options each component offers in its Ctrl+E settings, as data. The editor,
// the settings adapter and the settings file reader all read this table, so a component
// is one entry here plus its renderer script (scripts/render-<component>-settings).
//   kind: boolean | integer (min..max) | choices (a fixed list of integers or strings)
//   labels: optional { value: text } for choices that should not show their raw value
//   A component may have any number of options; the settings popup lists them all.
//   fallback: the explicit default declared in static configuration
//   available: optional, a function of a choice that says whether to offer it right now
QtObject {
    readonly property var components: ({
        launcher: [
            { key: "showIcons", label: qsTr("Icons"), name: qsTr("Application icons"), kind: "boolean", fallback: AppLauncher.showIcons },
            { key: "visibleRows", label: qsTr("Rows"), name: qsTr("Visible rows"), kind: "integer", min: 1, max: 24, fallback: AppLauncher.visibleRows }
        ],
        wallpaper: [
            { key: "wideColumns", label: qsTr("Columns"), name: qsTr("Wide wallpaper grid columns"), kind: "integer", min: 1, max: 6, fallback: WallpaperPicker.wideColumns },
            { key: "maximumVisibleRows", label: qsTr("Rows"), name: qsTr("Visible rows"), kind: "integer", min: 1, max: 4, fallback: WallpaperPicker.maximumVisibleRows }
        ],
        record: [
            { key: "countdown", label: qsTr("Countdown"), name: qsTr("Countdown seconds"), kind: "choices", choices: [0, 3, 5, 10], fallback: Record.countdownSeconds },
            { key: "desktopAudio", label: qsTr("Desktop audio"), name: qsTr("Record desktop audio"), kind: "boolean", fallback: Record.desktopAudio },
            { key: "microphone", label: qsTr("Microphone"), name: qsTr("Record the microphone"), kind: "boolean", fallback: Record.microphone },
            { key: "fps", label: qsTr("Frame rate"), name: qsTr("Frames per second"), kind: "choices", choices: [24, 30, 60, 90, 120, 144], fallback: Record.fps },
            { key: "quality", label: qsTr("Quality"), name: qsTr("Video quality preset"), kind: "choices", choices: ["medium", "high", "very_high", "ultra"],
              labels: { medium: qsTr("Medium"), high: qsTr("High"), very_high: qsTr("Very high"), ultra: qsTr("Ultra") }, fallback: Record.quality },
            { key: "codec", label: qsTr("Codec"), name: qsTr("Video codec"), kind: "choices", choices: ["auto", "h264", "hevc", "av1", "vp9"],
              labels: { auto: qsTr("Automatic") }, fallback: Record.codec },
            { key: "audioCodec", label: qsTr("Audio codec"), name: qsTr("Audio codec"), kind: "choices", choices: ["opus", "aac"],
              labels: { opus: qsTr("Opus"), aac: qsTr("AAC") }, fallback: Record.audioCodec },
            { key: "bitrate", label: qsTr("Bitrate"), name: qsTr("Video bitrate, which overrides the quality preset"), kind: "choices",
              choices: ["auto", "2500", "5000", "8000", "12000", "20000", "40000", "80000"],
              labels: { auto: qsTr("From quality"), "2500": qsTr("2.5 Mbps"), "5000": qsTr("5 Mbps"), "8000": qsTr("8 Mbps"), "12000": qsTr("12 Mbps"),
                        "20000": qsTr("20 Mbps"), "40000": qsTr("40 Mbps"), "80000": qsTr("80 Mbps") }, fallback: Record.bitrate },
            { key: "container", label: qsTr("Container"), name: qsTr("File container"), kind: "choices", choices: ["mp4", "mkv"], fallback: Record.container },
            { key: "cursor", label: qsTr("Cursor"), name: qsTr("Record the pointer"), kind: "boolean", fallback: Record.cursor },
            { key: "webcam", label: qsTr("Webcam"), name: qsTr("Show the webcam in the recording"), kind: "boolean", fallback: Record.webcam }
        ],
        shot: [
            { key: "copyToClipboard", label: qsTr("Clipboard"), name: qsTr("Copy the picture to the clipboard"), kind: "boolean", fallback: Shot.copyToClipboard },
            { key: "saveToFile", label: qsTr("File"), name: qsTr("Save the picture to a file"), kind: "boolean", fallback: Shot.saveToFile }
        ],
        mpris: [
            { key: "seekStep", label: qsTr("Seek step"), name: qsTr("Seek step in seconds"), kind: "choices", choices: [5, 10, 15, 30], fallback: Mpris.seekStepSeconds },
            { key: "artMode", label: qsTr("Art"), name: qsTr("Art behind the title, for every player"), kind: "choices", choices: ["auto", "cover", "blurhash", "off"],
              labels: { auto: qsTr("Per player"), cover: qsTr("Cover"), blurhash: qsTr("Blurhash"), off: qsTr("Off") }, fallback: Mpris.artMode,
              // The blurhash mode is offered only when its tools were found at start.
              available: value => value !== "blurhash" || Mpris.blurhashAvailable }
        ],
        audio: [
            { key: "volumeStep", label: qsTr("Step"), name: qsTr("Volume step percent"), kind: "choices", choices: [1, 2, 5, 10], fallback: Audio.volumeStepPercent },
            { key: "maximumVolume", label: qsTr("Maximum volume"), name: qsTr("Maximum volume percent"), kind: "choices", choices: [100, 125, 150], fallback: Audio.maximumVolumePercent }
        ]
    })

    // Whether a value read from a settings file is allowed for this option.
    function valid(option, value) {
        if (value === undefined) return true
        if (option.kind === "boolean") return typeof value === "boolean"
        if (option.kind === "choices") return option.choices.includes(value)
        return Number.isInteger(value) && value >= option.min && value <= option.max
    }
}

pragma Singleton
import QtQuick

// The two options each component offers in its Ctrl+E settings, as data. The editor,
// the settings adapter and the settings file reader all read this table, so a component
// is one entry here plus its renderer script (scripts/render-<component>-settings).
//   kind: boolean | integer (min..max) | choices (a fixed list of integers)
//   fallback: the explicit default declared in static configuration
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
        audio: [
            { key: "volumeStep", label: qsTr("Step"), name: qsTr("Volume step percent"), kind: "choices", choices: [1, 2, 5, 10], fallback: Audio.volumeStepPercent },
            { key: "maximumVolume", label: qsTr("Maximum volume"), name: qsTr("Maximum volume percent"), kind: "choices", choices: [100, 125, 150], fallback: Audio.maximumVolumePercent }
        ]
    })

    // Whether a value read from a settings file is allowed for this option.
    function valid(option, value) {
        if (value === undefined) return true
        if (option.kind === "boolean") return typeof value === "boolean"
        if (!Number.isInteger(value)) return false
        return option.kind === "choices" ? option.choices.includes(value) : value >= option.min && value <= option.max
    }
}

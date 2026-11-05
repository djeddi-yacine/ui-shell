pragma Singleton
import QtQuick
import "../config" as Config

QtObject {
    property var defaultPalette: Config.GeneratedRuntime.profileColors.defaultPalette
    property var byOutput: Config.GeneratedRuntime.profileColors.byOutput
    property var globalPalette: Config.GeneratedRuntime.profileColors.globalPalette
    signal profileApplied(var snapshot, bool restoresWallpapers)

    function forOutput(name) {
        return Object.prototype.hasOwnProperty.call(byOutput, name) ? byOutput[name] : defaultPalette
    }
    function apply(snapshot, restoresWallpapers) {
        defaultPalette = snapshot.defaultPalette
        byOutput = snapshot.byOutput
        globalPalette = snapshot.globalPalette
        profileApplied(snapshot, restoresWallpapers)
    }
}

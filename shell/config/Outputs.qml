pragma Singleton
import QtQuick

QtObject {
    // "screen-index": pickerScreenIndex is an exact zero-based runtime screen index.
    // "output-name": pickerOutputName is an exact output name; missing outputs are errors.
    // Neither policy substitutes another screen when its target is unavailable.
    readonly property string pickerTargetMode: "screen-index"
    readonly property int pickerScreenIndex: 0
    readonly property string pickerOutputName: ""
    // Required user defaults. Generated values override only launcher hosting.
    readonly property string launcherDefaultTargetMode: "screen-index"
    readonly property int launcherDefaultScreenIndex: 0
    readonly property string launcherDefaultOutputName: ""
    readonly property string launcherTargetMode: GeneratedLauncherOutput.targetMode === undefined
        ? launcherDefaultTargetMode : GeneratedLauncherOutput.targetMode
    readonly property int launcherScreenIndex: GeneratedLauncherOutput.screenIndex === undefined
        ? launcherDefaultScreenIndex : GeneratedLauncherOutput.screenIndex
    readonly property string launcherOutputName: GeneratedLauncherOutput.outputName === undefined
        ? launcherDefaultOutputName : GeneratedLauncherOutput.outputName
    function launcherScreen(screens) {
        let target
        if (launcherTargetMode === "output-name")
            target = screens.find(screen => screen.name === launcherOutputName)
        else if (launcherTargetMode === "screen-index")
            target = screens[launcherScreenIndex]
        else {
            console.error("App launcher: unsupported target mode:", launcherTargetMode)
            return null
        }
        if (!target) {
            console.error("App launcher: target unavailable:", launcherTargetMode,
                launcherTargetMode === "output-name" ? launcherOutputName : launcherScreenIndex)
            return null
        }
        return target
    }
    function pickerScreen(screens) {
        let target
        if (pickerTargetMode === "output-name")
            target = screens.find(screen => screen.name === pickerOutputName)
        else if (pickerTargetMode === "screen-index")
            target = screens[pickerScreenIndex]
        else {
            console.error("Wallpaper picker: unsupported target mode:", pickerTargetMode)
            return null
        }
        if (!target) {
            console.error("Wallpaper picker: target unavailable:", pickerTargetMode,
                pickerTargetMode === "output-name" ? pickerOutputName : pickerScreenIndex)
            return null
        }
        return target
    }
}

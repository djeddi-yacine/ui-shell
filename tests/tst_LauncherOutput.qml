import QtQuick
import QtTest
import "../shell/config" as Config

TestCase {
    name: "LauncherOutput"
    when: windowShown
    readonly property var screens: [{ name: "__TEST_OUTPUT_A__" }, { name: "__TEST_OUTPUT_B__" }]

    function test_userDefaultAndGeneratedOverride() {
        compare(Config.Outputs.launcherTargetMode, Config.GeneratedLauncherOutput.targetMode === undefined
            ? Config.Outputs.launcherDefaultTargetMode : Config.GeneratedLauncherOutput.targetMode)
        compare(Config.Outputs.launcherScreenIndex, Config.GeneratedLauncherOutput.screenIndex === undefined
            ? Config.Outputs.launcherDefaultScreenIndex : Config.GeneratedLauncherOutput.screenIndex)
        compare(Config.Outputs.launcherOutputName, Config.GeneratedLauncherOutput.outputName === undefined
            ? Config.Outputs.launcherDefaultOutputName : Config.GeneratedLauncherOutput.outputName)
        const target = Config.Outputs.launcherTargetMode === "screen-index"
            ? screens[Config.Outputs.launcherScreenIndex]
            : screens.find(screen => screen.name === Config.Outputs.launcherOutputName)
        verify(target !== undefined)
        verify(Config.Outputs.launcherScreen(screens) === target)
    }

    function test_unavailableTargetNeverSwitchesOutput() {
        compare(Config.Outputs.launcherScreen([]), null)
        if (Config.Outputs.launcherTargetMode === "output-name")
            compare(Config.Outputs.launcherScreen([screens[0]]), null)
    }
}

import QtQuick
import QtTest
import "../shell/config" as Config

TestCase {
    name: "OutputPalette"
    when: windowShown

    function test_defaultForDisplayWithoutOverride() {
        const name = "__TEST_UNCONFIGURED_OUTPUT__"
        const palettes = Config.GeneratedRuntime.profileColors
        verify(!Object.prototype.hasOwnProperty.call(palettes.byOutput, name))
        compare(palettes.byOutput[name], undefined)
        verify(palettes.defaultPalette !== undefined)
        verify(palettes.byOutput[""] === undefined)
    }

    function test_startupAndPaletteExposeTheCompleteTheme() {
        const palettes = Config.GeneratedRuntime.profileColors
        verify(palettes.globalPalette !== undefined)
        verify(palettes.globalPalette.colors !== undefined)
        verify(palettes.globalPalette.hyprland !== undefined)
        verify(palettes.defaultPalette.colors !== undefined)
        verify(palettes.defaultPalette.hyprland !== undefined)
        verify(Config.GeneratedRuntime.wallpaperTargets !== undefined)
    }

    function test_namedOverrides() {
        const palettes = Config.GeneratedRuntime.profileColors
        const outputs = Object.keys(palettes.byOutput)
        verify(!outputs.includes(""), "Default is an explicit value outside the override map")
        for (const output of outputs)
            verify(palettes.byOutput[output] !== undefined)
    }

    function test_objectPropertiesAreNotOutputOverrides() {
        const palettes = Config.GeneratedRuntime.profileColors
        for (const name of ["constructor", "toString", "__proto__"])
            verify(!Object.prototype.hasOwnProperty.call(palettes.byOutput, name))
    }
}

import QtQuick
import QtTest
import "../shell/config" as Config

// The Ctrl+E settings of the media panel: the blurhash mode is offered only when its tools were
// found, and a saved "blurhash" stays a valid value either way.
Item {
    TestCase {
        name: "MprisSpec"
        function art() { return Config.ComponentSpec.components.mpris.find(option => option.key === "artMode") }
        function cleanup() { Config.Mpris.blurhashAvailable = true }

        function test_blurhashIsOfferedWhenItsToolsExist() {
            Config.Mpris.blurhashAvailable = true
            compare(art().choices.filter(value => art().available(value)).join(), "auto,cover,blurhash,off")
        }
        function test_blurhashIsHiddenWhenItsToolsAreMissing() {
            Config.Mpris.blurhashAvailable = false
            compare(art().choices.filter(value => art().available(value)).join(), "auto,cover,off")
        }
        function test_aSavedBlurhashStaysValid() {
            Config.Mpris.blurhashAvailable = false
            verify(Config.ComponentSpec.components.mpris.length === 2)
            verify(art().choices.includes("blurhash"))
        }
        function test_theSeekStepChoicesAreTheRendererChoices() {
            const step = Config.ComponentSpec.components.mpris.find(option => option.key === "seekStep")
            compare(step.choices.join(), "5,10,15,30")
        }
    }
}

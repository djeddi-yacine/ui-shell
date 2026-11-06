import QtQuick
import QtQuick.Window
import QtTest
import "../shell/components" as Controls
import "../shell/theme" as Theme

// The capture-target picker: what it reports as `target`, how it keeps a choice when the
// lists change, region validation, and the keyboard (Left/Right kinds, Up/Down lists).
Item {
    id: root
    width: 700
    height: 600
    Controls.InputState { id: input; pointerActive: false }
    Controls.TargetPicker {
        id: picker
        width: 600
        style: Theme.Style
        inputState: input
        monitors: [{ name: "DP-1", width: 1920, height: 1080 }, { name: "HDMI-A-2", width: 1600, height: 900 }]
        windows: [{ address: "0xaa1", title: "editor", class: "code", width: 800, height: 600 },
                  { address: "0xaa2", title: "", class: "kitty", width: 400, height: 300 }]
    }
    SignalSpy { id: pickSpy; target: picker; signalName: "pickRegionRequested" }

    TestCase {
        name: "TargetPicker"
        when: windowShown
        function init() {
            root.Window.window.requestActivate()
            picker.monitors = [{ name: "DP-1", width: 1920, height: 1080 }, { name: "HDMI-A-2", width: 1600, height: 900 }]
            picker.windows = [{ address: "0xaa1", title: "editor", class: "code", width: 800, height: 600 },
                              { address: "0xaa2", title: "", class: "kitty", width: 400, height: 300 }]
            picker.kind = "monitor"
            picker.monitor = "DP-1"
            picker.windowAddress = "0xaa1"
            picker.region = ""
            pickSpy.clear()
        }

        function test_nothingIsChosenUntilTheUserChooses() {
            picker.monitor = ""
            picker.windowAddress = ""
            picker.monitors = []
            picker.monitors = [{ name: "DP-1", width: 1920, height: 1080 }]
            picker.windows = [{ address: "0xaa1", title: "editor", class: "code", width: 800, height: 600 }]
            compare(picker.target, "")
            picker.kind = "window"
            compare(picker.target, "")
        }
        function test_targetFollowsTheKind() {
            compare(picker.target, "monitor:DP-1")
            picker.kind = "window"
            compare(picker.target, "window:0xaa1")
            picker.kind = "region"
            compare(picker.target, "", "no region chosen yet")
            picker.region = "640x480+30+40"
            compare(picker.target, "region:640x480+30+40")
        }
        function test_regionValidation() {
            picker.kind = "region"
            for (const bad of ["0x200+1+1", "300x200", "300x200+-5+1", "abc", "100000x20+1+1", "300x200+1+2;x"]) {
                picker.region = bad
                compare(picker.regionValid, false, bad)
                compare(picker.target, "", bad)
            }
            picker.region = "1x1+0+0"
            compare(picker.regionValid, true)
        }
        function test_aChoiceThatVanishesIsCleared() {
            picker.kind = "window"
            picker.windowAddress = "0xaa2"
            picker.windows = [{ address: "0xaa1", title: "editor", class: "code", width: 800, height: 600 }]
            compare(picker.windowAddress, "", "a vanished choice is cleared, not replaced")
            compare(picker.target, "")
            picker.windowAddress = "0xaa1"
            compare(picker.target, "window:0xaa1")
            picker.windows = []
            compare(picker.target, "", "no window left means no target")
        }
        function test_aKindTheBackendDoesNotOfferIsDropped() {
            picker.kind = "window"
            picker.kinds = ["monitor", "region"]
            compare(picker.kind, "monitor")
            picker.kinds = ["monitor", "window", "region"]
        }
        function test_leftAndRightChangeTheKind() {
            picker.focusFirst()
            const first = picker.children[0].children[0]
            first.forceActiveFocus()
            keyClick(Qt.Key_Right)
            compare(picker.kind, "window")
            keyClick(Qt.Key_Right)
            compare(picker.kind, "region")
            keyClick(Qt.Key_Left)
            compare(picker.kind, "window")
        }
        function test_regionButtonsAndLastRegion() {
            picker.kind = "region"
            picker.lastRegion = "800x600+10+20"
            wait(50)
            picker.region = picker.lastRegion
            compare(picker.target, "region:800x600+10+20")
            picker.lastRegion = ""
        }
        function test_noEntriesMeansNoTarget() {
            picker.monitors = []
            compare(picker.monitor, "")
            compare(picker.target, "")
            picker.monitors = [{ name: "DP-1", width: 1920, height: 1080 }]
            compare(picker.monitor, "", "a new list does not pick for the user")
            compare(picker.target, "")
        }
    }
}

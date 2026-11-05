//@ pragma ShellId ui-shell-picker-motion-test
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "modules/wallpaper" as Wallpaper
import "components" as Controls
import "config" as Config
import "theme" as Theme

ShellRoot {
    Component.onCompleted: Quickshell.watchFiles = Config.Config.watchSourceFiles
    id: root
    property string phase: "open"
    property int cycles: 0
    property int creations: 0
    property int closes: 0
    property var previousPanel: null
    property double deadline: Date.now() + 15000
    readonly property var output: Quickshell.screens.length ? Quickshell.screens[0] : null

    function check(condition, message) {
        if (!condition)
            throw new Error(message)
    }

    Controls.InputState { id: input; pointerActive: false }
    Wallpaper.PickerSurface { id: surface; modelData: root.output; inputState: input }
    Connections {
        target: surface.panel
        function onClosed() { root.closes += 1 }
    }

    Timer {
        id: driver
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            try {
                root.check(Date.now() < root.deadline, "motion cycle timed out: " + root.phase)
                if (!root.output)
                    return
                if (root.phase === "open") {
                    Wallpaper.PickerState.screenName = root.output.name
                    Wallpaper.PickerState.targetOutput = root.output.name
                    Wallpaper.PickerState.open = true
                    root.phase = "loaded"
                    return
                }
                if (root.phase === "loaded") {
                    if (!surface.panel || surface.panel.width <= 0)
                        return
                    if (root.previousPanel)
                        root.check(surface.panel === root.previousPanel, "picker was rebuilt on reopen")
                    if (surface.panel !== root.previousPanel)
                        root.creations += 1
                    root.previousPanel = surface.panel
                    root.check(surface.panel.selectedWallpaper.path === surface.panel.savedPath,
                        "opening did not select the saved wallpaper")
                    const index = surface.panel.selectedIndex
                    surface.panel.moveSelection(1)
                    root.check(surface.panel.selectedIndex === Math.min(index + 1,
                        surface.panel.filteredWallpapers.length - 1), "keyboard selection was delayed")
                    root.phase = "close"
                    // Alternate completed entry and cancellation during entry.
                    driver.interval = root.cycles % 2 === 0 ? Theme.Motion.enterDuration + 40 : 20
                    return
                }
                if (root.phase === "close") {
                    const cancel = { key: Config.Keyboard.cancelKey, modifiers: Qt.NoModifier, accepted: false }
                    surface.panel.handleKey(cancel)
                    const before = surface.panel.selectedIndex
                    surface.panel.moveSelection(1)
                    surface.panel.chooseTheme()
                    root.check(!surface.panel.applying && surface.panel.selectedIndex === before,
                        "closing accepted a late wallpaper action")
                    surface.panel.requestClose()
                    root.check(cancel.accepted, "Escape was not accepted")
                    root.phase = "closed"
                    driver.interval = 20
                    return
                }
                if (Wallpaper.PickerState.open)
                    return
                root.cycles += 1
                root.check(root.closes === root.cycles, "close emitted more than once")
                if (root.cycles === 8) {
                    console.log("PICKER_MOTION_PASS cycles=" + root.cycles + " creations=" + root.creations)
                    Qt.quit()
                } else {
                    root.phase = "open"
                }
            } catch (error) {
                driver.stop()
                console.error("PICKER_MOTION_FAIL " + error)
                Qt.exit(1)
            }
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as ShellConfig
import "../../theme" as Theme
import "../../components" as Controls
import "../../adapters" as Adapters
import "../themes" as Themes

FocusScope {
    id: root

    required property string screenName
    required property Controls.InputState inputState
    signal closed()

    Theme.MonitorStyle {
        id: styleTokens
        palette: Theme.ActivePalettes.forOutput(root.screenName)
    }

    property string query: ""
    property int selectedIndex: -1
    property string statusText: ""
    readonly property bool closing: panelMotion.closing
    readonly property bool contextOpen: context.visible
    readonly property Controls.PanelContext contextPopup: context
    readonly property bool errorOpen: failures.visible
    readonly property Controls.ErrorPopup errorPopup: failures
    readonly property Themes.ThemeEditorPopup themeEditor: profilePopup
    readonly property Adapters.ComponentSettings componentSettings: componentOptions
    readonly property alias wallpaperView: grid
    property int failureSequence: 0
    property bool initialized: false
    // Hyprpaper uses the empty output for the configured default.
    readonly property var targets: [{ id: "", label: qsTr("Shared default") }].concat(Quickshell.screens.map(function(screen) {
        return { id: screen.name, label: screen.name }
    }))
    readonly property var filteredWallpapers: ShellConfig.GeneratedWallpapers.items.filter(function(wallpaper) {
        return !root.query || wallpaper.searchKey.includes(root.query.toLowerCase())
    })
    readonly property var selectedWallpaper: selectedIndex >= 0 && selectedIndex < filteredWallpapers.length
        ? filteredWallpapers[selectedIndex] : null
    readonly property bool applying: themeEditor.profileModel.operation === "save" || themeEditor.profileModel.loadOperation === "save"
    readonly property string savedPath: PickerState.savedPath(PickerState.targetOutput)
    readonly property string currentPath: PickerState.currentPath(PickerState.targetOutput)
    readonly property bool targetAvailable: targetIndexFor(PickerState.targetOutput) >= 0

    function targetIndexFor(output) {
        for (let index = 0; index < targets.length; index++) {
            if (targets[index].id === output)
                return index
        }
        return -1
    }

    function selectSaved() {
        selectedIndex = filteredWallpapers.findIndex(wallpaper => wallpaper.path === savedPath)
    }

    function choose(index) {
        if (!applying && !closing && !context.visible && !failures.visible && !themeEditor.visible && index >= 0 && index < filteredWallpapers.length)
            selectedIndex = index
    }

    function focusSelection() {
        if (!applying && !closing && !context.visible && !failures.visible && !themeEditor.visible)
            grid.forceActiveFocus()
    }

    function moveSelection(delta) {
        if (applying || closing || context.visible || failures.visible || themeEditor.visible || filteredWallpapers.length === 0)
            return
        grid.forceActiveFocus()
        choose(Math.max(0, Math.min(filteredWallpapers.length - 1, selectedIndex + delta)))
    }

    function chooseTheme() {
        if (!selectedWallpaper || applying || closing || context.visible || failures.visible || themeEditor.visible)
            return
        if (!targetAvailable) { reportUnavailableTarget(); return }
        themeEditor.begin({
            id: PickerState.targetOutput,
            label: PickerState.targetOutput || qsTr("Shared default"),
            folderId: selectedWallpaper.folderId,
            path: selectedWallpaper.path,
            name: selectedWallpaper.name,
            fitMode: PickerState.fitMode(PickerState.targetOutput)
        }, root.Window.window ? root.Window.window.activeFocusItem : grid)
    }

    function activate() {
        failures.close()
        context.close()
        themeEditor.resetDraft()
        componentOptions.refresh()
        inputState.keyboardUsed()
        query = ""
        selectSaved()
        statusText = ""
        grid.forceActiveFocus()
        panelMotion.enter()
        if (!targetAvailable) reportUnavailableTarget()
        else if (!selectedWallpaper) reportFailure(qsTr("Open saved wallpaper"), qsTr("Saved wallpaper unavailable"),
            qsTr("The saved wallpaper is not in the configured collections. Choose another image or correct the folder configuration."),
            savedPath, PickerState.targetOutput || qsTr("Shared default"), grid)
    }

    function requestClose() {
        if (themeEditor.visible) { if (!themeEditor.profileModel.busy) themeEditor.close(); return }
        if (failures.visible) { failures.close(); return }
        if (context.visible) { context.close(); return }
        if (applying || closing || !visible)
            return
        panelMotion.leave()
    }
    function reportFailure(operation, title, message, details, target, previousFocus) {
        failureSequence += 1
        failures.present({ source: "wallpaper", sequence: failureSequence, title: title,
            message: message, operation: operation, target: target, details: details }, previousFocus)
    }
    function reportUnavailableTarget() {
        reportFailure(qsTr("Select wallpaper output"), qsTr("Wallpaper output unavailable"),
            qsTr("The selected output is no longer connected. Choose an available output; no wallpaper was changed."),
            "", PickerState.targetOutput || qsTr("Shared default"), root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    onTargetAvailableChanged: {
        if (initialized && visible && !targetAvailable && !applying) reportUnavailableTarget()
    }

    onQueryChanged: {
        if (!query) selectSaved()
        else selectedIndex = filteredWallpapers.findIndex(wallpaper => wallpaper.searchKey.includes(query.toLowerCase()))
    }
    onSavedPathChanged: selectSaved()
    Connections {
        target: PickerState
        function onTargetOutputChanged() {
            root.query = ""
            root.selectSaved()
            grid.forceActiveFocus()
        }
    }
    onSelectedIndexChanged: {
        if (selectedIndex >= 0)
            grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }
    Component.onCompleted: {
        initialized = true
        if (visible)
            activate()
    }
    function handleKey(event) {
        inputState.keyboardUsed()
        if (themeEditor.visible) { themeEditor.handleKey(event); return }
        if (event.key === ShellConfig.ThemeEditor.openKey && event.modifiers === ShellConfig.ThemeEditor.openModifiers
            && !applying && !closing && !context.visible && !failures.visible) {
            root.chooseTheme()
            event.accepted = true
            return
        }
        if (failures.visible) {
            if (event.key === ShellConfig.ErrorPanels.dismissKey) failures.close()
            else if (event.key === ShellConfig.ErrorPanels.copyKey && event.modifiers === ShellConfig.ErrorPanels.copyModifiers)
                failures.copyDiagnostic()
            event.accepted = true
            return
        }
        if (context.handleShortcut(event)) return
        if (context.visible) {
            if (event.key === ShellConfig.Keyboard.cancelKey) context.close()
            event.accepted = true
            return
        }
        if (event.key === ShellConfig.Keyboard.searchKey && event.modifiers === ShellConfig.Keyboard.searchModifiers) {
            pickerHeader.searchField.forceActiveFocus()
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.cancelKey) {
            root.requestClose()
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.applyKey || event.key === ShellConfig.Keyboard.alternateApplyKey) {
            root.chooseTheme()
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.previousKey) {
            root.moveSelection(-1)
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.nextKey) {
            root.moveSelection(1)
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.rowUpKey) {
            root.moveSelection(-grid.columns)
            event.accepted = true
        } else if (event.key === ShellConfig.Keyboard.rowDownKey) {
            root.moveSelection(grid.columns)
            event.accepted = true
        }
    }
    Keys.onPressed: event => root.handleKey(event)

    function showContext(kind) {
        if (applying || closing || failures.visible || themeEditor.visible) return
        if (kind === "info") {
            if (pickerHeader.targetFocused) {
                context.infoTitle = PickerState.targetOutput || qsTr("Shared default")
                context.infoDescription = PickerState.targetOutput
                    ? qsTr("The wallpaper and generated colors are stored for this exact output.")
                    : qsTr("The configured default applies to displays without a wallpaper override.")
                context.infoDetails = [{ label: qsTr("Fit"), value: PickerState.fitMode(PickerState.targetOutput) }]
            } else {
                context.infoTitle = selectedWallpaper ? selectedWallpaper.name : qsTr("No wallpaper selected")
                context.infoDescription = selectedWallpaper && selectedWallpaper.path === currentPath
                    ? qsTr("Currently applied wallpaper") : ""
                context.infoDetails = selectedWallpaper ? [
                    { label: qsTr("Folder"), value: selectedWallpaper.folderId },
                    { label: qsTr("File"), value: selectedWallpaper.path },
                    { label: qsTr("Target"), value: PickerState.targetOutput || qsTr("Shared default") },
                    { label: qsTr("Fit"), value: PickerState.fitMode(PickerState.targetOutput) }
                ] : []
            }
        }
        context.show(kind, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Adapters.ComponentSettings {
        id: componentOptions
        component: "wallpaper"
        screenName: root.screenName
        onFailed: failures.present(componentOptions.failure, root.Window.window ? root.Window.window.activeFocusItem : null)
    }
    Controls.PanelContext {
        id: context
        owner: root
        style: styleTokens
        inputState: root.inputState
        settings: componentOptions
        shortcutsEnabled: !failures.visible && !root.themeEditor.visible
        bindings: [
            { key: ShellConfig.Keyboard.previousKey, modifiers: Qt.NoModifier, action: qsTr("Previous wallpaper") },
            { key: ShellConfig.Keyboard.nextKey, modifiers: Qt.NoModifier, action: qsTr("Next wallpaper") },
            { key: ShellConfig.Keyboard.rowUpKey, modifiers: Qt.NoModifier, action: qsTr("Previous row") },
            { key: ShellConfig.Keyboard.rowDownKey, modifiers: Qt.NoModifier, action: qsTr("Next row") },
            { key: ShellConfig.Keyboard.applyKey, modifiers: Qt.NoModifier, action: qsTr("Choose colors for this wallpaper") },
            { key: ShellConfig.Keyboard.searchKey, modifiers: ShellConfig.Keyboard.searchModifiers, action: qsTr("Focus search") },
            { key: ShellConfig.Keyboard.infoKey, modifiers: ShellConfig.Keyboard.contextModifiers, action: qsTr("Selection or target information") },
            { key: ShellConfig.Keyboard.helpKey, modifiers: ShellConfig.Keyboard.contextModifiers, action: qsTr("Component keys") },
            { key: ShellConfig.Keyboard.settingsKey, modifiers: ShellConfig.Keyboard.contextModifiers, action: qsTr("Component settings") },
            { key: ShellConfig.ThemeEditor.openKey, modifiers: ShellConfig.ThemeEditor.openModifiers, action: qsTr("Edit wallpaper and palette profile") },
            { key: Qt.Key_Tab, modifiers: Qt.NoModifier, action: qsTr("Next control") },
            { key: ShellConfig.Keyboard.cancelKey, modifiers: Qt.NoModifier, action: qsTr("Dismiss popup, then panel") }
        ]
        onRequested: kind => root.showContext(kind)
    }
    Controls.ErrorPopup {
        id: failures
        owner: root
        style: styleTokens
        inputState: root.inputState
    }
    Themes.ThemeEditorPopup {
        id: profilePopup
        owner: root
        style: styleTokens
        inputState: root.inputState
        screenName: root.screenName
        onApplied: panelMotion.leave()
    }

    Controls.PanelMotion {
        id: panelMotion
        surface: root
        onClosed: { root.themeEditor.resetDraft(); root.closed() }
    }

    Controls.PointerTracker {
        inputState: root.inputState
    }

    Rectangle {
        anchors.fill: parent
        color: styleTokens.scrimColor(ShellConfig.ContextPanels.scrimOpacity)

        MouseArea {
            anchors.fill: parent
            onClicked: root.requestClose()
        }
    }

    Rectangle {
        id: card
        objectName: "wallpaperPanelCard"

        width: Math.min(parent.width - styleTokens.spacing * ShellConfig.WallpaperPicker.outerSpacingUnits, ShellConfig.WallpaperPicker.maximumWidth)
        height: Math.min(parent.height - styleTokens.spacing * ShellConfig.WallpaperPicker.outerSpacingUnits,
            ShellConfig.WallpaperPicker.maximumHeight,
            panelLayout.implicitHeight + styleTokens.spacing * ShellConfig.WallpaperPicker.innerSpacingUnits * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        y: ShellConfig.Placement.y(ShellConfig.WallpaperPicker.placement, parent.height, height, styleTokens.barHeight, styleTokens.spacing * ShellConfig.WallpaperPicker.outerSpacingUnits / 2)
        color: styleTokens.pickerSurface
        radius: styleTokens.pickerRadius
        border.width: Theme.Shape.borderWidth
        border.color: styleTokens.pickerBorder
        scale: panelMotion.cardScale

        MouseArea {
            anchors.fill: parent
            onClicked: function() {}
        }

        ColumnLayout {
            id: panelLayout
            anchors.fill: parent
            anchors.margins: styleTokens.spacing * ShellConfig.WallpaperPicker.innerSpacingUnits
            spacing: styleTokens.spacing

            PickerHeader {
                id: pickerHeader
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                nextFocus: grid
                previousFocus: pickerFooter.actionControl
                targets: root.targets
                targetIndex: root.targetIndexFor(PickerState.targetOutput)
                query: root.query
                busy: root.applying
                onQueryEdited: query => root.query = query
                onSearchKeyPressed: event => {
                    root.inputState.keyboardUsed()
                    if (context.handleShortcut(event)) return
                    if (event.key === ShellConfig.Keyboard.cancelKey || event.key === ShellConfig.Keyboard.applyKey
                        || event.key === ShellConfig.Keyboard.alternateApplyKey) root.handleKey(event)
                    else if (event.key === ShellConfig.Keyboard.rowDownKey) {
                        if (root.selectedIndex < 0 && root.filteredWallpapers.length) root.choose(0)
                        grid.forceActiveFocus()
                        event.accepted = true
                    } else event.accepted = false
                }
                onTargetChosen: index => {
                    if (index >= 0 && index < root.targets.length)
                        PickerState.targetOutput = root.targets[index].id
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                // Half-gaps keep the outer tile edges on the header/footer axes.
                Layout.leftMargin: -ShellConfig.WallpaperPicker.tileGap / 2
                Layout.rightMargin: -ShellConfig.WallpaperPicker.tileGap / 2
                Layout.preferredHeight: Math.min(componentOptions.maximumVisibleRows,
                    Math.max(1, Math.ceil(ShellConfig.GeneratedWallpapers.items.length / columns))) * cellHeight
                clip: true
                activeFocusOnTab: true
                currentIndex: root.selectedIndex
                keyNavigationEnabled: false
                KeyNavigation.priority: KeyNavigation.AfterItem
                KeyNavigation.tab: pickerFooter.actionControl
                KeyNavigation.backtab: pickerHeader.targetControl
                enabled: !root.applying
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleKey(event)
                model: root.filteredWallpapers
                cellWidth: width / columns
                cellHeight: ShellConfig.WallpaperPicker.cellHeight
                readonly property int columns: Math.min(componentOptions.wideColumns,
                    width >= ShellConfig.WallpaperPicker.wideGridThreshold ? componentOptions.wideColumns
                    : width >= ShellConfig.WallpaperPicker.mediumGridThreshold ? ShellConfig.WallpaperPicker.narrowColumns
                    : width >= ShellConfig.WallpaperPicker.smallGridThreshold ? ShellConfig.WallpaperPicker.smallColumns
                    : ShellConfig.WallpaperPicker.minimumColumns)

                delegate: Item {
                    id: cell
                    required property int index
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    WallpaperTile {
                        anchors.fill: parent
                        anchors.margins: ShellConfig.WallpaperPicker.tileGap / 2
                        style: styleTokens
                        inputState: root.inputState
                        wallpaper: cell.modelData
                        selected: cell.index === root.selectedIndex
                        current: cell.modelData.path === root.currentPath
                        keyboardCandidate: grid.activeFocus && !root.contextOpen && !root.errorOpen
                        onChosen: {
                            root.choose(cell.index)
                            root.focusSelection()
                        }
                        onActivated: {
                            root.choose(cell.index)
                            root.chooseTheme()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.filteredWallpapers.length === 0
                    text: qsTr("No wallpapers match this search.")
                    color: styleTokens.textMuted
                    font.pointSize: styleTokens.bodyPointSize
                }
            }

            PickerFooter {
                id: pickerFooter
                Layout.fillWidth: true
                style: styleTokens
                inputState: root.inputState
                nextFocus: pickerHeader.searchField
                previousFocus: grid
                statusText: root.applying ? root.statusText : ""
                busy: root.applying
                canContinue: root.selectedWallpaper !== null && root.targetAvailable && !root.themeEditor.visible
                onThemeRequested: root.chooseTheme()
            }
        }
    }

}

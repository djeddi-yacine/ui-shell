//@ pragma ShellId ui-shell-launcher-test
pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "modules/apps" as Apps
import "components" as Controls
import "config" as Config

ShellRoot {
    id: root
    Component.onCompleted: Quickshell.watchFiles = Config.Config.watchSourceFiles
    readonly property var output: Quickshell.screens.length ? Quickshell.screens[0] : null
    property string phase: "open"
    property var firstPanel: null
    property int closes: 0
    property double deadline: Date.now() + 30000
    property double openedAt: 0
    property var openTimes: []
    property int contextIndex: -1
    property string capturePath: "/artifacts/frame-launcher.png"
    property string captureNextPhase: "failure"
    property string outputSettingsPath: ""
    property string defaultSettingsPath: ""
    property string cancelRevision: ""
    property bool contextualChecksDone: false
    property bool searchCandidateChecked: false
    property bool baselineCaptured: false
    property var observedFailure: null
    property var interruptedFocus: null
    property var interruptedEditor: null
    property var errorDraft: null
    property string expectedDiagnostic: ""
    property string clipboardBefore: "private launcher clipboard: & <123>"
    property real editorHeightBeforeError: 0
    property real cardHeightBeforeError: 0
    property var launchGeometry: null
    property int errorCandidate: -1
    property var runnerInterruptedFocus: null
    property string settingsReader: ""
    property bool tickRunning: false
    property bool filterMotionDone: false
    property int filterStep: 0
    property int filterTicks: 0
    property double filterLastChange: 0
    readonly property var filterQueries: ["e", "ei", "e", "", "zq", "", "a", "ab", "a", ""]
    function nextPhase(name) {
        phase = name
        deadline = Date.now() + 30000
    }
    function key(keyCode, modifiers) {
        const event = { key: keyCode, modifiers: modifiers, accepted: false }
        surface.panel.handleKey(event)
        return event
    }
    function editor() { return surface.panel.contextPopup.editor }
    // Computed colors carry float precision; compare to well under one 8-bit step.
    function sameColor(first, second) {
        return Math.abs(first.r - second.r) < 0.002 && Math.abs(first.g - second.g) < 0.002
            && Math.abs(first.b - second.b) < 0.002 && Math.abs(first.a - second.a) < 0.002
    }
    function check(condition, message) {
        if (!condition) throw new Error(message)
    }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) {
            const found = find(child, name)
            if (found) return found
        }
        return null
    }
    function findAll(item, name, found = []) {
        if (item.objectName === name) found.push(item)
        for (const child of item.children || []) findAll(child, name, found)
        return found
    }
    function hasVisibleStartingText(item) {
        if (item.visible && item.text !== undefined && String(item.text).startsWith("Starting ")) return true
        for (const child of item.children || [])
            if (root.hasVisibleStartingText(child)) return true
        return false
    }
    function launchLayout(panel) {
        const card = root.find(panel, "appPanelCard")
        const search = root.find(panel, "appSearchInput")
        const list = root.find(panel, "appList")
        const row = root.find(panel, "appEntryRow")
        const label = root.find(panel, "appEntryLabel")
        const cardPosition = card.mapToItem(panel, 0, 0)
        const searchPosition = search.mapToItem(panel, 0, 0)
        const listPosition = list.mapToItem(panel, 0, 0)
        const rowPosition = row.mapToItem(panel, 0, 0)
        const labelPosition = label.mapToItem(panel, 0, 0)
        return { cardX: cardPosition.x, cardY: cardPosition.y, cardWidth: card.width, cardHeight: card.height,
            searchX: searchPosition.x, searchY: searchPosition.y, searchWidth: search.width,
            listX: listPosition.x, listY: listPosition.y, listWidth: list.width,
            rowX: rowPosition.x, rowY: rowPosition.y, rowWidth: row.width, rowHeight: row.height,
            labelX: labelPosition.x, labelWidth: label.width, labelText: label.text,
            labelWeight: label.font.weight }
    }
    function assertLaunchLayout(panel) {
        const current = root.launchLayout(panel)
        for (const key of Object.keys(root.launchGeometry))
            root.check(Math.abs(current[key] - root.launchGeometry[key]) < 0.5
                || current[key] === root.launchGeometry[key], "launch changed row/panel geometry or label: " + key)
    }
    function enter() {
        const event = { key: Config.Keyboard.applyKey, modifiers: Qt.NoModifier, accepted: false }
        surface.panel.handleKey(event)
        check(event.accepted && surface.panel.busy, "Enter did not start app2unit")
    }
    Controls.InputState { id: input; pointerActive: false }
    Apps.AppSurface {
        id: surface
        modelData: root.output
        inputState: input
        TestCase { id: nativeKeys; when: false }
        TextEdit { id: clipboardProbe; visible: false; textFormat: TextEdit.PlainText }
    }
    Connections { target: surface.panel; function onClosed() { root.closes += 1 } }
    Process {
        id: capture
        command: ["grim", "-o", root.output ? root.output.name : "", root.capturePath]
        onExited: function(exitCode) {
            if (exitCode !== 0) { console.error("LAUNCHER_FAIL frame capture"); Qt.exit(1) }
            root.nextPhase(root.captureNextPhase)
        }
    }
    Timer {
        id: poll
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (root.tickRunning) return
            root.tickRunning = true
            try {
                root.check(Date.now() < root.deadline, "launcher deadline exceeded: " + root.phase
                    + ", busy=" + (surface.panel ? surface.panel.busy : "no panel")
                    + ", error=" + (surface.panel ? surface.panel.error : "")
                    + ", settingsLoadError=" + (surface.panel ? surface.panel.componentSettings.loadError : "")
                    + ", settingsSaveError=" + (surface.panel ? surface.panel.componentSettings.saveError : "")
                    + ", open=" + Apps.AppState.open + ", closes=" + root.closes)
                if (!root.output) return
                if (root.phase === "open") {
                    root.openedAt = Date.now()
                    Apps.AppState.show(root.output.name)
                    root.phase = "ready"
                    return
                }
                const panel = surface.panel
                if (!panel || panel.width <= 0
                    || (panel.matches.length === 0 && root.phase !== "search-empty" && root.phase !== "filter-motion")) return
                if (root.phase === "ready") {
                    if (!panel.componentSettings.ready || panel.componentSettings.loading) return
                    const search = root.find(panel, "appSearchInput")
                    root.check(search && search.activeFocus, "launcher did not focus search")
                    root.check(panel.selectedEntry !== null, "opening candidate missing")
                    root.check(panel.componentSettings.showIcons === true && panel.componentSettings.visibleRows === 12,
                        "initial launcher settings did not retain static icons-on/12-row defaults")
                    root.check(panel.pageSize >= 10, "launcher still shows too few complete rows: " + panel.pageSize)
                    if (!root.filterMotionDone) { root.nextPhase("filter-motion"); return }
                    if (!root.searchCandidateChecked) {
                        search.text = "ui-shell-no-matching-app"
                        root.nextPhase("search-empty")
                        return
                    }
                    const originalIndex = panel.selectedIndex
                    const list = panel.applicationView
                    const originalQuery = panel.query
                    const pointerIndex = originalIndex + 1 < panel.matches.length ? originalIndex + 1 : originalIndex - 1
                    const selectedRow = list.itemAtIndex(originalIndex)
                    const pointerRow = list.itemAtIndex(pointerIndex)
                    root.check(selectedRow && pointerRow, "launcher requires two visible rows for pointer/keyboard arbitration")
                    const selectedLabel = root.find(selectedRow, "appEntryLabel")
                    const pointerLabel = root.find(pointerRow, "appEntryLabel")
                    list.forceActiveFocus()
                    nativeKeys.mouseMove(pointerRow, pointerRow.width / 2, pointerRow.height / 2)
                    nativeKeys.mouseMove(pointerRow, pointerRow.width / 2 + 1, pointerRow.height / 2)
                    root.check(input.pointerActive && panel.selectedIndex === originalIndex
                        && list.activeFocus && selectedRow.keyboardCandidate
                        && root.sameColor(selectedLabel.color, selectedRow.style.controls.selectionText)
                        && !pointerRow.selected
                        // The pointer row only hovers (its own colour); the keyboard keeps the selection.
                        && pointerRow.hoverShown && root.sameColor(pointerLabel.color, pointerRow.style.controls.hoverText),
                        "pointer movement changed or obscured the keyboard-owned launcher candidate: "
                            + JSON.stringify({ pointer: input.pointerActive, index: panel.selectedIndex,
                                focus: list.activeFocus, selected: selectedRow.keyboardCandidate,
                                selectedText: String(selectedLabel.color), expectedSelected: String(selectedRow.style.controls.selectionText),
                                pointerSelected: pointerRow.selected,
                                pointerText: String(pointerLabel.color), expectedPointerText: String(pointerRow.style.controls.text) }))
                    nativeKeys.keyClick(Config.AppLauncher.nextKey)
                    root.check(!input.pointerActive
                        && panel.selectedIndex === Math.min(panel.matches.length - 1, originalIndex + 1),
                        "keyboard navigation did not resume from the retained launcher candidate")
                    panel.choose(originalIndex)
                    search.forceActiveFocus()
                    for (let cycle = 0; cycle < 3; cycle++) {
                        input.pointerUsed()
                        nativeKeys.keyClick(Qt.Key_Tab)
                        root.check(list.activeFocus && !search.activeFocus
                            && panel.selectedIndex === originalIndex && panel.query === originalQuery,
                            "native launcher Tab lost exclusive list focus or changed candidate/query")
                        root.check(!input.pointerActive, "Tab retained pointer-only hover feedback")
                        const candidate = list.itemAtIndex(panel.selectedIndex)
                        root.check(candidate && !candidate.activeFocus && !candidate.activeFocusOnTab
                            && candidate.keyboardCandidate, "application delegate focus mismatch: "
                                + JSON.stringify({ exists: !!candidate, focus: candidate ? candidate.activeFocus : null,
                                    tab: candidate ? candidate.activeFocusOnTab : null,
                                    candidate: candidate ? candidate.keyboardCandidate : null,
                                    view: list.activeFocus, index: panel.selectedIndex, current: list.currentIndex }))
                        nativeKeys.keyClick(Qt.Key_Tab)
                        root.check(search.activeFocus && !list.activeFocus && !candidate.keyboardCandidate
                            && panel.selectedIndex === originalIndex && panel.query === originalQuery,
                            "native launcher Tab retained stale candidate focus or inserted Tab text")
                        nativeKeys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
                        root.check(list.activeFocus && !search.activeFocus && panel.selectedIndex === originalIndex,
                            "native launcher Shift+Tab changed candidate or failed reverse navigation")
                        nativeKeys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
                        root.check(search.activeFocus && !list.activeFocus && !candidate.keyboardCandidate,
                            "native launcher Shift+Tab left two highlighted focus owners")
                    }
                    // A literal Tab payload must not pass through type-to-search.
                    list.forceActiveFocus()
                    const tabPayload = { key: Qt.Key_Tab, modifiers: Qt.NoModifier, text: "\t", accepted: false }
                    panel.handleKey(tabPayload)
                    root.check(!tabPayload.accepted && list.activeFocus && panel.query === originalQuery,
                        "launcher typing handler consumed a Tab as search input")
                    search.forceActiveFocus()
                    const pageEvent = { key: Config.AppLauncher.nextPageKey, modifiers: Qt.NoModifier, accepted: false }
                    panel.handleKey(pageEvent)
                    root.check(pageEvent.accepted && panel.selectedIndex === Math.min(panel.matches.length - 1, originalIndex + panel.pageSize), "PageDown did not advance one visible page")
                    panel.choose(originalIndex)
                    const row = root.find(panel, "appEntryRow")
                    const icon = row ? root.find(row, "appEntryIcon") : null
                    root.check(row && icon && row.showIcon === Config.AppLauncher.showIcons, "icon configuration was not composed")
                    const label = root.find(row, "appEntryLabel")
                    root.check(label && label.font.weight === row.style.bodyWeight,
                        "application selection changed the configured font weight")
                    panel.moveSelection(1)
                    root.check(label.font.weight === row.style.bodyWeight,
                        "application deselection changed the configured font weight")
                    panel.choose(originalIndex)
                    search.forceActiveFocus()
                    const searchPosition = search.mapToItem(panel, 0, 0)
                    const rowPosition = row.mapToItem(panel, 0, 0)
                    root.check(Math.abs(searchPosition.x - rowPosition.x) < 0.5
                        && Math.abs(search.width - row.width) < 0.5,
                        "search and application border rectangles do not share both alignment axes")
                    row.showIcon = false
                    root.check(!icon.visible && icon.source.toString() === "", "disabled icons still load images")
                    row.showIcon = Qt.binding(() => panel.componentSettings.showIcons)
                    root.check(!Apps.AppCatalog.index.some(item => item.entry.id === "org.uishell.launcher-hidden"), "NoDisplay entry leaked")
                    if (!root.firstPanel) root.firstPanel = panel
                    else root.check(root.firstPanel === panel && panel.query === "", "reopen rebuilt panel or retained query")
                    if (root.closes > 0) {
                        const rows = root.findAll(panel, "appEntryRow")
                        root.check(rows.every(item => {
                            const indicator = root.find(item, "appLaunchIndicator")
                            return !item.launching && !item.launchPulseRunning && indicator && !indicator.visible
                        }), "reopened launcher retained a stale launch indicator")
                    }
                    root.openTimes.push(Date.now() - root.openedAt)
                    if (!root.baselineCaptured) {
                        root.nextPhase("capture")
                        return
                    }
                    if (!root.contextualChecksDone) {
                        root.contextIndex = panel.selectedIndex
                        const infoEvent = root.key(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
                        root.check(infoEvent.accepted && panel.contextOpen, "Ctrl+I did not open contextual information")
                        root.nextPhase("info-open")
                        return
                    }
                    if (root.closes > 0) {
                        panel.requestClose()
                        panel.requestClose()
                        root.nextPhase("cancelled")
                    } else {
                        root.nextPhase("capture")
                        poll.interval = 200
                    }
                    return
                }
                if (root.phase === "filter-motion") {
                    // Change the query faster than the 200 ms row transitions finish, then let it settle.
                    const search = root.find(panel, "appSearchInput")
                    const list = panel.applicationView
                    root.check(search.activeFocus && !list.activeFocus, "filtering mid-transition moved focus away from search")
                    root.check(panel.selectedIndex === (panel.matches.length ? 0 : -1), "filtering mid-transition left a stale candidate")
                    if (root.filterStep < root.filterQueries.length) {
                        if (++root.filterTicks < 3) return
                        root.filterTicks = 0
                        search.text = root.filterQueries[root.filterStep++]
                        root.filterLastChange = Date.now()
                        return
                    }
                    if (Date.now() - root.filterLastChange < 700) return
                    root.check(list.count === panel.matches.length, "list count differs from the matches after settling")
                    let rows = 0
                    for (let index = 0; index < list.count; index++) {
                        const row = list.itemAtIndex(index)
                        if (!row) continue
                        root.check(row.index === index && row.entry === panel.matches[index], "row " + index + " shows the wrong entry after settling")
                        root.check(Math.abs(row.y - index * (row.height + list.spacing)) < 0.5, "row " + index + " did not settle in place: y=" + row.y)
                        root.check(row.opacity === 1, "row " + index + " stayed faded: " + row.opacity)
                        rows++
                    }
                    // Off-screen delegates may linger in the view's cache; stale means a duplicate or out-of-range row.
                    const children = list.contentItem.children.filter(child => child.objectName === "appEntryRow")
                    const seen = children.map(child => child.index)
                    root.check(seen.every((value, at) => value >= 0 && value < list.count && seen.indexOf(value) === at), "stale rows left in the list: " + JSON.stringify(seen))
                    root.check(panel.selectedIndex === (panel.matches.length ? 0 : -1) && panel.query === "", "settled list lost its candidate or query")
                    root.filterMotionDone = true
                    root.nextPhase("ready")
                    return
                }
                if (root.phase === "search-empty") {
                    if (panel.matches.length !== 0 || panel.selectedIndex !== -1) return
                    root.find(panel, "appSearchInput").text = "uishell fixture"
                    root.nextPhase("search-candidate")
                    return
                }
                if (root.phase === "search-candidate") {
                    if (panel.matches.length !== 1 || panel.selectedIndex !== 0) return
                    const candidate = panel.applicationView.itemAtIndex(0)
                    const label = candidate ? root.find(candidate, "appEntryLabel") : null
                    const background = candidate ? root.find(candidate, "appEntryBackground") : null
                    if (!candidate || !label || !background) return
                    root.check(panel.selectedEntry.id === "org.uishell.launcher.desktop"
                        && candidate.selected && candidate.candidateVisible && !candidate.keyboardCandidate,
                        "search did not expose its first result as the candidate while the search field owns focus")
                    root.check(root.sameColor(label.color, candidate.style.controls.selectionText),
                        "first search result lacks candidate text emphasis while search owns focus")
                    root.check(root.sameColor(background.color, candidate.style.controls.container),
                        "first search result lacks the candidate fill while search owns focus")
                    root.check(root.find(panel, "appSearchInput").text === panel.query,
                        "search field did not retain the active filtered query")
                    root.nextPhase("search-candidate-settled")
                    return
                }
                if (root.phase === "search-candidate-settled") {
                    root.capturePath = "/artifacts/frame-launcher-search-candidate.png"
                    root.captureNextPhase = "search-candidate-captured"
                    capture.running = true
                    root.nextPhase("search-candidate-capturing")
                    return
                }
                if (root.phase === "search-candidate-capturing") return
                if (root.phase === "search-candidate-captured") {
                    root.find(panel, "appSearchInput").text = ""
                    root.searchCandidateChecked = true
                    root.nextPhase("ready")
                    return
                }
                if (root.phase === "capture") {
                    if (panel.opacity !== 1) return
                    root.capturePath = "/artifacts/frame-launcher.png"
                    root.captureNextPhase = root.contextualChecksDone ? "failure" : "baseline-captured"
                    capture.running = true
                    root.nextPhase("capturing")
                    poll.interval = 20
                    return
                }
                if (root.phase === "capturing") return
                if (root.phase === "baseline-captured") {
                    root.baselineCaptured = true
                    root.contextIndex = panel.selectedIndex
                    const infoEvent = root.key(Config.Keyboard.infoKey, Config.Keyboard.contextModifiers)
                    root.check(infoEvent.accepted && panel.contextOpen, "Ctrl+I did not open contextual information")
                    root.nextPhase("info-open")
                    return
                }
                if (root.phase === "info-open") {
                    const popup = panel.contextPopup
                    if (!popup.opened) return
                    root.check(panel.contextOpen && popup.kind === "info" && popup.infoTitle === panel.selectedEntry.name
                        && popup.infoDetails.length >= 3, "selected app information content was missing")
                    const selected = panel.selectedIndex
                    const enterEvent = root.key(Config.Keyboard.applyKey, Qt.NoModifier)
                    const downEvent = root.key(Config.AppLauncher.nextKey, Qt.NoModifier)
                    root.check(enterEvent.accepted && downEvent.accepted && !panel.busy
                        && panel.selectedIndex === selected && selected === root.contextIndex,
                        "open information popup allowed launch or selection changes")
                    root.capturePath = "/artifacts/frame-launcher-info.png"
                    root.captureNextPhase = "info-captured"
                    capture.running = true
                    root.nextPhase("info-capturing")
                    return
                }
                if (root.phase === "info-capturing") return
                if (root.phase === "info-captured") {
                    const escapeEvent = root.key(Config.Keyboard.cancelKey, Qt.NoModifier)
                    root.check(escapeEvent.accepted, "Escape was not consumed by the popup")
                    root.nextPhase("info-closed")
                    return
                }
                if (root.phase === "info-closed") {
                    const search = root.find(panel, "appSearchInput")
                    if (panel.contextOpen || !search.activeFocus) return
                    root.check(panel.selectedIndex === root.contextIndex && panel.query === "",
                        "closing information changed candidate/query or failed to restore search focus")
                    const helpEvent = root.key(Config.Keyboard.helpKey, Config.Keyboard.contextModifiers)
                    root.check(helpEvent.accepted && panel.contextOpen, "Ctrl+Space did not open configured help")
                    root.nextPhase("help-open")
                    return
                }
                if (root.phase === "help-open") {
                    const bindings = panel.contextPopup.bindings
                    root.check(panel.contextPopup.kind === "help"
                        && bindings.some(binding => binding.key === Config.AppLauncher.nextKey && binding.action.length > 0)
                        && bindings.some(binding => binding.key === Config.Keyboard.settingsKey && binding.action.length > 0),
                        "configured help popup did not expose component keybindings")
                    root.check(root.key(Config.Keyboard.cancelKey, Qt.NoModifier).accepted, "Escape did not dismiss help")
                    root.nextPhase("help-closed")
                    return
                }
                if (root.phase === "help-closed") {
                    if (panel.contextOpen) return
                    const settingsEvent = root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.check(settingsEvent.accepted && panel.contextOpen, "Ctrl+E did not open component settings")
                    root.nextPhase("output-editor")
                    return
                }
                if (root.phase === "output-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable || !panel.contextPopup.opened) return
                    root.check(edit.scope === "output" && edit.file.ready && edit.revision === edit.file.revision,
                        "settings editor did not asynchronously load the output scope")
                    root.outputSettingsPath = edit.file.path
                    root.check(root.outputSettingsPath.startsWith(Config.GeneratedRuntime.paths.components
                        + "/launcher/"), "output settings escaped configured component root")
                    root.check(root.outputSettingsPath !== panel.componentSettings.fileForScope("default").path,
                        "default and output settings share a file path")
                    root.nextPhase("output-editor-settled")
                    return
                }
                if (root.phase === "output-editor-settled") {
                    root.capturePath = "/artifacts/frame-launcher-settings.png"
                    root.captureNextPhase = "dropdown-open"
                    capture.running = true
                    root.nextPhase("output-editor-capturing")
                    return
                }
                if (root.phase === "output-editor-capturing") return
                if (root.phase === "dropdown-open") {
                    const choice = root.find(root.editor(), "settingsChoice-showIcons")
                    root.check(choice && choice.currentIndex === 0, "opening dropdown choice did not reflect the default")
                    input.keyboardUsed()
                    choice.forceActiveFocus()
                    choice.popup.open()
                    root.nextPhase("dropdown-settled")
                    return
                }
                if (root.phase === "dropdown-settled") {
                    const choice = root.find(root.editor(), "settingsChoice-showIcons")
                    if (!choice.popup.opened) return
                    const option = choice.popup.contentItem.itemAtIndex(choice.currentIndex)
                    if (!option) return
                    root.check(option.currentChoice && option.keyboardCandidate && option.candidate,
                        "native dropdown did not preserve both committed choice and keyboard candidate")
                    root.check(option.background.border.width === 0 && option.background.border.color.a === 0,
                        "dropdown option painted a row border")
                    root.check(root.sameColor(option.foregroundColor, choice.style.controls.selectionText),
                        "dropdown keyboard candidate did not use its semantic foreground")
                    root.nextPhase("dropdown-capture")
                    return
                }
                if (root.phase === "dropdown-capture") {
                    root.capturePath = "/artifacts/frame-launcher-dropdown.png"
                    root.captureNextPhase = "dropdown-captured"
                    capture.running = true
                    root.nextPhase("dropdown-capturing")
                    return
                }
                if (root.phase === "dropdown-capturing") return
                if (root.phase === "dropdown-captured") {
                    root.find(root.editor(), "settingsChoice-showIcons").popup.close()
                    root.nextPhase("output-editor-captured")
                    return
                }
                if (root.phase === "output-editor-captured") {
                    if (root.find(root.editor(), "settingsChoice-showIcons").popup.visible) return
                    const edit = root.editor()
                    edit.setDraftAt(0, false)
                    edit.setDraftAt(1, 10)
                    root.check(panel.componentSettings.showIcons === Config.AppLauncher.showIcons
                        && panel.componentSettings.visibleRows === Config.AppLauncher.visibleRows,
                        "output draft edits changed effective launcher settings")
                    const saveButton = root.find(edit, "settingsSave")
                    const revision = edit.revision
                    const closes = root.closes
                    root.check(saveButton && saveButton.enabled, "output Save button was unavailable")
                    saveButton.forceActiveFocus()
                    nativeKeys.keyPress(Qt.Key_Return)
                    root.check(!panel.componentSettings.busy && edit.revision === revision
                        && panel.componentSettings.showIcons === Config.AppLauncher.showIcons
                        && panel.componentSettings.visibleRows === Config.AppLauncher.visibleRows,
                        "output settings saved on Enter press instead of release")
                    root.check(root.closes === closes && Apps.AppState.open,
                        "output settings Enter press launched or closed the parent launcher")
                    nativeKeys.keyRelease(Qt.Key_Return)
                    root.nextPhase("output-saved")
                    return
                }
                if (root.phase === "output-saved") {
                    if (panel.componentSettings.busy || panel.contextOpen) return
                    root.check(!panel.componentSettings.showIcons && panel.componentSettings.visibleRows === 10,
                        "saved output settings were not applied live")
                    const settingsEvent = root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.check(settingsEvent.accepted, "could not reopen settings for default scope")
                    root.nextPhase("default-editor")
                    return
                }
                if (root.phase === "default-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "default") { edit.loadScope("default"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.defaultSettingsPath = edit.file.path
                    root.check(root.defaultSettingsPath.startsWith(Config.GeneratedRuntime.paths.components
                        + "/launcher/") && root.defaultSettingsPath !== root.outputSettingsPath,
                        "default settings path is not distinct under private XDG_CONFIG_HOME")
                    edit.setDraftAt(0, true)
                    edit.setDraftAt(1, 8)
                    root.check(!panel.componentSettings.showIcons && panel.componentSettings.visibleRows === 10,
                        "default draft edits changed the active output override")
                    const saveButton = root.find(edit, "settingsSave")
                    const revision = edit.revision
                    const closes = root.closes
                    root.check(saveButton && saveButton.enabled, "default Save button was unavailable")
                    saveButton.forceActiveFocus()
                    nativeKeys.keyPress(Qt.Key_Enter, Qt.KeypadModifier)
                    root.check(!panel.componentSettings.busy && edit.revision === revision
                        && panel.componentSettings.showIcons === false && panel.componentSettings.visibleRows === 10,
                        "default settings saved on keypad Enter press instead of release")
                    root.check(root.closes === closes && Apps.AppState.open,
                        "default settings keypad Enter press launched or closed the parent launcher")
                    nativeKeys.keyRelease(Qt.Key_Enter, Qt.KeypadModifier)
                    root.nextPhase("default-saved")
                    return
                }
                if (root.phase === "default-saved") {
                    if (panel.componentSettings.busy || panel.contextOpen) return
                    root.check(panel.componentSettings.showIcons === false && panel.componentSettings.visibleRows === 10,
                        "shared settings overrode the more specific output settings")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.nextPhase("cancel-draft-editor")
                    return
                }
                if (root.phase === "cancel-draft-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "output") { edit.loadScope("output"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.cancelRevision = edit.revision
                    edit.setDraftAt(0, true)
                    edit.setDraftAt(1, 6)
                    root.check(panel.componentSettings.showIcons === false && panel.componentSettings.visibleRows === 10,
                        "cancelled output draft changed live settings")
                    root.check(root.key(Config.Keyboard.cancelKey, Qt.NoModifier).accepted,
                        "Escape did not dismiss settings with an uncommitted draft")
                    root.nextPhase("cancel-draft-closed")
                    return
                }
                if (root.phase === "cancel-draft-closed") {
                    if (panel.contextOpen) return
                    root.check(!panel.componentSettings.busy
                        && panel.componentSettings.fileForScope("output").revision === root.cancelRevision
                        && panel.componentSettings.showIcons === false && panel.componentSettings.visibleRows === 10,
                        "cancelling settings wrote the draft or changed live values")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.nextPhase("output-reset-editor")
                    return
                }
                if (root.phase === "output-reset-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "output") { edit.loadScope("output"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.check(edit.file.path === root.outputSettingsPath, "reopened output scope changed path")
                    edit.setDraftAt(0, undefined)
                    edit.setDraftAt(1, undefined)
                    edit.save()
                    root.nextPhase("output-reset")
                    return
                }
                if (root.phase === "output-reset") {
                    if (panel.componentSettings.busy || panel.contextOpen) return
                    root.check(panel.componentSettings.showIcons === true && panel.componentSettings.visibleRows === 8,
                        "undefined output values did not inherit default settings")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.nextPhase("reopened-editor")
                    return
                }
                if (root.phase === "reopened-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "output") { edit.loadScope("output"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.check(edit.draftAt(0) === undefined && edit.draftAt(1) === undefined
                        && edit.file.path === root.outputSettingsPath
                        && panel.componentSettings.showIcons === true && panel.componentSettings.visibleRows === 8,
                        "reopened editor did not show persisted inherited output settings")
                    const frozenRevision = edit.revision
                    panel.componentSettings.save("output", frozenRevision, [false, 10])
                    root.nextPhase("stale-external-save")
                    return
                }
                if (root.phase === "stale-external-save") {
                    if (panel.componentSettings.busy) return
                    const edit = root.editor()
                    root.check(edit && edit.revision !== panel.componentSettings.fileForScope("output").revision,
                        "external settings write did not advance the revision")
                    root.interruptedEditor = edit
                    root.errorDraft = { first: edit.draftAt(0), second: edit.draftAt(1), revision: edit.revision }
                    root.editorHeightBeforeError = edit.height
                    clipboardProbe.text = root.clipboardBefore
                    clipboardProbe.selectAll()
                    clipboardProbe.copy()
                    clipboardProbe.deselect()
                    edit.save()
                    root.nextPhase("stale-rejected")
                    return
                }
                if (root.phase === "stale-rejected") {
                    const edit = root.editor()
                    if (panel.componentSettings.busy || !panel.errorPopup.opened) return
                    root.check(panel.contextOpen && edit === root.interruptedEditor && edit.error.length > 0,
                        "stale settings save was accepted or closed its editor")
                    root.check(edit.height === root.editorHeightBeforeError && edit.draftAt(0) === root.errorDraft.first
                        && edit.draftAt(1) === root.errorDraft.second && edit.revision === root.errorDraft.revision,
                        "settings error resized the editor or discarded its draft")
                    root.observedFailure = panel.errorPopup.failure
                    root.interruptedFocus = panel.errorPopup.returnFocus
                    root.check(root.observedFailure.target.includes(root.output.name)
                        && panel.errorPopup.diagnostic.includes(root.outputSettingsPath), "settings failure lost its exact scope/file")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.key(Config.Keyboard.applyKey, Qt.NoModifier)
                    root.check(panel.errorOpen && root.editor() === root.interruptedEditor,
                        "error input replaced or submitted the scoped editor")
                    clipboardProbe.text = ""
                    clipboardProbe.paste()
                    root.capturePath = "/artifacts/frame-settings-error.png"
                    root.captureNextPhase = "settings-error-copy"
                    capture.running = true
                    root.nextPhase("settings-error-capturing")
                    return
                }
                if (root.phase === "settings-error-capturing") return
                if (root.phase === "settings-error-copy") {
                    root.check(clipboardProbe.text === root.clipboardBefore && !panel.errorPopup.copied,
                        "opening a settings failure overwrote the private clipboard")
                    root.expectedDiagnostic = panel.errorPopup.diagnostic
                    const copy = root.find(panel.errorPopup.contentItem, "errorCopy")
                    root.check(copy, "settings error Copy button was unavailable")
                    const closes = root.closes
                    copy.forceActiveFocus()
                    nativeKeys.keyPress(Qt.Key_Return)
                    root.check(!panel.errorPopup.copied && root.closes === closes && Apps.AppState.open,
                        "settings error Copy activated before Enter release or affected its parent")
                    nativeKeys.keyRelease(Qt.Key_Return)
                    clipboardProbe.text = ""
                    clipboardProbe.paste()
                    root.nextPhase("settings-error-copied")
                    return
                }
                if (root.phase === "settings-error-copied") {
                    if (clipboardProbe.text !== root.expectedDiagnostic) return
                    root.check(panel.errorPopup.copied, "settings error Copy was not acknowledged")
                    const dismiss = root.find(panel.errorPopup.contentItem, "errorDismiss")
                    root.check(dismiss, "settings error Dismiss button was unavailable")
                    const closes = root.closes
                    dismiss.forceActiveFocus()
                    nativeKeys.keyPress(Qt.Key_Enter, Qt.KeypadModifier)
                    root.check(panel.errorOpen && root.closes === closes && Apps.AppState.open,
                        "settings error dismissed before keypad Enter release or affected its parent")
                    nativeKeys.keyRelease(Qt.Key_Enter, Qt.KeypadModifier)
                    root.nextPhase("settings-error-dismissed")
                    return
                }
                if (root.phase === "settings-error-dismissed") {
                    if (panel.errorOpen) return
                    root.check(panel.contextOpen && root.editor() === root.interruptedEditor
                        && root.interruptedFocus.activeFocus && root.editor().draftAt(0) === root.errorDraft.first
                        && root.editor().draftAt(1) === root.errorDraft.second,
                        "error dismissal lost editor focus or its unsaved draft")
                    root.check(!panel.errorPopup.present(root.observedFailure, root.interruptedFocus) && !panel.errorOpen,
                        "observing the same settings failure reopened it")
                    root.editor().loadScope("output")
                    root.nextPhase("stale-reloaded")
                    return
                }
                if (root.phase === "stale-reloaded") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable || edit.revision !== edit.file.revision) return
                    root.check(edit.error.length === 0, "explicit reload did not clear the stale revision error")
                    edit.setDraftAt(0, true)
                    edit.setDraftAt(1, 6)
                    root.errorDraft = { first: edit.draftAt(0), second: edit.draftAt(1), revision: edit.revision }
                    root.interruptedEditor = edit
                    root.interruptedFocus = root.find(edit, "settingsScope")
                    root.interruptedFocus.forceActiveFocus()
                    root.settingsReader = Config.GeneratedRuntime.commands.readComponentSettings
                    Config.GeneratedRuntime.commands.readComponentSettings = "/usr/bin/false"
                    edit.file.refresh()
                    root.nextPhase("settings-load-failed")
                    return
                }
                if (root.phase === "settings-load-failed") {
                    if (!panel.errorPopup.opened) return
                    Config.GeneratedRuntime.commands.readComponentSettings = root.settingsReader
                    const edit = root.editor()
                    root.observedFailure = panel.errorPopup.failure
                    root.check(edit === root.interruptedEditor && panel.componentSettings.loadError.length > 0
                        && root.observedFailure.title === qsTr("Settings load failed")
                        && root.observedFailure.target.includes(root.output.name) && edit.draftAt(0) === root.errorDraft.first
                        && edit.draftAt(1) === root.errorDraft.second && edit.revision === root.errorDraft.revision,
                        "settings load failure lost scope, editor or draft")
                    root.key(Config.ErrorPanels.dismissKey, Qt.NoModifier)
                    root.nextPhase("settings-load-dismissed")
                    return
                }
                if (root.phase === "settings-load-dismissed") {
                    if (panel.errorOpen) return
                    root.check(panel.contextOpen && root.interruptedFocus.activeFocus
                        && !panel.errorPopup.present(root.observedFailure, root.interruptedFocus),
                        "settings load dismissal lost focus or reopened the failure")
                    root.editor().file.refresh()
                    root.nextPhase("settings-load-reloaded")
                    return
                }
                if (root.phase === "settings-load-reloaded") {
                    const edit = root.editor()
                    if (!edit.editable || edit.file.reading) return
                    root.check(edit.error.length === 0 && edit.draftAt(0) === root.errorDraft.first
                        && edit.draftAt(1) === root.errorDraft.second, "settings retry discarded the unsaved draft")
                    edit.setDraftAt(0, undefined)
                    edit.setDraftAt(1, undefined)
                    edit.save()
                    root.nextPhase("output-final-reset")
                    return
                }
                if (root.phase === "output-final-reset") {
                    if (panel.componentSettings.busy || panel.contextOpen) return
                    root.check(panel.componentSettings.showIcons === true && panel.componentSettings.visibleRows === 8,
                        "restoring output inheritance did not preserve default settings")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.nextPhase("default-final-reset-editor")
                    return
                }
                if (root.phase === "default-final-reset-editor") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "default") { edit.loadScope("default"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    edit.setDraftAt(0, undefined)
                    edit.setDraftAt(1, undefined)
                    edit.save()
                    root.nextPhase("default-final-reset")
                    return
                }
                if (root.phase === "default-final-reset") {
                    if (panel.componentSettings.busy || panel.contextOpen) return
                    root.check(panel.componentSettings.showIcons === Config.AppLauncher.showIcons
                        && panel.componentSettings.visibleRows === Config.AppLauncher.visibleRows,
                        "resetting private test settings did not restore static launcher defaults")
                    root.key(Config.Keyboard.settingsKey, Config.Keyboard.contextModifiers)
                    root.nextPhase("reset-confirm-default")
                    return
                }
                if (root.phase === "reset-confirm-default") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "default") { edit.loadScope("default"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.check(edit.draftAt(0) === undefined && edit.draftAt(1) === undefined
                        && edit.file.path === root.defaultSettingsPath,
                        "reopened default scope did not confirm inherited configured values/path")
                    edit.loadScope("output")
                    root.nextPhase("reset-confirm-output")
                    return
                }
                if (root.phase === "reset-confirm-output") {
                    const edit = root.editor()
                    if (!edit || edit.awaitingScope || !edit.editable) return
                    if (edit.scope !== "output") { edit.loadScope("output"); return }
                    if (!edit.file.ready || edit.revision !== edit.file.revision) return
                    root.check(edit.draftAt(0) === undefined && edit.draftAt(1) === undefined
                        && edit.file.path === root.outputSettingsPath
                        && root.defaultSettingsPath !== root.outputSettingsPath
                        && panel.componentSettings.showIcons === Config.AppLauncher.showIcons
                        && panel.componentSettings.visibleRows === Config.AppLauncher.visibleRows,
                        "reopened output scope did not confirm inherited values and distinct files")
                    root.check(root.key(Config.Keyboard.cancelKey, Qt.NoModifier).accepted,
                        "Escape did not close settings after confirming reset values")
                    root.nextPhase("reset-confirm-closed")
                    return
                }
                if (root.phase === "reset-confirm-closed") {
                    if (panel.contextOpen) return
                    root.contextualChecksDone = true
                    panel.query = ""
                    panel.selectedIndex = 0
                    root.check(panel.matches.length > 0 && panel.selectedEntry !== null,
                        "launcher candidate did not recover after contextual settings")
                    root.nextPhase("capture")
                    return
                }
                if (root.phase === "failure") {
                    panel.query = "uishell fixture"
                    root.check(panel.matches.length === 1 && panel.selectedEntry.id === "org.uishell.launcher.desktop", "native entry/search contract mismatch")
                    panel.runnerArguments = Config.AppLauncher.runnerArguments.concat(["--test", "--invalid-launcher-test-option"])
                    root.cardHeightBeforeError = root.find(panel, "appPanelCard").height
                    root.errorCandidate = panel.selectedIndex
                    root.runnerInterruptedFocus = root.find(panel, "appList")
                    root.runnerInterruptedFocus.forceActiveFocus()
                    root.enter()
                    root.nextPhase("failed")
                    return
                }
                if (root.phase === "failed") {
                    if (panel.busy || !panel.errorPopup.opened) return
                    root.check(panel.error.length > 0 && Apps.AppState.open && root.closes === 0 && panel.errorOpen,
                        "runner failure was hidden or closed UI")
                    const dismiss = root.find(panel.errorPopup.contentItem, "errorDismiss")
                    const copy = root.find(panel.errorPopup.contentItem, "errorCopy")
                    const diagnostics = panel.errorPopup.diagnosticsControl
                    const candidate = panel.applicationView.itemAtIndex(panel.selectedIndex)
                    root.check(dismiss.activeFocus && candidate && !candidate.keyboardCandidate,
                        "error popup retained underlying application focus emphasis")
                    nativeKeys.keyClick(Qt.Key_Tab)
                    root.check(copy.activeFocus && !dismiss.activeFocus && !diagnostics.activeFocus,
                        "native error Tab focused diagnostics or retained Dismiss focus")
                    nativeKeys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier)
                    root.check(dismiss.activeFocus && !copy.activeFocus && !diagnostics.activeFocus,
                        "native error Shift+Tab mismatch: " + JSON.stringify({ dismiss: dismiss.activeFocus,
                            copy: copy.activeFocus, diagnostics: diagnostics.activeFocus,
                            actual: panel.Window.window.activeFocusItem ? panel.Window.window.activeFocusItem.objectName : "none" }))
                    root.check(root.find(panel, "appPanelCard").height === root.cardHeightBeforeError
                        && panel.selectedIndex === root.errorCandidate, "runner failure changed main geometry or selection")
                    root.observedFailure = panel.errorPopup.failure
                    root.check(root.observedFailure.target === "org.uishell.launcher.desktop.desktop"
                        && panel.errorPopup.diagnostic.includes("app2unit") && panel.errorPopup.diagnostic.includes("Exit code:"),
                        "runner error lost desktop target or process diagnostics")
                    root.capturePath = "/artifacts/frame-launcher-error.png"
                    root.captureNextPhase = "runner-error-copy"
                    capture.running = true
                    root.nextPhase("runner-error-capturing")
                    return
                }
                if (root.phase === "runner-error-capturing") return
                if (root.phase === "runner-error-copy") {
                    root.expectedDiagnostic = panel.errorPopup.diagnostic
                    root.key(Config.ErrorPanels.copyKey, Config.ErrorPanels.copyModifiers)
                    clipboardProbe.text = ""
                    clipboardProbe.paste()
                    root.nextPhase("runner-error-copied")
                    return
                }
                if (root.phase === "runner-error-copied") {
                    if (clipboardProbe.text !== root.expectedDiagnostic) return
                    root.key(Config.ErrorPanels.dismissKey, Qt.NoModifier)
                    root.nextPhase("runner-error-dismissed")
                    return
                }
                if (root.phase === "runner-error-dismissed") {
                    if (panel.errorOpen) return
                    root.check(root.runnerInterruptedFocus.activeFocus && panel.selectedIndex === root.errorCandidate
                        && !panel.errorPopup.present(root.observedFailure, null), "runner error dismissal lost focus or reopened")
                    panel.errorPopup.present({ source: "test-long-diagnostic", sequence: 1,
                        title: "Long plain-text diagnostic", message: "Native copy must preserve the full transcript.",
                        operation: "Private clipboard regression", target: root.output.name,
                        details: "<not markup> & 0123456789\n".repeat(300) }, root.find(panel, "appSearchInput"))
                    root.nextPhase("long-error-open")
                    return
                }
                if (root.phase === "long-error-open") {
                    if (!panel.errorPopup.opened) return
                    root.expectedDiagnostic = panel.errorPopup.diagnostic
                    root.key(Config.ErrorPanels.copyKey, Config.ErrorPanels.copyModifiers)
                    clipboardProbe.text = ""
                    clipboardProbe.paste()
                    root.nextPhase("long-error-copied")
                    return
                }
                if (root.phase === "long-error-copied") {
                    if (clipboardProbe.text !== root.expectedDiagnostic) return
                    root.key(Config.ErrorPanels.dismissKey, Qt.NoModifier)
                    root.nextPhase("long-error-dismissed")
                    return
                }
                if (root.phase === "long-error-dismissed") {
                    if (panel.errorOpen) return
                    panel.runnerExecutable = "/usr/bin/bash"
                    panel.runnerArguments = ["/project/tests/scripts/launch-with-delay", "1.5", Config.AppLauncher.runnerExecutable]
                        .concat(Config.AppLauncher.runnerArguments, ["--test"])
                    const rows = root.findAll(panel, "appEntryRow")
                    root.check(rows.length === 1, "successful launch fixture did not resolve to exactly one row")
                    root.launchGeometry = root.launchLayout(panel)
                    root.enter()
                    root.nextPhase("launch-pending")
                    return
                }
                if (root.phase === "launch-pending") {
                    if (!panel.busy) return
                    const rows = root.findAll(panel, "appEntryRow")
                    root.check(rows.length === 1, "successful launch fixture did not retain exactly one row")
                    const indicator = root.find(rows[0], "appLaunchIndicator")
                    root.check(rows[0].entry.id === "org.uishell.launcher.desktop" && rows[0].launching
                        && indicator && indicator.visible
                        && rows[0].launchPulseRunning,
                        "pending launch did not show an active indicator on its target row")
                    root.check(indicator.contentItem.width === Config.AppLauncher.launchIndicatorSize
                        && indicator.contentItem.height === Config.AppLauncher.launchIndicatorSize,
                        "launch indicator padding consumed its painted dot")
                    root.check(!root.hasVisibleStartingText(panel),
                        "pending launch rendered a conditional Starting footer")
                    root.assertLaunchLayout(panel)
                    root.capturePath = "/artifacts/frame-launcher-starting.png"
                    root.captureNextPhase = "launch-pending-captured"
                    capture.running = true
                    root.nextPhase("launch-pending-capturing")
                    return
                }
                if (root.phase === "launch-pending-capturing") return
                if (root.phase === "launch-pending-captured") {
                    if (panel.busy) {
                        root.assertLaunchLayout(panel)
                        return
                    }
                    if (root.closes === 0) return
                    root.check(panel.error === "" && root.closes === 1,
                        "delayed app2unit dry-run did not complete as a single successful handoff")
                    panel.runnerExecutable = Config.AppLauncher.runnerExecutable
                    panel.runnerArguments = Config.AppLauncher.runnerArguments
                    root.nextPhase("launched")
                    return
                }
                if (root.phase === "launched") {
                    root.check(panel.busy || panel.error === "", "app2unit dry-run failed: " + panel.error)
                    if (panel.busy || root.closes === 0) return
                    root.check(root.closes === 1 && panel.error === "", "successful launch closed incorrectly")
                    root.check(panel.runnerOutput.includes("org.uishell.launcher.desktop.desktop")
                        && panel.runnerOutput.includes("Type=exec") && panel.runnerOutput.includes("one argument"), "real app2unit parser lost entry ID, service mode or argv")
                    root.nextPhase("open")
                    return
                }
                if (root.phase === "cancelled" && !Apps.AppState.open) {
                    root.check(root.closes === root.openTimes.length, "duplicate/missing close")
                    if (root.closes === 4) {
                        console.log("LAUNCHER_PASS " + JSON.stringify({ closes: root.closes, creations: 1, observedOpenMs: root.openTimes, runner: Config.AppLauncher.runnerExecutable + " --test", command: panel.runnerOutput }))
                        Qt.quit()
                    } else root.nextPhase("open")
                }
            } catch (error) {
                poll.stop()
                    console.error("LAUNCHER_FAIL " + error + "\n" + error.stack)
                Qt.exit(1)
            } finally {
                root.tickRunning = false
            }
        }
    }
}

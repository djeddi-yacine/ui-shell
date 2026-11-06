pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../components" as Controls
import "../../config" as Config
import "../../theme" as Theme

ColumnLayout {
    id: root
    required property var profileModel
    required property var style
    required property Controls.InputState inputState
    required property string screenName
    property string targetOutput: ""
    property string profileId: ""
    property string chosenProfile: ""
    property string source: ""
    property string mode: colors.mode
    property string sourceId: Config.ThemeEditor.initialSourceId
    property string definitionPath: ""
    property string customName: Config.ThemeEditor.initialCustomName
    property var colors: Theme.ActivePalettes.forOutput(screenName)
    property var selectedRole: null
    readonly property bool editable: profileModel.snapshotReady && !profileModel.busy
    readonly property bool custom: sourceId === "custom"
    readonly property var sourceChoices: (profileModel.snapshot ? profileModel.snapshot.palettes.map(theme =>
        ({ id: theme.path, label: theme.label, kind: "theme", path: theme.path })) : []).concat(Config.ThemeEditor.sources)
    readonly property var wallpaper: profileModel.snapshot ? profileModel.snapshot.draftWallpaper : null
    property var preservedDraft: null
    property var pendingSource: null
    // A source that failed to load keeps the combo highlighted, so keyboard
    // navigation moves on instead of snapping back. The draft stays the last
    // valid one, and Save is off until a source loads.
    property string failedCandidateId: ""
    readonly property bool sourceUnavailable: failedCandidateId !== ""
    // Unsaved edits: the draft differs from what it was when it was read or last saved.
    property string savedSignature: ""
    readonly property bool dirty: savedSignature !== "" && savedSignature !== draftSignature()
    function draftSignature() { return JSON.stringify([sourceId, customName, mode, colors]) }
    readonly property Controls.PaletteColorPicker colorPicker: colorPopup
    readonly property Controls.ShellButton primaryAction: saveAction
    signal saved()
    signal back()
    spacing: Config.ContextPanels.spacing

    function currentColors() {
        const snapshot = profileModel.snapshot
        return Object.prototype.hasOwnProperty.call(snapshot.byOutput, targetOutput)
            ? snapshot.byOutput[targetOutput] : snapshot.defaultPalette
    }
    function copyTheme(palette) {
        const result = Object.assign({}, palette)
        if (palette && palette.colors) result.colors = Object.assign({}, palette.colors)
        if (palette && palette.hyprland) result.hyprland = Object.assign({}, palette.hyprland)
        return result
    }
    function draft(palette) { colors = copyTheme(palette); mode = palette.mode }
    function keepDraft() {
        return { profileId: profileId, chosenProfile: chosenProfile, source: source,
            sourceId: sourceId, definitionPath: definitionPath, customName: customName, colors: copyTheme(colors) }
    }
    function restoreDraft(kept) {
        profileId = kept.profileId
        chosenProfile = kept.chosenProfile
        source = kept.source
        sourceId = kept.sourceId
        definitionPath = kept.definitionPath
        customName = kept.customName
        draft(kept.colors)
    }
    function readDraft() {
        const kept = preservedDraft
        preservedDraft = null
        pendingSource = null
        failedCandidateId = ""
        profileId = profileModel.snapshot.profileId
        chosenProfile = profileModel.snapshot.profilePath
        source = profileModel.snapshot.source
        definitionPath = Object.prototype.hasOwnProperty.call(profileModel.snapshot.definitionOverrides, targetOutput)
            ? profileModel.snapshot.definitionOverrides[targetOutput] : profileModel.snapshot.definition
        sourceId = source === "wallpaper" ? "wallpaper" : definitionPath || "custom"
        if (custom) customName = profileId
        draft(source === "wallpaper" ? wallpaper.colors : currentColors())
        if (kept) {
            restoreDraft(kept)
            if (source === "wallpaper") draft(wallpaper.colors)
        }
        savedSignature = draftSignature()
    }
    function begin(selection) {
        const previous = wallpaper
        if (previous && profileModel.snapshotReady && previous.id === selection.id
            && previous.folderId === selection.folderId && previous.name === selection.name
            && previous.fitMode === selection.fitMode) {
            sourceChoice.forceActiveFocus()
            return
        }
        preservedDraft = profileModel.snapshot && targetOutput === selection.id
            ? keepDraft() : null
        targetOutput = selection.id
        profileModel.wallpaperSelection = Object.assign({}, selection)
        profileModel.refresh(!!preservedDraft && preservedDraft.source === "wallpaper")
    }
    function resetDraft() {
        preservedDraft = null
        pendingSource = null
        failedCandidateId = ""
        profileId = ""
        chosenProfile = ""
        source = ""
        sourceId = Config.ThemeEditor.initialSourceId
        definitionPath = ""
        customName = Config.ThemeEditor.initialCustomName
    }
    function edit(role, color) { if (editable && custom) colors = Object.assign({}, colors, { [role]: color }) }
    function save() {
        if (editable && !sourceUnavailable && (!custom || name.acceptableInput))
            profileModel.save(profileId, targetOutput, source, mode,
                Object.assign(copyTheme(colors), { mode: mode }), custom, definitionPath)
    }
    function chooseSource(choice) {
        if (!editable || !choice) return
        failedCandidateId = ""
        sourceChoice.forceActiveFocus()
        if (choice.kind === "theme") {
            pendingSource = keepDraft()
            preservedDraft = null
            sourceId = choice.id
            profileModel.readPalette(choice.path)
        } else {
            const previous = keepDraft()
            sourceId = choice.id
            source = choice.kind === "wallpaper" ? "wallpaper" : "file"
            profileId = custom ? customName : profileModel.snapshot.profileId
            if (choice.kind === "wallpaper") definitionPath = ""
            if (source === "wallpaper" && !wallpaper.colors) {
                pendingSource = previous
                preservedDraft = keepDraft()
                profileModel.refresh(true)
                return
            }
            draft(source === "wallpaper" ? wallpaper.colors : colors)
        }
    }
    function focusedRole() {
        for (let index = 0; index < fields.count; index++) {
            const field = fields.itemAt(index) as Controls.PaletteColorField
            if (field && field.editorFocused) return field.role
        }
        return null
    }
    function focusedInfo() {
        const role = focusedRole()
        if (role) return { title: role.label, description: role.description,
            details: [{ label: qsTr("Color"), value: String(colors[role.key]) }] }
        if (sourceChoice.activeFocus) return { title: qsTr("Source"),
            description: qsTr("A saved theme loads only its custom colors for the picked wallpaper. Wallpaper generates colors from the image. Custom copies the preview colors so you can edit and name a theme. Nothing applies or creates a profile until Save and apply."),
            details: [{ label: qsTr("Source"), value: sourceChoice.currentText }] }
        if (name.activeFocus) return { title: qsTr("Theme name"),
            description: qsTr("Name this custom wallpaper/color theme using lowercase letters, digits and hyphens. A new name creates a theme. Use the loaded theme's name to edit it; another theme's name is rejected."),
            details: [{ label: qsTr("Name"), value: profileId }] }
        if (colorMode.activeFocus) return { title: qsTr("Palette mode"),
            description: qsTr("Dark or Light describes these custom colors; it does not invert them. Wallpaper colors use the explicitly configured generation mode."), details: [] }
        if (backAction.activeFocus) return { title: qsTr("Back"),
            description: qsTr("Return to the wallpaper picker and keep this draft. Closing the whole picker discards it without changing the desktop."), details: [] }
        if (saveAction.activeFocus) return { title: qsTr("Save and apply"),
            description: qsTr("Save and activate this wallpaper/color theme together for the target chosen in the wallpaper picker. Other display selections in the theme are preserved."), details: [] }
        return { title: qsTr("Theme"),
            description: qsTr("Everything here is a draft until Save and apply. Back keeps the draft; closing the picker discards it. The target stays the one chosen in the wallpaper picker."),
            details: [{ label: qsTr("Scope"), value: targetOutput || qsTr("Shared default") },
                { label: qsTr("Wallpaper"), value: wallpaper ? wallpaper.path : "" }] }
    }
    Theme.MonitorStyle { id: preview; palette: root.colors }
    Connections {
        target: root.profileModel
        function onReady() { root.readDraft(); sourceChoice.forceActiveFocus() }
        function onPaletteReady(palette) {
            root.pendingSource = null
            root.failedCandidateId = ""
            root.definitionPath = root.sourceId
            root.source = "file"
            root.profileId = root.profileModel.snapshot.profileId
            root.draft(palette)
            sourceChoice.forceActiveFocus()
        }
        function onFailed(failure) {
            if (!root.pendingSource) return
            const failedId = root.sourceId
            root.restoreDraft(root.pendingSource)
            root.failedCandidateId = failedId
            root.pendingSource = null
            root.preservedDraft = null
        }
        function onCommitted() { root.readDraft(); root.saved() }
    }
    Controls.ShellComboBox {
        id: sourceChoice
        objectName: "themeSourceChoice"
        Layout.fillWidth: true
        style: root.style
        inputState: root.inputState
        emphasis: Theme.Interaction.selectorEmphasis
        optionEmphasis: Theme.Interaction.selectorOptionEmphasis
        model: root.sourceChoices
        textRole: "label"
        currentIndex: model.findIndex(entry => entry.id === (root.failedCandidateId || root.sourceId))
        enabled: root.editable
        Accessible.name: qsTr("Source")
        onActivated: index => root.chooseSource(model[index])
    }
    RowLayout {
        visible: root.custom
        Layout.fillWidth: true
        spacing: Config.ContextPanels.spacing
        Controls.ShellTextField {
            id: name
            objectName: "themeName"
            Layout.fillWidth: true
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.inputEmphasis
            text: root.profileId
            placeholderText: qsTr("Theme name")
            maximumLength: 64
            validator: RegularExpressionValidator { regularExpression: /[a-z0-9]+(?:-[a-z0-9]+)*/ }
            Accessible.name: qsTr("Theme name")
            enabled: root.editable
            onTextEdited: { root.profileId = text; root.customName = text }
        }
        Controls.ShellComboBox {
            id: colorMode
            objectName: "themePaletteMode"
            Layout.minimumWidth: Config.ThemeEditor.modeFieldWidth
            Layout.preferredWidth: Config.ThemeEditor.modeFieldWidth
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.selectorEmphasis
            optionEmphasis: Theme.Interaction.selectorOptionEmphasis
            model: [{ label: qsTr("Dark"), value: "dark" }, { label: qsTr("Light"), value: "light" }]
            textRole: "label"
            currentIndex: model.findIndex(choice => choice.value === root.mode)
            enabled: root.editable
            Accessible.name: qsTr("Palette mode")
            onActivated: index => root.draft(Object.assign({}, root.colors, { mode: model[index].value }))
        }
    }
    Rectangle {
        objectName: "themePalettePreview"
        Layout.fillWidth: true
        Layout.preferredHeight: Config.ThemeEditor.previewHeight
        color: preview.background
        border.width: Theme.Shape.borderWidth
        border.color: preview.outline
        RowLayout {
            anchors.fill: parent
            anchors.margins: Config.ContextPanels.spacing
            spacing: Config.ContextPanels.spacing
            Image {
                Layout.preferredWidth: Config.ThemeEditor.previewHeight - Config.ContextPanels.spacing * 2
                Layout.fillHeight: true
                source: root.wallpaper ? "file://" + encodeURI(root.wallpaper.path).replace(/#/g, "%23").replace(/\?/g, "%3F") : ""
                sourceSize.width: Config.ThemeEditor.previewHeight
                sourceSize.height: Config.ThemeEditor.previewHeight
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                Accessible.name: root.wallpaper ? root.wallpaper.name : ""
            }
            Text {
                Layout.fillWidth: true
                text: root.wallpaper ? root.wallpaper.name : ""
                elide: Text.ElideRight
                color: preview.controls.text
                font.family: preview.uiFamily
                font.pointSize: preview.bodyPointSize
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: root.width >= Config.ThemeEditor.colorColumnsThreshold ? 2 : 1
        columnSpacing: Config.ContextPanels.spacing
        rowSpacing: Config.ContextPanels.spacing
        Repeater {
            id: fields
            model: Config.ThemeEditor.roles
            Controls.PaletteColorField {
                required property var modelData
                Layout.fillWidth: true
                role: modelData
                style: root.style
                inputState: root.inputState
                value: String(root.colors[modelData.key])
                enabled: root.editable && root.custom
                onEdited: color => root.edit(modelData.key, color)
                onPickRequested: {
                    root.selectedRole = modelData
                    colorPopup.begin(modelData, String(root.colors[modelData.key]), root.Window.window.activeFocusItem)
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Controls.ShellButton {
            id: backAction
            objectName: "themeDraftBack"
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.buttonEmphasis
            text: qsTr("Back")
            enabled: !root.profileModel.busy
            onClicked: root.back()
        }
        Item { Layout.fillWidth: true }
        Controls.ShellButton {
            id: saveAction
            objectName: "themeSave"
            text: root.profileModel.operation === "save" ? qsTr("Saving…") : qsTr("Save and apply")
            style: root.style
            inputState: root.inputState
            emphasis: Theme.Interaction.primaryActionEmphasis
            enabled: root.editable && !root.sourceUnavailable && (!root.custom || name.acceptableInput)
            onClicked: root.save()
        }
    }
    Controls.PaletteColorPicker {
        id: colorPopup
        owner: root
        style: root.style
        inputState: root.inputState
        onChosen: color => root.edit(root.selectedRole.key, color)
    }
}

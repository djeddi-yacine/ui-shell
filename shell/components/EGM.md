# Shell Components (UiShell.Components)

## Overview
Shared QML control and popup library for the shell, registered as module `UiShell.Components` by [qmldir](./qmldir) (21 types, all version 1.0). It provides input-mode tracking (pointer vs keyboard), themed controls (button, combo box, slider, text field), and the shared popup family (context, exit, error, colour picker, settings and tuning editors). All types take a `style` object and an `InputState`; colours and metrics come from `../theme` and `../config`.

## Interface
Input and state
- `InputState` [InputState.qml:InputState] QtObject; `required pointerActive`, `keyboardUsed()`, `pointerUsed()`.
- `PointerTracker` [PointerTracker.qml:PointerTracker] HoverHandler (mouse/touchpad only); calls `inputState.pointerUsed()` on real movement or press.
- `ShellControlState` [ShellControlState.qml:ShellControlState] extends `Theme.ControlState`; `control`, `inputState`, `alwaysShowFocus`, `focusVisible`.
- `ShellControlBackground` [ShellControlBackground.qml:ShellControlBackground] background driven by a `controlState`.
- `PanelMotion` [PanelMotion.qml:PanelMotion] `surface`, `offset`, `closing`, `closed()`, `enter()`, `leave()`, `reset()`.

Controls
- `ShellButton` [ShellButton.qml:ShellButton] Button; `style`, `emphasis`, `inputState` required; `selected`, `current`, `keyboardCandidate`, `activationKey`, `matchesActivation(event)`.
- `ShellComboBox` [ShellComboBox.qml:ShellComboBox] ComboBox; `style`, `emphasis`, `optionEmphasis`, `inputState` required; delegate is `ShellComboOption`.
- `ShellComboOption` [ShellComboOption.qml:ShellComboOption] `style`, `emphasis`, `inputState`, `currentChoice`, `keyboardCandidate` required.
- `ShellSlider` [ShellSlider.qml:ShellSlider] Slider; `style`, `inputState` required; `wheelAllowed`; `jumpTo(target)`.
- `ShellTextField` [ShellTextField.qml:ShellTextField] `style`, `emphasis`, `inputState` required; `pointerPressed`.
- `ShellEditingMenu` [ShellEditingMenu.qml:ShellEditingMenu] themed text edit context menu; `style` required.

Popups and panels
- `ContextPopup` [ContextPopup.qml:ContextPopup] modal Popup base; `owner`, `style`, `inputState` required; `kind`, `shortcutsEnabled`, `primaryAction`, `returnFocus`; `requested(kind)`, `handleShortcut(event)`, `show(kind, previousFocus)`.
- `PanelContext` [PanelContext.qml:PanelContext] ContextPopup showing settings/help/info panes; `settings`, `infoTitle`, `infoDescription`, `infoDetails`, `bindings` (required), `editor`, `unsaved`.
- `ExitDialog` [ExitDialog.qml:ExitDialog] ContextPopup; `title`, `message`, `confirmed()`, `request(unsaved, previousFocus)`, `confirm()`.
- `ErrorPopup` [ErrorPopup.qml:ErrorPopup] ContextPopup; `failure`, `copied`, `copiedDiagnostic()`, `present(failure, previousFocus)`, `copyDiagnostic()`.
- `PaletteColorPicker` [PaletteColorPicker.qml:PaletteColorPicker] ContextPopup with RGB channel sliders; `role`, `seedColor`, `channels`, `value`, `dirty`, `chosen(color)`, `begin(role, color, previousFocus)`, `requestClose()`.
- `PaletteColorField` [PaletteColorField.qml:PaletteColorField] row with swatch and hex field; `role`, `style`, `inputState`, `value` required; `edited(color)`, `pickRequested()`, `editorFocused`.
- `ComponentSettingsEditor` [ComponentSettingsEditor.qml:ComponentSettingsEditor] ColumnLayout; `settings` (`Adapters.ComponentSettings`), `style`, `inputState` required; `scope`, `dirty`, `editable`, `primaryAction`, `begin()`, `loadScope()`, `readDraft()`, `save()`, `saved()`.
- `ControlTuningEditor` [ControlTuningEditor.qml:ControlTuningEditor] schema-driven editor; `style`, `inputState`, `store` required; `draft`, `draftMode`, `modified`, `primaryAction`, `begin()`, `setValue()`, `applyMode()`, `reset()`, `discard()`, `save()`, `saved()`, `dismissed()`.
- `ContextHelp` [ContextHelp.qml:ContextHelp] `style`, `bindings` required; lists shortcuts via `Config.Keyboard.shortcut`.
- `ContextDetails` [ContextDetails.qml:ContextDetails] `style`, `title`, `description`, `details` required.

## Invariants
- Every control and popup requires `style` and `inputState` [ShellButton.qml:style/inputState], [ShellSlider.qml:style/inputState], [ShellComboBox.qml:style/inputState], [ContextPopup.qml:style/inputState]; they must be supplied, not defaulted.
- Hover is honoured only while the pointer is the active input; keyboard use clears it via `inputState.keyboardUsed()` [ShellControlState.qml:hovered], [InputState.qml:keyboardUsed]. Controls call `keyboardUsed()` in `Keys.onPressed` and `PointerTracker` calls `pointerUsed()` [ShellButton.qml:Keys.onPressed], [PointerTracker.qml:observe].
- Focus ring shows only when the keyboard drives (or `alwaysShowFocus` / `flags.focusVisible === "always"`) and the window is active [ShellControlState.qml:focusVisible].
- ShellButton activates on key release, only if still focused, enabled and visible, using `Config.Keyboard.buttonActivationKeys` / `buttonActivationModifiers`; `activationKey` resets on focus loss, disable or hide [ShellButton.qml:matchesActivation, Keys.onReleased].
- ShellComboBox: delegate model/activation stays native; key events are never accepted by the combo itself [ShellComboBox.qml:Keys.onPressed].
- ShellSlider: arrows step natively, Home/End are added via `jumpTo` using `increase()`/`decrease()` so bindings survive; dragging follows the pointer without glide; the wheel is captured only when `wheelAllowed` [ShellSlider.qml:jumpTo, glide, wheelAllowed].
- ContextPopup is modal, parented to `owner`, closes when `owner` becomes hidden, and restores focus to `returnFocus` on close only if it is still visible and enabled [ContextPopup.qml:onClosed, Connections].
- ContextPopup context shortcuts (`infoKey`, `helpKey`, `settingsKey` with `contextModifiers`) are active only when `shortcutsEnabled` and the owner is visible and enabled; the primary-action shortcut fires only while opened, focused and `primaryAction.enabled` [ContextPopup.qml:handleShortcut, Shortcut].
- ExitDialog rule: Esc (`Config.Keyboard.cancelKey`) confirms leaving; "Keep editing" is the primary action and initial focus; click outside only closes (keeps editing); `request(false)` confirms immediately without showing; shortcuts are disabled; `z: 2` [ExitDialog.qml:request, confirm, onOpened, closePolicy].
- PanelContext: with unsaved settings (`editor.dirty`) `closePolicy` is `NoAutoClose`, so only ExitDialog may close it; Esc routes to `exit.request(unsaved, ...)`; `settings` may be null for panels with their own controls [PanelContext.qml:unsaved, closePolicy, Keys.onPressed].
- PaletteColorPicker follows the same rule: dirty (`value` differs from `seedColor`) forces `NoAutoClose` and Esc goes through its ExitDialog (`z: 3`) [PaletteColorPicker.qml:dirty, requestClose, exit].
- ComponentSettingsEditor is editable only when `file.ready && !awaitingScope && !settings.busy && !file.error`; `save()` is a no-op otherwise; `dirty` compares drafts with `file.values` [ComponentSettingsEditor.qml:editable, dirty, save].
- ControlTuningEditor: rows come from `Theme.ControlTuning.schema` (no per-knob code); values are rounded to `knob.step`; destruction always calls `discard()` so the live preview draft never leaks [ControlTuningEditor.qml:setValue, Component.onDestruction].
- ErrorPopup.present throws unless the failure has `source`, integer `sequence >= 1`, `title`, `message`, `operation`, `target`, string `details`; a sequence not greater than the last seen for that `source` is ignored (returns false); unknown `Config.ErrorPanels.initialFocus` throws [ErrorPopup.qml:present, onOpened].
- Text from callers is rendered as `Text.PlainText` in ExitDialog [ExitDialog.qml:textFormat].

## Side Effects
- Motion: `Theme.Motion.active` gates all animations (instant when false) [ContextPopup.qml:enter/exit], [PanelMotion.qml:enter/leave], [ShellSlider.qml:glide].
- ErrorPopup.copyDiagnostic writes to the system clipboard through a hidden `TextEdit` (`selectAll/copy/deselect`) and sets `copied` [ErrorPopup.qml:copyDiagnostic].
- ComponentSettingsEditor refreshes the scope file (`settings.fileForScope(scope).refresh()`), clears `settings.saveError`, and persists via `settings.save(scope, revision, first, second)` [ComponentSettingsEditor.qml:loadScope, save].
- ControlTuningEditor writes live preview state to `Theme.ControlTuning.draft` / `draftMode`, and persists via `store.save(draftMode, draft)` [ControlTuningEditor.qml:setValue, applyMode, save].
- ContextPopup mutates focus (`previous.forceActiveFocus()`) on close and registers window-level `Shortcut`s [ContextPopup.qml:onClosed, Shortcut].
- No processes spawned and no files touched directly in this package; file/process access lives in `../adapters`.

## Verification
- Run: `make test-qml` (defined in `tests/targets.mk`, included by the root Makefile: lints QML and runs isolated Qt Quick Test suites)

import QtQuick
import "../theme" as Theme

// The one place a shell control or row declares its interaction state.
// Give it the owning style and, for a Qt control, the control itself: hover,
// press, focus and enabled follow that control, and hover is honoured only
// while the pointer (not the keyboard) is the active input. Override any flag
// a control computes differently (a keyboard candidate, a button's armed key).
//
//     ShellControlState { id: visual; style: root.style; control: root
//         inputState: root.inputState; emphasis: root.emphasis }
//     background: ShellControlBackground { controlState: visual }
//     contentItem: Text { color: visual.foreground }
//
// Rows and tiles that are not Qt controls omit `control` and set the flags.
Theme.ControlState {
    required property var style
    // Any Qt control (button, slider, combo box, text field): which of hovered, down and pressed it
    // has differs, so the flags below ask for them by name.
    property var control: null
    property InputState inputState: null
    // Focus is shown when the keyboard drives (or always, in modes that say so) (Tab, arrows), not after a mouse
    // click, and only in the window that actually has keyboard focus (a bar
    // button keeps its focus item while a launcher owns the keyboard). Text inputs set this true: an insertion field always shows focus.
    property bool alwaysShowFocus: false
    readonly property bool focusVisible: control ? control.activeFocus && control.Window.active && (alwaysShowFocus || flags.focusVisible === "always" || !inputState || !inputState.pointerActive) : false

    colors: style.controls
    enabled: control ? control.enabled : true
    hovered: control && inputState ? inputState.pointerActive && control.hovered === true : false
    pressed: control ? (control.down === true || control.pressed === true) : false
    focused: focusVisible
}

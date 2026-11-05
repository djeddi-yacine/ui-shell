import QtQuick

// Applies one style's typed control colors to a control's Qt palette. Qt's own
// default controls (the built-in text-editing context menu, tooltips, ...) read
// only palette roles, so declaring this inside a control or popup themes
// everything below it and leaves no default white surface behind. It is the one
// place that maps shell colors onto Qt palette roles.
//
//     Theme.ControlPalette { palette: root.palette; colors: root.style.controls }
QtObject {
    id: root
    required property var palette
    required property var colors

    property list<QtObject> bindings: [
        Binding { target: root.palette; property: "window"; value: root.colors.surface },
        Binding { target: root.palette; property: "windowText"; value: root.colors.text },
        Binding { target: root.palette; property: "base"; value: root.colors.surface },
        Binding { target: root.palette; property: "text"; value: root.colors.text },
        Binding { target: root.palette; property: "button"; value: root.colors.surface },
        Binding { target: root.palette; property: "buttonText"; value: root.colors.text },
        Binding { target: root.palette; property: "placeholderText"; value: root.colors.disabledText },
        Binding { target: root.palette; property: "highlight"; value: root.colors.selection },
        Binding { target: root.palette; property: "highlightedText"; value: root.colors.selectionText },
        // Menu item feedback and borders: highlighted, pressed, outline.
        Binding { target: root.palette; property: "light"; value: root.colors.hoverSurface },
        Binding { target: root.palette; property: "midlight"; value: root.colors.pressedSurface },
        Binding { target: root.palette; property: "mid"; value: root.colors.outline },
        Binding { target: root.palette; property: "dark"; value: root.colors.outline },
        Binding { target: root.palette; property: "shadow"; value: root.colors.palette.scrim },
        Binding { target: root.palette; property: "toolTipBase"; value: root.colors.surface },
        Binding { target: root.palette; property: "toolTipText"; value: root.colors.text }
    ]

    // Unavailable items (a disabled menu entry) fade instead of reading as enabled.
    // Setting a role through the base palette also resets its disabled group, so
    // the group is applied after the base roles and again whenever they change.
    function applyDisabled() {
        root.palette.disabled.text = root.colors.disabledText
        root.palette.disabled.windowText = root.colors.disabledText
        root.palette.disabled.buttonText = root.colors.disabledText
    }
    property Connections watcher: Connections {
        target: root.colors
        function onTextChanged() { root.applyDisabled() }
        function onDisabledTextChanged() { root.applyDisabled() }
    }
    Component.onCompleted: applyDisabled()
}

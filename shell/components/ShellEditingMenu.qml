import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls.Basic.impl as BasicImpl
import "../theme" as Theme

// Qt's Undo/Redo/Cut/Copy/Paste/Delete/Select All menu for a text editor, themed
// from the owning style. The menu is a popup, so it does not inherit its editor's
// palette: every text control gives its editor this menu instead of Qt's default.
//
//     ContextMenu.menu: ShellEditingMenu { editor: root; style: root.style }
BasicImpl.TextEditingContextMenu {
    id: root
    required property var style
    Theme.ControlPalette { palette: root.palette; colors: root.style.controls }
}

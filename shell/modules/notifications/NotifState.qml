pragma Singleton
import QtQuick

// Whether the drawer is open, and on which screen. Joins the panel group.
QtObject {
    property bool open: false
    property string screenName: ""
    function show(output) {
        screenName = output
        open = true
    }
    function toggle(output) {
        if (open) open = false
        else show(output)
    }
}

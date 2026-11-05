import QtQuick

QtObject {
    required property bool pointerActive

    function keyboardUsed() {
        pointerActive = false
    }

    function pointerUsed() {
        pointerActive = true
    }
}

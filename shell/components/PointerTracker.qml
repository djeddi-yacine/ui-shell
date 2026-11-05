import QtQuick

HoverHandler {
    id: root
    required property InputState inputState
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    property point previousPosition: Qt.point(0, 0)
    property bool positionKnown: false

    function observe() {
        if (!hovered)
            return
        const position = point.scenePosition
        if (point.pressedButtons !== Qt.NoButton || (positionKnown
            && (position.x !== previousPosition.x || position.y !== previousPosition.y)))
            inputState.pointerUsed()
        previousPosition = position
        positionKnown = true
    }

    // Enter/layout events seed a position, not a claim of physical mouse movement.
    onPointChanged: observe()
    onHoveredChanged: observe()
}

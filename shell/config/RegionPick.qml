pragma Singleton
import QtQuick

// The region picker overlay (modules/shot/RegionPickSurface.qml).
QtObject {
    // How dark the screen is outside the selection.
    readonly property real dimOpacity: 0.55
    readonly property int borderWidth: 4
    // Diameter of the round handles on the selection's corners.
    readonly property int handleSize: 22
}

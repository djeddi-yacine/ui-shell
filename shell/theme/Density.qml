pragma Singleton

import QtQuick

QtObject {
    readonly property string preset: "comfortable"

    readonly property int spacing: 12
    readonly property int controlHeight: 36
    readonly property int controlPaddingX: 12
    readonly property int controlPaddingY: 6
    readonly property int menuMaximumHeight: 288
    readonly property int menuViewportMargin: 12
    readonly property int barHeight: 32
    // Gaps and sizes derived from the base spacing and control height, so a denser or looser preset
    // moves all of them together. Components use these, never a literal.
    readonly property int spacingTight: Math.round(spacing * 2 / 3)
    readonly property int spacingLoose: Math.round(spacing * 3 / 2)
    readonly property int cardPadding: Math.round(spacing * 7 / 6)
    // A two-line row (a card, a patchbay node): one control height and a half.
    readonly property int rowHeight: Math.round(controlHeight * 3 / 2)
    readonly property int sliderHeight: Math.round(controlHeight * 0.7)
    readonly property int nodeSocketSize: spacing
    // A dropdown beside a label, and the readout of a percentage or a clock.
    readonly property int chooserWidth: Math.round(controlHeight * 5.5)
    readonly property int readoutWidth: Math.round(controlHeight * 4 / 3)
    // How many rows a scrolling list shows before it scrolls.
    readonly property int listVisibleRows: 6
}

//@ pragma ShellId ui-shell-test-application
import QtQuick
import Quickshell

ShellRoot {
    Window {
        visible: true
        width: 480
        height: 240
        title: "ui-shell test application"
        color: "#15151a"
        Text {
            anchors.centerIn: parent
            text: qsTr("Private app2unit scope")
            color: "#dedee8"
            font.pixelSize: 24
        }
    }
}

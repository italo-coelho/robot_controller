import QtQuick 2.15
import QtQuick.Layouts 1.15

Column {
    id: root
    spacing: 6

    property int enableState: -1

    signal resetClicked()
    signal toggleEnableClicked(int newState)

    Rectangle {
        width: 72
        height: 24
        radius: 12
        color: resetMouse.containsMouse ? "#C0392B" : "#DC3545"

        Text {
            anchors.centerIn: parent
            text: "Reset"
            font.pixelSize: 10
            font.bold: true
            color: "#ffffff"
            font.letterSpacing: 0.5
        }

        MouseArea {
            id: resetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.resetClicked()
        }
    }

    Rectangle {
        width: 72
        height: 24
        radius: 12
        color: {
            if (root.enableState === 1)
                return enableMouse.containsMouse ? "#E0A800" : "#FFC107"
            return enableMouse.containsMouse ? "#1E7E34" : "#28A745"
        }

        Text {
            anchors.centerIn: parent
            text: root.enableState === 1 ? "Disable" : "Enable"
            font.pixelSize: 10
            font.bold: true
            color: root.enableState === 1 ? "#333" : "#ffffff"
            font.letterSpacing: 0.5
        }

        MouseArea {
            id: enableMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleEnableClicked(root.enableState === 1 ? 0 : 1)
        }
    }
}

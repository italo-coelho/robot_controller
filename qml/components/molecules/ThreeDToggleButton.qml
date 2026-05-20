import QtQuick 2.15

Rectangle {
    id: root
    width: 72
    height: 54
    radius: 12
    color: threeDMouse.containsMouse ? "#E65A00" : "#FE6900"

    signal clicked()

    Text {
        anchors.centerIn: parent
        text: "3D"
        font.pixelSize: 14
        font.bold: true
        font.letterSpacing: 2
        color: "#FFFFFF"
    }

    MouseArea {
        id: threeDMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

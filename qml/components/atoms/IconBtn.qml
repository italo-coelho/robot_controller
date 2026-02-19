import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
 
Rectangle {
    id: iconBtn
    width: 40
    height: 40
    radius: 6
    color: hovered ? "#ffdddd" : "transparent" 

    property bool hovered: false
    property string iconSource: "../../assets/icons/trash-can.png"

    signal clicked()
    signal pressed()
    signal released()

    Image {
        anchors.centerIn: parent
        source: iconSource
        width: 22
        height: 22
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: parent.hovered = true
        onExited: parent.hovered = false

        onClicked: iconBtn.clicked()
        onPressed: iconBtn.pressed()
        onReleased: iconBtn.released()
        onCanceled: iconBtn.released()
    }
}
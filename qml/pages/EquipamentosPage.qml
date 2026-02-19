import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Label {
            text: "Equipamentos"
            font.pixelSize: 28
            font.bold: true
            color: "#8f8f8f"
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Em breve"
            font.pixelSize: 16
            color: "#b8b8b8"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

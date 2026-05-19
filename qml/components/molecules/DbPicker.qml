import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: 280
    height: 55
    radius: height / 2
    color: "#ffffff"

    property string dbName: "No database selected"
    signal selectClicked()

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.alignment: Qt.AlignVCenter
            text: root.dbName
            color: "#a0a0a0"
            font.pixelSize: 13
            elide: Text.ElideLeft
        }

        Button {
            id: dbPickerBtn
            text: "Select dB"
            Layout.preferredWidth: 110
            Layout.preferredHeight: 45
            Layout.rightMargin: 5
            Layout.alignment: Qt.AlignVCenter

            background: Rectangle {
                radius: height / 2
                color: dbPickerBtn.down    ? "#17807E"
                     : dbPickerBtn.hovered ? "#20B2AA"
                     :                      "#1CA8A4"
            }

            contentItem: Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                text: dbPickerBtn.text
                color: "white"
                font.pixelSize: 16
            }

            onClicked: root.selectClicked()
        }
    }
}

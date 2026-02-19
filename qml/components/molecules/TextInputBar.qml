import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: background
    Layout.fillWidth: true
    Layout.preferredHeight: 55
    Layout.margins: 12
    radius: height / 2
    color: "#ffffff"

    signal connectClicked(string name)
    signal textChanged(string text)

    property string buttonName: "pesquisar"
    property string placeholder: "Insira o nome da posição"
    property alias currentText: textInput.text

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 8

        TextField {
            id: textInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 12
            implicitHeight: 40
            placeholderText: background.placeholder
            font.pixelSize: 16
            color: "#333"
            verticalAlignment: TextInput.AlignVCenter
            background: Rectangle { color: "transparent" }
            padding: 8
            onTextChanged: background.textChanged(text)
        }

        Button {
            id: connectButton
            text: background.buttonName
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 145
            Layout.preferredHeight: 45
            Layout.rightMargin: 5

            background: Rectangle {
                radius: height / 2
                color: connectButton.down    ? "#17807E"
                     : connectButton.hovered ? "#20B2AA"
                     :                        "#1CA8A4"
            }

            contentItem: Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                text: connectButton.text
                color: "white"
                font.pixelSize: 16
            }

            onClicked: background.connectClicked(textInput.text)
        }
    }
}

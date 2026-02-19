import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    width: 220
    color: "#0078d4"

    signal pageSelected(string pageName)
    property string currentPage: "Positions"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Logo area — drop logo.png into assets/icons/ to replace the text fallback
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 75
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 10
                height: parent.height
                radius: 16
                clip: true
                color: "transparent"
                visible: logoImage.status === Image.Ready

                Image {
                    id: logoImage
                    anchors.fill: parent
                    source: "../../../assets/icons/logo.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Label {
                anchors.centerIn: parent
                text: "Robotine"
                color: "white"
                font.bold: true
                font.pixelSize: 18
                visible: logoImage.status !== Image.Ready
            }
        }

        Rectangle { height: 1; color: "#2196f3"; Layout.fillWidth: true }

        Repeater {
            model: [
                { label: "Points",     page: "Positions"    },
                { label: "Systems", page: "Equipamentos" }
            ]
            delegate: Rectangle {
                width: parent.width
                height: 44
                radius: 8
                color: sidebar.currentPage === modelData.page ? "#2196f3" : "transparent"

                Text {
                    text: modelData.label
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:  if (sidebar.currentPage !== modelData.page) parent.color = "#1a8fe8"
                    onExited:   parent.color = sidebar.currentPage === modelData.page ? "#2196f3" : "transparent"
                    onClicked: {
                        sidebar.currentPage = modelData.page
                        sidebar.pageSelected(modelData.page)
                    }
                }
            }
        }

        // Spacer
        Item { Layout.fillHeight: true }
    }
}

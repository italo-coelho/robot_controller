import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components/organisms"
import "pages"

ApplicationWindow {
    id: mainWindow
    visible: true
    title: "Robotine Controller"
    visibility: Window.Maximized

    Rectangle {
        anchors.fill: parent
        color: "#f5f7fa"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Sidebar {
                id: sidebar
                Layout.preferredWidth: 220
                Layout.fillHeight: true

                onPageSelected: function(pageName) {
                    let pageUrl = Qt.resolvedUrl("pages/" + pageName + "Page.qml")
                    stackView.replace(pageUrl)
                }

                Component.onCompleted: {
                    pageSelected("Positions")
                }
            }

            StackView {
                id: stackView
                Layout.fillWidth: true
                Layout.fillHeight: true
                initialItem: Qt.resolvedUrl("pages/PositionsPage.qml")
                clip: true
                focus: true

                replaceEnter: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                }
                replaceExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
                }
            }
        }
    }
}

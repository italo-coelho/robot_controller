import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components/organisms"

Item {
    id: positionsPage

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ListPosition {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 30
        }
    }
}

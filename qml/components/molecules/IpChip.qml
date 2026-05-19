import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Column {
    id: root
    spacing: 4

    property bool connected: false
    property string initialIp: "192.168.167.199"

    signal connectRequested(string ip)

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "ROBOT IP"
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 1.2
        color: "#888"
    }

    Rectangle {
        id: ipInputBox
        width: 175
        height: 36
        radius: 18
        color: "#ffffff"
        border.color: root.connected ? "#28A745" : "#DC3545"
        border.width: 1.5

        Rectangle {
            id: statusDot
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            width: 8; height: 8; radius: 4
            color: root.connected ? "#28A745" : "#DC3545"
        }

        TextField {
            id: ipField
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            height: parent.height
            text: root.initialIp
            inputMask: "000.000.000.000"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
            font.family: "monospace"
            color: "#333"
            background: Rectangle { color: "transparent" }

            onEditingFinished: {
                let ip = text.replace(/_/g, "").replace(/\s/g, "")
                ip = ip.split(".").map(function(o){ return parseInt(o) || 0 }).join(".")
                root.connectRequested(ip)
            }
        }

        Component.onCompleted: {
            let ip = ipField.text.replace(/_/g, "").replace(/\s/g, "")
            ip = ip.split(".").map(function(o){ return parseInt(o) || 0 }).join(".")
            root.connectRequested(ip)
        }
    }
}

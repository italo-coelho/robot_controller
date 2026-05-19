import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Column {
    spacing: 4

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "SPEED"
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 1.2
        color: "#888"
    }

    Rectangle {
        id: speedBox
        width: 148
        height: 36
        radius: 18
        color: "#ffffff"
        border.color: "#6C757D"
        border.width: 1.5

        property int currentSpeed: 100
        property var presets: [10, 25, 50, 75, 100]

        function applySpeed(val) {
            val = Math.max(1, Math.min(100, val))
            currentSpeed = val
            speedField.text = val + "%"
            PositionController.set_speed(val)
        }

        function prevPreset() {
            for (let i = presets.length - 1; i >= 0; i--) {
                if (presets[i] < currentSpeed) { applySpeed(presets[i]); return }
            }
            applySpeed(presets[0])
        }

        function nextPreset() {
            for (let i = 0; i < presets.length; i++) {
                if (presets[i] > currentSpeed) { applySpeed(presets[i]); return }
            }
            applySpeed(presets[presets.length - 1])
        }

        Rectangle {
            id: minusBtnArea
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            width: 24; height: 24; radius: 12
            color: minusMouse.containsMouse ? "#F0F0F0" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: 16
                font.bold: true
                color: "#555"
            }

            MouseArea {
                id: minusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: speedBox.prevPreset()
            }
        }

        TextField {
            id: speedField
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: minusBtnArea.right
            anchors.right: plusBtnArea.left
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            height: parent.height
            text: "100%"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
            font.bold: true
            color: "#333"
            background: Rectangle { color: "transparent" }

            onEditingFinished: {
                let raw = text.replace(/%/g, "").trim()
                let val = parseInt(raw)
                if (!isNaN(val) && val >= 1 && val <= 100)
                    speedBox.applySpeed(val)
                else
                    text = speedBox.currentSpeed + "%"
            }

            Keys.onReturnPressed: editingFinished()
        }

        Rectangle {
            id: plusBtnArea
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 6
            width: 24; height: 24; radius: 12
            color: plusMouse.containsMouse ? "#F0F0F0" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 16
                font.bold: true
                color: "#555"
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: speedBox.nextPreset()
            }
        }
    }
}

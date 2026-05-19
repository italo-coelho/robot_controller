import QtQuick 2.15
import QtQuick.Layouts 1.15

Column {
    id: root
    spacing: 6

    property int estop:     -1
    property int collision: -1
    property int enable:    -1

    Repeater {
        model: [
            { label: "E-STOP",    val: root.estop,     activeColor: "#DC3545" },
            { label: "COLLISION", val: root.collision, activeColor: "#FD7E14" },
            { label: "ENABLE",    val: root.enable,    activeColor: "#28A745" }
        ]

        Row {
            spacing: 7

            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    if (modelData.val < 0)  return "#CCCCCC"
                    if (modelData.label === "ENABLE")
                        return modelData.val === 1 ? modelData.activeColor : "#CCCCCC"
                    return modelData.val === 1 ? modelData.activeColor : "#28A745"
                }
            }

            Text {
                text: modelData.label
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.8
                color: "#555"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../atoms"

Rectangle {
    id: positionItem
    width: parent ? parent.width - 20 : 600
    implicitHeight: content.implicitHeight + 24
    radius: 20
    color: "#ffffff"
    border.color: "#e0e0e0"

    property string nameText
    property int poseId
    property var poses
    property string poseType: "cartesian"

    signal viewClicked(int poseId)
    signal editClicked(int poseId)
    signal deleteClicked(int poseId)

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Title { titleText: nameText; font.pixelSize: 16; font.bold: false; color: '#8f8f8f'}
        
        // Tag indicando o tipo
        Tag { 
            text: poseType === "joint" ? "Juntas" : "Cartesiano"
            backgroundColor: poseType === "joint" ? '#ffd6d6' : '#d6e3ff'
        }
        
        Item{ Layout.fillWidth: true }
        
        // Mostrar valores dependendo do tipo
        Repeater {
            model: poseType === "joint" ? [
                { label: "J1", value: poses ? poses.j1 : 0 },
                { label: "J2", value: poses ? poses.j2 : 0 },
                { label: "J3", value: poses ? poses.j3 : 0 },
                { label: "J4", value: poses ? poses.j4 : 0 },
                { label: "J5", value: poses ? poses.j5 : 0 },
                { label: "J6", value: poses ? poses.j6 : 0 }
            ] : [
                { label: "X", value: poses ? poses.posX : 0 },
                { label: "Y", value: poses ? poses.posY : 0 },
                { label: "Z", value: poses ? poses.posZ : 0 },
                { label: "RX", value: poses ? poses.posRX : 0, color: '#d6ffd7' },
                { label: "RY", value: poses ? poses.posRY : 0, color: '#d6ffd7' },
                { label: "RZ", value: poses ? poses.posRZ : 0, color: '#d6ffd7' }
            ]
            Tag { 
                text: `${modelData.label}: ${Number(modelData.value || 0).toFixed(2)}`
                backgroundColor: modelData.color || undefined
            }
        }  


        RowLayout {
            spacing: 6

            IconBtn {
                iconSource: "../../../assets/icons/industrial-robot.png"
                onClicked: positionItem.viewClicked(poseId)
            }

            IconBtn {
                iconSource: "../../../assets/icons/edit.png"
                onClicked: positionItem.editClicked(poseId)
            }

            IconBtn {
                iconSource: "../../../assets/icons/trash-can.png"
                onClicked: positionItem.deleteClicked(poseId)
            }
        }
    }
}

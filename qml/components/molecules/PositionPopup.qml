import QtQuick 2.15 
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../atoms"

Popup {
    id: toast
    modal: true
    focus: true
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnPressOutside

    width:  Math.min(Overlay.overlay.width  * 0.60, 900)
    height: Math.min(Overlay.overlay.height * 0.80, 700)

    property string mainButtonText: "Salvar"
    property string actualPositionName: ""
    property string poseId: ""
    property alias positionName: textInput.text
    property alias poseXValue: poseX.value
    property alias poseYValue: poseY.value
    property alias poseZValue: poseZ.value
    property alias poseRXValue: poseRX.value
    property alias poseRYValue: poseRY.value
    property alias poseRZValue: poseRZ.value

    signal mainButtonClicked()

    function openWith(itemId, itemName, x, y, z, rx, ry, rz) {
        poseId = itemId ? String(itemId) : ""
        actualPositionName = itemName || ""
        textInput.text = itemName || ""
        poseX.value  = (x  !== undefined && x  !== null) ? String(x)  : "0.0"
        poseY.value  = (y  !== undefined && y  !== null) ? String(y)  : "0.0"
        poseZ.value  = (z  !== undefined && z  !== null) ? String(z)  : "0.0"
        poseRX.value = (rx !== undefined && rx !== null) ? String(rx) : "0.0"
        poseRY.value = (ry !== undefined && ry !== null) ? String(ry) : "0.0"
        poseRZ.value = (rz !== undefined && rz !== null) ? String(rz) : "0.0"
        open()
    }

    function clearState() {
        poseId = ""
        actualPositionName = ""
        textInput.text = ""
        poseX.value = "0.0"
        poseY.value = "0.0"
        poseZ.value = "0.0"
        poseRX.value = "0.0"
        poseRY.value = "0.0"
        poseRZ.value = "0.0"
    }

    onClosed: clearState()

    background: Rectangle {
        anchors.fill: parent
        color: "#eeeeee"
        radius: 20
        border.color: "#d0d0d0"
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160 }
        NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: 160; easing.type: Easing.InCubic }
    }
    
    Connections {
        target: PositionController
        function onCurrentPoseLoaded(pose) {
            textInput.text = actualPositionName
            poseX.value = pose.x.toFixed(2)
            poseY.value = pose.y.toFixed(2)
            poseZ.value = pose.z.toFixed(2)
            poseRX.value = pose.rx.toFixed(2)
            poseRY.value = pose.ry.toFixed(2)
            poseRZ.value = pose.rz.toFixed(2)
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 5

        Label {
            text: `${mainButtonText} nova posição`
            color: "#525252"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        Rectangle {
            id: background
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            Layout.margins: 6
            radius: height / 2
            color: "#ffffff"
            property string placeholder: "Insira o nome da posição"

            RowLayout {
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
                }
            }
        }

        GridLayout {
            id: grid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignHCenter

            PoseInput { id: poseX;  nameInput: "Pose X";  value: "0.0" }
            PoseInput { id: poseY;  nameInput: "Pose Y";  value: "0.0" }
            PoseInput { id: poseZ;  nameInput: "Pose Z";  value: "0.0" }
            PoseInput { id: poseRX; nameInput: "Pose RX"; value: "0.0" }
            PoseInput { id: poseRY; nameInput: "Pose RY"; value: "0.0" }
            PoseInput { id: poseRZ; nameInput: "Pose RZ"; value: "0.0" }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            CommonBtn {
                text: "Posição Atual"
                style: "info"
                onClicked: PositionController.get_current_pose()
            }
            Item { Layout.fillWidth: true }

            CommonBtn {
                text: "Mover"
                style: "secondary"
                onClicked: {
                    PositionController.move_j(
                        textInput.text,
                        parseFloat(poseX.value),
                        parseFloat(poseY.value),
                        parseFloat(poseZ.value),
                        parseFloat(poseRX.value),
                        parseFloat(poseRY.value),
                        parseFloat(poseRZ.value)
                    )
                }
            }
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            CommonBtn {
                text: "Cancelar"
                style: "danger"
                onClicked: toast.close()
            }
            CommonBtn {
                text: mainButtonText
                style: "success"
                onClicked: {
                    if (textInput.text.length === 0) return
                    mainButtonClicked()
                    toast.close()
                }
            }
        }
    }
}

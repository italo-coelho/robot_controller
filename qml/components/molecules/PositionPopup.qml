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

    property string mainButtonText: "Save"
    property string actualPositionName: ""
    property string poseId: ""
    property bool isJointMode: false
    property alias positionName: textInput.text
    property alias poseXValue: poseX.value
    property alias poseYValue: poseY.value
    property alias poseZValue: poseZ.value
    property alias poseRXValue: poseRX.value
    property alias poseRYValue: poseRY.value
    property alias poseRZValue: poseRZ.value
    property alias joint1Value: joint1.value
    property alias joint2Value: joint2.value
    property alias joint3Value: joint3.value
    property alias joint4Value: joint4.value
    property alias joint5Value: joint5.value
    property alias joint6Value: joint6.value

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
        isJointMode = false
        open()
    }
    
    function openWithJoints(itemId, itemName, j1, j2, j3, j4, j5, j6) {
        poseId = itemId ? String(itemId) : ""
        actualPositionName = itemName || ""
        textInput.text = itemName || ""
        joint1.value = (j1 !== undefined && j1 !== null) ? String(j1) : "0.0"
        joint2.value = (j2 !== undefined && j2 !== null) ? String(j2) : "0.0"
        joint3.value = (j3 !== undefined && j3 !== null) ? String(j3) : "0.0"
        joint4.value = (j4 !== undefined && j4 !== null) ? String(j4) : "0.0"
        joint5.value = (j5 !== undefined && j5 !== null) ? String(j5) : "0.0"
        joint6.value = (j6 !== undefined && j6 !== null) ? String(j6) : "0.0"
        isJointMode = true
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
        joint1.value = "0.0"
        joint2.value = "0.0"
        joint3.value = "0.0"
        joint4.value = "0.0"
        joint5.value = "0.0"
        joint6.value = "0.0"
        isJointMode = false
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
            if (!toast.isJointMode) {
                textInput.text = actualPositionName
                poseX.value = pose.x.toFixed(2)
                poseY.value = pose.y.toFixed(2)
                poseZ.value = pose.z.toFixed(2)
                poseRX.value = pose.rx.toFixed(2)
                poseRY.value = pose.ry.toFixed(2)
                poseRZ.value = pose.rz.toFixed(2)
            }
        }
        function onCurrentJointPoseLoaded(pose) {
            if (toast.isJointMode) {
                textInput.text = actualPositionName
                joint1.value = pose.j1.toFixed(2)
                joint2.value = pose.j2.toFixed(2)
                joint3.value = pose.j3.toFixed(2)
                joint4.value = pose.j4.toFixed(2)
                joint5.value = pose.j5.toFixed(2)
                joint6.value = pose.j6.toFixed(2)
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 5

        Label {
            text: `${mainButtonText}`
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
            property string placeholder: "Type point name"

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

        // Toggle entre Cartesiano e Juntas
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Label {
                text: "Cartesian"
                color: toast.isJointMode ? '#c71f1f' : "#525252"
                font.bold: !toast.isJointMode
            }

            Switch {
                id: modeSwitch
                checked: toast.isJointMode
                onCheckedChanged: {
                    toast.isJointMode = checked
                }
            }

            Label {
                text: "Joints"
                color: toast.isJointMode ? '#da2222' : "#b6b3b3"
                font.bold: toast.isJointMode
            }
        }

        // Grid para posição cartesiana
        GridLayout {
            id: cartesianGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignHCenter
            visible: !toast.isJointMode

            PoseInput { id: poseX;  nameInput: "Pose X";  value: "0.0" }
            PoseInput { id: poseY;  nameInput: "Pose Y";  value: "0.0" }
            PoseInput { id: poseZ;  nameInput: "Pose Z";  value: "0.0" }
            PoseInput { id: poseRX; nameInput: "Pose RX"; value: "0.0" }
            PoseInput { id: poseRY; nameInput: "Pose RY"; value: "0.0" }
            PoseInput { id: poseRZ; nameInput: "Pose RZ"; value: "0.0" }
        }

        // Grid para posição das juntas
        GridLayout {
            id: jointGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignHCenter
            visible: toast.isJointMode

            PoseInput { id: joint1; nameInput: "J1"; value: "0.0" }
            PoseInput { id: joint2; nameInput: "J2"; value: "0.0" }
            PoseInput { id: joint3; nameInput: "J3"; value: "0.0" }
            PoseInput { id: joint4; nameInput: "J4"; value: "0.0" }
            PoseInput { id: joint5; nameInput: "J5"; value: "0.0" }
            PoseInput { id: joint6; nameInput: "J6"; value: "0.0" }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            CommonBtn {
                text: "Get Position"
                style: "info"
                onClicked: {
                    if (toast.isJointMode) {
                        PositionController.get_current_joint_pose()
                    } else {
                        PositionController.get_current_pose()
                    }
                }
            }
            Item { Layout.fillWidth: true }

            CommonBtn {
                text: "Move Robot"
                style: "secondary"
                onPressed: {
                    if (toast.isJointMode) {
                        PositionController.move_joints(
                            textInput.text,
                            parseFloat(joint1.value),
                            parseFloat(joint2.value),
                            parseFloat(joint3.value),
                            parseFloat(joint4.value),
                            parseFloat(joint5.value),
                            parseFloat(joint6.value)
                        )
                    } else {
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
                onReleased: PositionController.stop_motion()
            }
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            CommonBtn {
                text: "Cancel"
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

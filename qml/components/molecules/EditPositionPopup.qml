import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../atoms"

import QtQuick 2.15
import QtQuick.Controls 2.15

Popup {
    id: toast
    modal: true
    focus: true
    width: 600
    height: 700
    anchors.centerIn: parent

    closePolicy: Popup.CloseOnPressOutside
    
    property bool isJointMode: false
    
    background: Rectangle {
        width: toast.width
        height: toast.height
        color: '#eeeeee'
        radius: 20
        border.color: "#d0d0d0"
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
        NumberAnimation { property: "scale"; from: 1; to: 0.9; duration: 180; easing.type: Easing.InCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 20

        Label {
            text: "Add new point"
            color: "#525252"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
        }

        Rectangle {
            id: background
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            Layout.margins: 12 
            radius: height / 2
            color: "#ffffff"

            property string placeholder: "Type point name"

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

        Rectangle {
            height: 1
            color: '#b8b8b8'
            Layout.fillWidth: true
            Layout.margins: 1
        }

        // Grid para posição cartesiana
        GridLayout {
            id: cartesianGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.alignment: Qt.AlignHCenter
            visible: !toast.isJointMode

            PoseInput { id: poseX; nameInput: "Pose X" }
            PoseInput { id: poseY; nameInput: "Pose Y" }
            PoseInput { id: poseZ; nameInput: "Pose Z" }
            PoseInput { id: poseRX; nameInput: "Pose RX" }
            PoseInput { id: poseRY; nameInput: "Pose RY" }
            PoseInput { id: poseRZ; nameInput: "Pose RZ" }
        }

        // Grid para posição das juntas
        GridLayout {
            id: jointGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.alignment: Qt.AlignHCenter
            visible: toast.isJointMode

            PoseInput { id: joint1; nameInput: "J1" }
            PoseInput { id: joint2; nameInput: "J2" }
            PoseInput { id: joint3; nameInput: "J3" }
            PoseInput { id: joint4; nameInput: "J4" }
            PoseInput { id: joint5; nameInput: "J5" }
            PoseInput { id: joint6; nameInput: "J6" }
        }

        RowLayout{
            id: positionButtons
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

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

            Item{ Layout.fillWidth: true }

            CommonBtn {
                text: "Move"
                style: "secondary"
                onClicked: {
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
            }

        }

        Rectangle {
            height: 1
            color: '#b8b8b8'
            Layout.fillWidth: true
            Layout.margins: 1
        }

        RowLayout{
            id: buttonsControllers
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter  
            spacing: 0

            CommonBtn {
                text: "Cancel"
                style: "danger"
                onClicked: {
                    textInput.text = ""
                    toast.isJointMode = false
                    toast.close()
                }
            }

            CommonBtn { 
                text: "Edit"
                style: "success"

                onClicked: {
                    if (textInput.text.length === 0) return
                    
                    if (toast.isJointMode) {
                        PositionController.save_joint_pose(
                            textInput.text,
                            parseFloat(joint1.value),
                            parseFloat(joint2.value),
                            parseFloat(joint3.value),
                            parseFloat(joint4.value),
                            parseFloat(joint5.value),
                            parseFloat(joint6.value)
                        )
                    } else {
                        PositionController.save_pose(
                            textInput.text,
                            parseFloat(poseX.value),
                            parseFloat(poseY.value),
                            parseFloat(poseZ.value),
                            parseFloat(poseRX.value),
                            parseFloat(poseRY.value),
                            parseFloat(poseRZ.value)
                        )
                    }
                    
                    textInput.text = ""
                    toast.isJointMode = false
                    PositionController.load_poses()
                    toast.close()
                }
            }
        }
    }

    Connections {
        target: PositionController
        function onCurrentPoseLoaded(pose) {
            if (!toast.isJointMode) {
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
                joint1.value = pose.j1.toFixed(2)
                joint2.value = pose.j2.toFixed(2)
                joint3.value = pose.j3.toFixed(2)
                joint4.value = pose.j4.toFixed(2)
                joint5.value = pose.j5.toFixed(2)
                joint6.value = pose.j6.toFixed(2)
            }
        }
    }
}


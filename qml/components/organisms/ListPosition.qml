import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../molecules"
import "../atoms"

Rectangle {
    id: positionController
    Layout.fillWidth: true
    Layout.preferredHeight: 800
    radius: 30
    color: "transparent"

    ListModel { id: savedPositionsModel }

    Component.onCompleted: PositionController.load_poses()

    Connections {
        target: PositionController
        function onPosesLoaded(poses) {
            savedPositionsModel.clear()
            for (let pose of poses) {
                if (pose.type === "cartesian") {
                    savedPositionsModel.append({
                        id: pose.id,
                        name: pose.name,
                        type: "cartesian",
                        poses: {
                            posX: pose.x,
                            posY: pose.y,
                            posZ: pose.z,
                            posRX: pose.rx,
                            posRY: pose.ry,
                            posRZ: pose.rz
                        }
                    })
                } else if (pose.type === "joint") {
                    savedPositionsModel.append({
                        id: pose.id,
                        name: pose.name,
                        type: "joint",
                        poses: {
                            j1: pose.j1,
                            j2: pose.j2,
                            j3: pose.j3,
                            j4: pose.j4,
                            j5: pose.j5,
                            j6: pose.j6
                        }
                    })
                }
            }
        }
    }

    PositionPopup {
        id: addPositionPopup
        onMainButtonClicked: {
            if (isJointMode) {
                PositionController.save_joint_pose(
                    positionName,
                    parseFloat(joint1Value),
                    parseFloat(joint2Value),
                    parseFloat(joint3Value),
                    parseFloat(joint4Value),
                    parseFloat(joint5Value),
                    parseFloat(joint6Value)
                )
            } else {
                PositionController.save_pose(
                    positionName,
                    parseFloat(poseXValue),
                    parseFloat(poseYValue),
                    parseFloat(poseZValue),
                    parseFloat(poseRXValue),
                    parseFloat(poseRYValue),
                    parseFloat(poseRZValue)
                )
            }
            PositionController.load_poses()
        }
    }

    PositionPopup {
        id: editPositionPopup
        mainButtonText: "Editar"
        onMainButtonClicked: {
            if (isJointMode) {
                PositionController.update_joint_pose(
                    actualPositionName,
                    positionName,
                    parseFloat(joint1Value),
                    parseFloat(joint2Value),
                    parseFloat(joint3Value),
                    parseFloat(joint4Value),
                    parseFloat(joint5Value),
                    parseFloat(joint6Value)
                )
            } else {
                PositionController.update_pose(
                    actualPositionName,
                    positionName,
                    parseFloat(poseXValue),
                    parseFloat(poseYValue),
                    parseFloat(poseZValue),
                    parseFloat(poseRXValue),
                    parseFloat(poseRYValue),
                    parseFloat(poseRZValue)
                )
            }
            PositionController.load_poses()
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        Layout.margins: 30

        Title { Layout.alignment: Qt.AlignJustify; titleText: "Lista de Posições" }

        RowLayout {
            id: buttonsControllers
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignJustify
            spacing: 0

            TextInputBar {
                id: positionInputBar
                buttonName: "Pesquisar"
                placeholder: "Insira o nome da posição"
            }

            CommonBtn {
                text: "Nova Posição"
                style: "primary"
                onClicked: {
                    addPositionPopup.openWith("", "", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                }
            }
        }

        Rectangle {
            height: 2
            color: "#b8b8b8"
            Layout.fillWidth: true
            Layout.margins: 5
        }

        ListView {
            id: savedPositionsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: savedPositionsModel
            spacing: 12
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: PositionItem {
                nameText: name
                poses: model.poses
                poseType: model.type || "cartesian"

                onViewClicked: (itemId) => {
                    console.log("Ver posição", name)
                }

                onEditClicked: (itemId) => {
                    if (model.type === "joint") {
                        editPositionPopup.openWithJoints(
                            itemId,
                            name,
                            poses.j1,
                            poses.j2,
                            poses.j3,
                            poses.j4,
                            poses.j5,
                            poses.j6
                        )
                    } else {
                        editPositionPopup.openWith(
                            itemId,
                            name,
                            poses.posX,
                            poses.posY,
                            poses.posZ,
                            poses.posRX,
                            poses.posRY,
                            poses.posRZ
                        )
                    }
                }

                onDeleteClicked: (itemId) => {
                    PositionController.delete_pose_by_type(name, model.type || "cartesian")
                }
            }
        }

        CommonBtn {
            text: "Deletar Lista"
            style: "danger"
            onClicked: {
                PositionController.delete_all_poses()
            }
        }
    }
}

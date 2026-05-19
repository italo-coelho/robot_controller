import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtQuick.Window 2.15
import "../molecules"
import "../atoms"

Rectangle {
    id: positionController
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 30
    color: "transparent"

    // Master list – all loaded poses, never filtered
    property var allPoses: []

    // Filename shown in the DB picker chip; updated from FileDialog/Python.
    property string currentDbName: "No database selected"

    ListModel { id: savedPositionsModel }

    function applyFilter(text) {
        savedPositionsModel.clear()
        let lower = text.toLowerCase().trim()
        for (let pose of allPoses) {
            if (lower === "" || pose.name.toLowerCase().indexOf(lower) !== -1) {
                savedPositionsModel.append(pose)
            }
        }
    }

    Component.onCompleted: PositionController.load_poses()

    Connections {
        target: PositionController
        function onPosesLoaded(poses) {
            allPoses = []
            for (let pose of poses) {
                if (pose.type === "cartesian") {
                    allPoses.push({
                        id: pose.id,
                        name: pose.name,
                        type: "cartesian",
                        poses: {
                            posX: pose.x,
                            posY: pose.y,
                            posZ: pose.z,
                            posRX: pose.rx,
                            posRY: pose.ry,
                            posRZ: pose.rz,
                            posDX: pose.dx,
                            posDY: pose.dy,
                            posDZ: pose.dz,
                            posDRX: pose.drx,
                            posDRY: pose.dry,
                            posDRZ: pose.drz
                        }
                    })
                } else if (pose.type === "joint") {
                    allPoses.push({
                        id: pose.id,
                        name: pose.name,
                        type: "joint",
                        poses: {
                            j1: pose.j1,
                            j2: pose.j2,
                            j3: pose.j3,
                            j4: pose.j4,
                            j5: pose.j5,
                            j6: pose.j6,
                            dx: pose.dx,
                            dy: pose.dy,
                            dz: pose.dz,
                            drx: pose.drx,
                            dry: pose.dry,
                            drz: pose.drz
                        }
                    })
                }
            }
            applyFilter(positionInputBar.currentText)
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
        mainButtonText: "Edit"
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

    OffsetPopup {
        id: offsetPopup
        onSaveClicked: {
            if (isJointMode) {
                PositionController.update_joint_offset(
                    actualPositionName,
                    parseFloat(jointDxValue),
                    parseFloat(jointDyValue),
                    parseFloat(jointDzValue),
                    parseFloat(jointDrxValue),
                    parseFloat(jointDryValue),
                    parseFloat(jointDrzValue)
                )
            } else {
                PositionController.update_pose_offset(
                    actualPositionName,
                    parseFloat(dxValue),
                    parseFloat(dyValue),
                    parseFloat(dzValue),
                    parseFloat(drxValue),
                    parseFloat(dryValue),
                    parseFloat(drzValue)
                )
            }
            PositionController.load_poses()
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        Layout.margins: 30

        // non-visual helpers (outside rows so they're always available)
        FileDialog {
            id: dbFilePicker
            title: "Select Points dB"
            nameFilters: ["SQLite databases (*.db)", "All files (*)"]
            fileMode: FileDialog.OpenFile
            // Pass the file:// URL straight to Python; QUrl.toLocalFile there
            // handles the macOS / Linux / Windows path conventions uniformly.
            onAccepted: PositionController.set_database(selectedFile.toString())
        }

        QtObject {
            id: ipStatus
            property bool connected: false
        }

        QtObject {
            id: robotStates
            property int estop:     -1
            property int collision: -1
            property int enable:    -1
        }

        Connections {
            target: PositionController
            function onRobotStatusChanged(connected, ip) { ipStatus.connected = connected }
            function onDatabaseChanged(path) {
                if (!path) {
                    positionController.currentDbName = "No database selected"
                    return
                }
                let parts = path.split(/[\/\\]/)  // handles both POSIX and Windows separators
                positionController.currentDbName = parts[parts.length - 1] || path
            }
            function onRobotStatesUpdated(states) {
                robotStates.estop     = states["estop"]
                robotStates.collision = states["collision"]
                robotStates.enable    = states["enable"]
            }
        }

        // ── Row 1: title + status chips — wraps on narrow widths ────────────
        Flow {
            Layout.fillWidth: true
            Layout.rightMargin: 20
            spacing: 16

            Title { titleText: "Point List" }

            SpeedChip {}

            IpChip {
                connected: ipStatus.connected
                onConnectRequested: (ip) => {
                    ipStatus.connected = false
                    PositionController.connect_robot(ip)
                }
            }

            RobotStatesChip {
                estop:     robotStates.estop
                collision: robotStates.collision
                enable:    robotStates.enable
            }

            RobotActionsChip {
                enableState: robotStates.enable
                onResetClicked: PositionController.reset_all_error()
                onToggleEnableClicked: (newState) => PositionController.robot_enable(newState)
            }

            JogToggleButton {
                onClicked: jogControlPopup.visible ? jogControlPopup.hide() : jogControlPopup.show()
            }
        }

        JogControlPopup { id: jogControlPopup }

        // ── Row 2: search · DB picker · New Point — wraps on narrow widths ──
        Flow {
            id: buttonsControllers
            Layout.fillWidth: true
            spacing: 12

            TextInputBar {
                id: positionInputBar
                width: parent.width >= 800
                         ? Math.max(280, parent.width - 440)
                         : parent.width
                height: 55
                buttonName: "Search"
                placeholder: "Type point name..."
                onTextChanged: applyFilter(currentText)
                onConnectClicked: (text) => applyFilter(text)
            }

            DbPicker {
                dbName: positionController.currentDbName
                onSelectClicked: dbFilePicker.open()
            }

            CommonBtn {
                text: "New Point"
                style: "primary"
                width: 130
                height: 50
                onClicked: addPositionPopup.openWith("", "", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
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

                onMovePressed: (poseName, poseData, type) => {
                    if (type === "joint") {
                        PositionController.move_joints(
                            poseName,
                            parseFloat(poseData.j1),
                            parseFloat(poseData.j2),
                            parseFloat(poseData.j3),
                            parseFloat(poseData.j4),
                            parseFloat(poseData.j5),
                            parseFloat(poseData.j6)
                        )
                    } else {
                        PositionController.move_j(
                            poseName,
                            parseFloat(poseData.posX),
                            parseFloat(poseData.posY),
                            parseFloat(poseData.posZ),
                            parseFloat(poseData.posRX),
                            parseFloat(poseData.posRY),
                            parseFloat(poseData.posRZ)
                        )
                    }
                }

                onMoveReleased: PositionController.stop_motion()

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

                onOffsetClicked: (itemId) => {
                    if (model.type === "joint") {
                        offsetPopup.openWithJoints(
                            name,
                            poses.dx,  poses.dy,  poses.dz,
                            poses.drx, poses.dry, poses.drz,
                            poses.j1, poses.j2, poses.j3,
                            poses.j4, poses.j5, poses.j6
                        )
                    } else {
                        offsetPopup.openWithTcp(
                            name,
                            poses.posDX,  poses.posDY,  poses.posDZ,
                            poses.posDRX, poses.posDRY, poses.posDRZ,
                            poses.posX,  poses.posY,  poses.posZ,
                            poses.posRX, poses.posRY, poses.posRZ
                        )
                    }
                }
            }
        }

        CommonBtn {
            text: "Delete List"
            style: "danger"
            visible: Window.window ? Window.window.deleteUnlocked : false
            onClicked: confirmDeletePopup.open()
        }
    }

    Popup {
        id: confirmDeletePopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        closePolicy: Popup.CloseOnEscape
        padding: 24

        width: 400

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#D1D5DB"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 14

            Label {
                text: "Delete all poses?"
                font.pixelSize: 18
                font.bold: true
                color: "#111827"
            }

            Label {
                text: "This will permanently remove every saved pose from the current database. This cannot be undone."
                font.pixelSize: 13
                color: "#6B7280"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    onClicked: confirmDeletePopup.close()
                }
                Button {
                    text: "Delete"
                    highlighted: true
                    onClicked: {
                        PositionController.delete_all_poses()
                        confirmDeletePopup.close()
                    }
                }
            }
        }
    }
}

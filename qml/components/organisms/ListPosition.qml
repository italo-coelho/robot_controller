import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import "../molecules"
import "../atoms"

Rectangle {
    id: positionController
    Layout.fillWidth: true
    Layout.preferredHeight: 800
    radius: 30
    color: "transparent"

    // Master list – all loaded poses, never filtered
    property var allPoses: []

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
            onAccepted: {
                let path = selectedFile.toString()
                path = path.replace(/^file:\/\/\//, "/").replace(/^file:\/\//, "//")
                PositionController.set_database(path)
                dbLabel.text = path.split("/").pop()
            }
        }

        QtObject {
            id: ipStatus
            property bool connected: false
        }

        Connections {
            target: PositionController
            function onRobotStatusChanged(connected, ip) { ipStatus.connected = connected }
            function onDatabaseChanged(path) { dbLabel.text = path.split("/").pop() }
        }

        // ── Row 1: title left · speed selector · IP selector right ──────────
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 20
            spacing: 10

            Title { titleText: "Point List" }

            Item { Layout.fillWidth: true }

            // ── Speed selector ────────────────────────────────────────────────
            Column {
                Layout.alignment: Qt.AlignVCenter
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

                    // − button
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

                    // speed text field
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

                    // + button
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

            // 3× gap between speed and IP
            Item { Layout.preferredWidth: 20 }

            // ── IP selector ───────────────────────────────────────────────────
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

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
                    border.color: ipStatus.connected ? "#28A745" : "#DC3545"
                    border.width: 1.5

                    // status dot — pinned left
                    Rectangle {
                        id: statusDot
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        width: 8; height: 8; radius: 4
                        color: ipStatus.connected ? "#28A745" : "#DC3545"
                    }

                    // IP field — centered in the pill, equal padding both sides
                    TextField {
                        id: ipField
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        height: parent.height
                        text: "192.168.167.199"
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
                            ipStatus.connected = false
                            PositionController.connect_robot(ip)
                        }
                    }

                    Component.onCompleted: {
                        let ip = ipField.text.replace(/_/g, "").replace(/\s/g, "")
                        ip = ip.split(".").map(function(o){ return parseInt(o) || 0 }).join(".")
                        PositionController.connect_robot(ip)
                    }
                }
            }
        }

        // ── Row 2: search left · filename | Trocar DB | Nova Posição right ─
        RowLayout {
            id: buttonsControllers
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            TextInputBar {
                id: positionInputBar
                buttonName: "Search"
                placeholder: "Type point name..."
                onTextChanged: applyFilter(currentText)
                onConnectClicked: (text) => applyFilter(text)
            }

            Item { Layout.fillWidth: true }

            // filename + DB picker — one pill matching the search bar
            Rectangle {
                Layout.preferredHeight: 55
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 260
                Layout.maximumWidth: 340
                radius: height / 2
                color: "#ffffff"

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        id: dbLabel
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.alignment: Qt.AlignVCenter
                        text: "points.db"
                        color: "#a0a0a0"
                        font.pixelSize: 13
                        elide: Text.ElideLeft
                    }

                    Button {
                        id: dbPickerBtn
                        text: "Select dB"
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 45
                        Layout.rightMargin: 5
                        Layout.alignment: Qt.AlignVCenter

                        background: Rectangle {
                            radius: height / 2
                            color: dbPickerBtn.down    ? "#17807E"
                                 : dbPickerBtn.hovered ? "#20B2AA"
                                 :                      "#1CA8A4"
                        }

                        contentItem: Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                            text: dbPickerBtn.text
                            color: "white"
                            font.pixelSize: 16
                        }

                        onClicked: dbFilePicker.open()
                    }
                }
            }

            CommonBtn {
                text: "New Point"
                style: "primary"
                Layout.preferredHeight: 50
                Layout.preferredWidth: 130
                Layout.alignment: Qt.AlignVCenter
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
            onClicked: {
                PositionController.delete_all_poses()
            }
        }
    }
}

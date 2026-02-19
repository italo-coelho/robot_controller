import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../atoms"

Popup {
    id: offsetPopup
    modal: true
    focus: true
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnPressOutside

    width: Math.min(Overlay.overlay.width * 0.50, 700)
    height: Math.min(Overlay.overlay.height * 0.70, 600)

    property string actualPositionName: ""
    property bool isJointMode: false

    // offsets
    property alias dxValue:  tcpDx.value
    property alias dyValue:  tcpDy.value
    property alias dzValue:  tcpDz.value
    property alias drxValue: tcpDrx.value
    property alias dryValue: tcpDry.value
    property alias drzValue: tcpDrz.value
    property alias jointDxValue:  jointDx.value
    property alias jointDyValue:  jointDy.value
    property alias jointDzValue:  jointDz.value
    property alias jointDrxValue: jointDrx.value
    property alias jointDryValue: jointDry.value
    property alias jointDrzValue: jointDrz.value

    // base pose — stored so Mover can add offsets on top
    property real basePoseX:  0; property real basePoseY:  0; property real basePoseZ:  0
    property real basePoseRX: 0; property real basePoseRY: 0; property real basePoseRZ: 0
    property real baseJ1: 0; property real baseJ2: 0; property real baseJ3: 0
    property real baseJ4: 0; property real baseJ5: 0; property real baseJ6: 0

    signal saveClicked()

    function openWithTcp(name, dx, dy, dz, drx, dry, drz, x, y, z, rx, ry, rz) {
        actualPositionName = name || ""
        isJointMode = false
        tcpDx.value  = (dx  !== undefined && dx  !== null) ? String(dx)  : "0.0"
        tcpDy.value  = (dy  !== undefined && dy  !== null) ? String(dy)  : "0.0"
        tcpDz.value  = (dz  !== undefined && dz  !== null) ? String(dz)  : "0.0"
        tcpDrx.value = (drx !== undefined && drx !== null) ? String(drx) : "0.0"
        tcpDry.value = (dry !== undefined && dry !== null) ? String(dry) : "0.0"
        tcpDrz.value = (drz !== undefined && drz !== null) ? String(drz) : "0.0"
        basePoseX = x || 0; basePoseY = y || 0; basePoseZ = z || 0
        basePoseRX = rx || 0; basePoseRY = ry || 0; basePoseRZ = rz || 0
        open()
    }

    function openWithJoints(name, dx, dy, dz, drx, dry, drz, j1, j2, j3, j4, j5, j6) {
        actualPositionName = name || ""
        isJointMode = true
        jointDx.value  = (dx  !== undefined && dx  !== null) ? String(dx)  : "0.0"
        jointDy.value  = (dy  !== undefined && dy  !== null) ? String(dy)  : "0.0"
        jointDz.value  = (dz  !== undefined && dz  !== null) ? String(dz)  : "0.0"
        jointDrx.value = (drx !== undefined && drx !== null) ? String(drx) : "0.0"
        jointDry.value = (dry !== undefined && dry !== null) ? String(dry) : "0.0"
        jointDrz.value = (drz !== undefined && drz !== null) ? String(drz) : "0.0"
        baseJ1 = j1 || 0; baseJ2 = j2 || 0; baseJ3 = j3 || 0
        baseJ4 = j4 || 0; baseJ5 = j5 || 0; baseJ6 = j6 || 0
        open()
    }

    function clearState() {
        actualPositionName = ""
        isJointMode = false
        tcpDx.value = "0.0"; tcpDy.value = "0.0"; tcpDz.value = "0.0"
        tcpDrx.value = "0.0"; tcpDry.value = "0.0"; tcpDrz.value = "0.0"
        jointDx.value = "0.0"; jointDy.value = "0.0"; jointDz.value = "0.0"
        jointDrx.value = "0.0"; jointDry.value = "0.0"; jointDrz.value = "0.0"
        basePoseX = 0; basePoseY = 0; basePoseZ = 0
        basePoseRX = 0; basePoseRY = 0; basePoseRZ = 0
        baseJ1 = 0; baseJ2 = 0; baseJ3 = 0; baseJ4 = 0; baseJ5 = 0; baseJ6 = 0
    }

    onClosed: clearState()

    background: Rectangle {
        anchors.fill: parent
        color: "#eeeeee"
        radius: 20
        border.color: "#d0d0d0"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Label {
            text: "Edit Offset"
            color: "#525252"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: `Point: ${actualPositionName}`
            color: "#6a6a6a"
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        GridLayout {
            id: tcpGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignHCenter
            visible: !offsetPopup.isJointMode

            PoseInput { id: tcpDx;  nameInput: "dX";  value: "0.0" }
            PoseInput { id: tcpDy;  nameInput: "dY";  value: "0.0" }
            PoseInput { id: tcpDz;  nameInput: "dZ";  value: "0.0" }
            PoseInput { id: tcpDrx; nameInput: "dRX"; value: "0.0" }
            PoseInput { id: tcpDry; nameInput: "dRY"; value: "0.0" }
            PoseInput { id: tcpDrz; nameInput: "dRZ"; value: "0.0" }
        }

        GridLayout {
            id: jointGrid
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignHCenter
            visible: offsetPopup.isJointMode

            PoseInput { id: jointDx;  nameInput: "dX";  value: "0.0" }
            PoseInput { id: jointDy;  nameInput: "dY";  value: "0.0" }
            PoseInput { id: jointDz;  nameInput: "dZ";  value: "0.0" }
            PoseInput { id: jointDrx; nameInput: "dRX"; value: "0.0" }
            PoseInput { id: jointDry; nameInput: "dRY"; value: "0.0" }
            PoseInput { id: jointDrz; nameInput: "dRZ"; value: "0.0" }
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        // Mover button — same style as PositionPopup's Mover
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            CommonBtn {
                text: "Move"
                style: "secondary"
                Layout.fillWidth: true
                Layout.margins: 0
                onClicked: {
                    if (offsetPopup.isJointMode) {
                        let base   = [baseJ1, baseJ2, baseJ3, baseJ4, baseJ5, baseJ6].join(",")
                        let offset = [parseFloat(jointDx.value) || 0, parseFloat(jointDy.value) || 0,
                                        parseFloat(jointDz.value) || 0, parseFloat(jointDrx.value) || 0,
                                        parseFloat(jointDry.value) || 0, parseFloat(jointDrz.value) || 0].join(",")
                        PositionController.move_joints_with_offset(actualPositionName, base, offset)
                    } else {
                        let base   = [basePoseX, basePoseY, basePoseZ, basePoseRX, basePoseRY, basePoseRZ].join(",")
                        let offset = [parseFloat(tcpDx.value) || 0, parseFloat(tcpDy.value) || 0,
                                    parseFloat(tcpDz.value) || 0, parseFloat(tcpDrx.value) || 0,
                                    parseFloat(tcpDry.value) || 0, parseFloat(tcpDrz.value) || 0].join(",")
                        PositionController.move_j_with_offset(actualPositionName, base, offset)
                    }
                }
            }
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            CommonBtn {
                text: "Cancel"
                style: "danger"
                Layout.fillWidth: true
                Layout.margins: 0
                onClicked: offsetPopup.close()
            }
            CommonBtn {
                text: "Reset"
                style: "primary"
                Layout.fillWidth: true
                Layout.margins: 0
                onClicked: {
                    if (offsetPopup.isJointMode) {
                        jointDx.value = "0.0"; jointDy.value = "0.0"; jointDz.value = "0.0"
                        jointDrx.value = "0.0"; jointDry.value = "0.0"; jointDrz.value = "0.0"
                    } else {
                        tcpDx.value = "0.0"; tcpDy.value = "0.0"; tcpDz.value = "0.0"
                        tcpDrx.value = "0.0"; tcpDry.value = "0.0"; tcpDrz.value = "0.0"
                    }
                }
            }
            CommonBtn {
                text: "Save"
                style: "success"
                Layout.fillWidth: true
                Layout.margins: 0
                onClicked: {
                    if (actualPositionName.length === 0) return
                    saveClicked()
                    offsetPopup.close()
                }
            }
        }
    }
}

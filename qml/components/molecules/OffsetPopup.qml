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
    property alias dxValue: tcpDx.value
    property alias dyValue: tcpDy.value
    property alias dzValue: tcpDz.value
    property alias drxValue: tcpDrx.value
    property alias dryValue: tcpDry.value
    property alias drzValue: tcpDrz.value
    property alias jointDxValue: jointDx.value
    property alias jointDyValue: jointDy.value
    property alias jointDzValue: jointDz.value
    property alias jointDrxValue: jointDrx.value
    property alias jointDryValue: jointDry.value
    property alias jointDrzValue: jointDrz.value

    signal saveClicked()

    function openWithTcp(name, dx, dy, dz, drx, dry, drz) {
        actualPositionName = name || ""
        isJointMode = false
        tcpDx.value = (dx !== undefined && dx !== null) ? String(dx) : "0.0"
        tcpDy.value = (dy !== undefined && dy !== null) ? String(dy) : "0.0"
        tcpDz.value = (dz !== undefined && dz !== null) ? String(dz) : "0.0"
        tcpDrx.value = (drx !== undefined && drx !== null) ? String(drx) : "0.0"
        tcpDry.value = (dry !== undefined && dry !== null) ? String(dry) : "0.0"
        tcpDrz.value = (drz !== undefined && drz !== null) ? String(drz) : "0.0"
        open()
    }

    function openWithJoints(name, dx, dy, dz, drx, dry, drz) {
        actualPositionName = name || ""
        isJointMode = true
        jointDx.value = (dx !== undefined && dx !== null) ? String(dx) : "0.0"
        jointDy.value = (dy !== undefined && dy !== null) ? String(dy) : "0.0"
        jointDz.value = (dz !== undefined && dz !== null) ? String(dz) : "0.0"
        jointDrx.value = (drx !== undefined && drx !== null) ? String(drx) : "0.0"
        jointDry.value = (dry !== undefined && dry !== null) ? String(dry) : "0.0"
        jointDrz.value = (drz !== undefined && drz !== null) ? String(drz) : "0.0"
        open()
    }

    function clearState() {
        actualPositionName = ""
        isJointMode = false
        tcpDx.value = "0.0"
        tcpDy.value = "0.0"
        tcpDz.value = "0.0"
        tcpDrx.value = "0.0"
        tcpDry.value = "0.0"
        tcpDrz.value = "0.0"
        jointDx.value = "0.0"
        jointDy.value = "0.0"
        jointDz.value = "0.0"
        jointDrx.value = "0.0"
        jointDry.value = "0.0"
        jointDrz.value = "0.0"
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
            text: `Position: ${actualPositionName}`
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

            PoseInput { id: tcpDx; nameInput: "dX"; value: "0.0" }
            PoseInput { id: tcpDy; nameInput: "dY"; value: "0.0" }
            PoseInput { id: tcpDz; nameInput: "dZ"; value: "0.0" }
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

            PoseInput { id: jointDx; nameInput: "dX"; value: "0.0" }
            PoseInput { id: jointDy; nameInput: "dY"; value: "0.0" }
            PoseInput { id: jointDz; nameInput: "dZ"; value: "0.0" }
            PoseInput { id: jointDrx; nameInput: "dRX"; value: "0.0" }
            PoseInput { id: jointDry; nameInput: "dRY"; value: "0.0" }
            PoseInput { id: jointDrz; nameInput: "dRZ"; value: "0.0" }
        }

        Rectangle { height: 1; color: "#b8b8b8"; Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            CommonBtn {
                text: "Cancel"
                style: "danger"
                onClicked: offsetPopup.close()
            }
            CommonBtn {
                text: "Reset"
                style: "warning"
                onClicked: {
                    if (offsetPopup.isJointMode) {
                        jointDx.value  = "0.0"
                        jointDy.value  = "0.0"
                        jointDz.value  = "0.0"
                        jointDrx.value = "0.0"
                        jointDry.value = "0.0"
                        jointDrz.value = "0.0"
                    } else {
                        tcpDx.value  = "0.0"
                        tcpDy.value  = "0.0"
                        tcpDz.value  = "0.0"
                        tcpDrx.value = "0.0"
                        tcpDry.value = "0.0"
                        tcpDrz.value = "0.0"
                    }
                }
            }
            CommonBtn {
                text: "Save"
                style: "success"
                onClicked: {
                    if (actualPositionName.length === 0) return
                    saveClicked()
                    offsetPopup.close()
                }
            }
        }
    }
}

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

    signal movePressed(string poseName, var poses, string poseType)
    signal moveReleased()
    signal editClicked(int poseId)
    signal deleteClicked(int poseId)
    signal offsetClicked(int poseId)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Row 1: Name · Type tag · spacer · Action buttons ──────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Title {
                titleText: nameText
                font.pixelSize: 16
                font.bold: false
                color: "#8f8f8f"
            }

            Tag {
                text: poseType === "joint" ? "Joints" : "Cartesian"
                backgroundColor: poseType === "joint" ? "#ffd6d6" : "#d6e3ff"
            }

            Item { Layout.fillWidth: true }

            // Buttons pinned to the right — always visible
            RowLayout {
                spacing: 6

                IconBtn {
                    iconSource: "../../../assets/icons/industrial-robot.png"
                    onPressed: positionItem.movePressed(nameText, poses, poseType)
                    onReleased: positionItem.moveReleased()
                }
                IconBtn {
                    iconSource: "../../../assets/icons/edit.png"
                    onClicked: positionItem.editClicked(poseId)
                }
                IconBtn {
                    iconSource: "../../../assets/icons/settings.png"
                    onClicked: positionItem.offsetClicked(poseId)
                }
                IconBtn {
                    iconSource: "../../../assets/icons/trash-can.png"
                    onClicked: positionItem.deleteClicked(poseId)
                }
            }
        }

        // ── Row 2: Main values (X/Y/Z/RX/RY/RZ or J1–J6) ─────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: poseType === "joint" ? [
                    { label: "J1", value: poses ? poses.j1 : 0, color: "#d6ffd7" },
                    { label: "J2", value: poses ? poses.j2 : 0, color: "#d6ffd7" },
                    { label: "J3", value: poses ? poses.j3 : 0, color: "#d6ffd7" },
                    { label: "J4", value: poses ? poses.j4 : 0, color: "#d6ffd7" },
                    { label: "J5", value: poses ? poses.j5 : 0, color: "#d6ffd7" },
                    { label: "J6", value: poses ? poses.j6 : 0, color: "#d6ffd7" },
                ] : [
                    { label: "X",  value: poses ? poses.posX  : 0, color: "#d6ffd7" },
                    { label: "Y",  value: poses ? poses.posY  : 0, color: "#d6ffd7" },
                    { label: "Z",  value: poses ? poses.posZ  : 0, color: "#d6ffd7" },
                    { label: "RX", value: poses ? poses.posRX : 0, color: "#d6ffd7" },
                    { label: "RY", value: poses ? poses.posRY : 0, color: "#d6ffd7" },
                    { label: "RZ", value: poses ? poses.posRZ : 0, color: "#d6ffd7" },
                ]

                Tag {
                    text: `${modelData.label}: ${Number(modelData.value || 0).toFixed(2)}`
                    backgroundColor: modelData.color
                }
            }
        }

        // ── Row 3: Offset values (DX/DY/DZ/DRX/DRY/DRZ) ──────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: poseType === "joint" ? [
                    { label: "DX",  value: poses ? poses.dx  : 0, color: "#d6e3ff" },
                    { label: "DY",  value: poses ? poses.dy  : 0, color: "#d6e3ff" },
                    { label: "DZ",  value: poses ? poses.dz  : 0, color: "#d6e3ff" },
                    { label: "DRX", value: poses ? poses.drx : 0, color: "#d6e3ff" },
                    { label: "DRY", value: poses ? poses.dry : 0, color: "#d6e3ff" },
                    { label: "DRZ", value: poses ? poses.drz : 0, color: "#d6e3ff" },
                ] : [
                    { label: "DX",  value: poses ? poses.posDX  : 0, color: "#d6e3ff" },
                    { label: "DY",  value: poses ? poses.posDY  : 0, color: "#d6e3ff" },
                    { label: "DZ",  value: poses ? poses.posDZ  : 0, color: "#d6e3ff" },
                    { label: "DRX", value: poses ? poses.posDRX : 0, color: "#d6e3ff" },
                    { label: "DRY", value: poses ? poses.posDRY : 0, color: "#d6e3ff" },
                    { label: "DRZ", value: poses ? poses.posDRZ : 0, color: "#d6e3ff" },
                ]

                Tag {
                    text: `${modelData.label}: ${Number(modelData.value || 0).toFixed(2)}`
                    backgroundColor: modelData.color
                }
            }
        }
    }
}

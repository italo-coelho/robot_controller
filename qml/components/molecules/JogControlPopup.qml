import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: jogWindow
    title: "Jog Control"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false

    width:  456
    height: mainCol.implicitHeight + 32  // 16px top + content + 16px bottom

    // ── State ─────────────────────────────────────────────────────────────────
    property var  tcpPose:    [0, 0, 0, 0, 0, 0]
    property var  jointPose:  [0, 0, 0, 0, 0, 0]
    property bool isJointMode: false
    property real jogStep:    10
    property var  stepPresets: [1, 5, 10, 50, 100]

    // Drag tracking
    property real _dx: 0
    property real _dy: 0

    // Position on first show
    Component.onCompleted: {
        x = Screen.width  - width  - 40
        y = (Screen.height - height) / 2
    }

    // ── Position — Python QTimer pushes updates at 100 ms, no QML timer needed
    Connections {
        target: PositionController
        function onJogStateUpdated(state) {
            jogWindow.tcpPose   = state["tcp"]
            jogWindow.jointPose = state["joints"]
        }
    }

    // ── Shell ─────────────────────────────────────────────────────────────────
    Rectangle {
        id: shell
        anchors.fill: parent
        color: "#F4F6F9"
        radius: 14
        border.color: "#D1D5DB"
        border.width: 1
        clip: true

        ColumnLayout {
            id: mainCol
            anchors {
                left:   parent.left
                right:  parent.right
                top:    parent.top
                margins: 16
            }
            spacing: 12

            // ── Header (drag handle) ──────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                height: 28

                // Drag the whole window via the header
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 36   // leave room for close btn
                    cursorShape: Qt.SizeAllCursor
                    onPressed:  { jogWindow._dx = mouseX; jogWindow._dy = mouseY }
                    onPositionChanged: {
                        if (pressed) {
                            jogWindow.x += mouseX - jogWindow._dx
                            jogWindow.y += mouseY - jogWindow._dy
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle { width: 8; height: 8; radius: 4; color: "#6366F1" }

                    Text {
                        text: "Jog Control"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#111827"
                    }

                    Item { Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: xMouse.containsMouse ? "#E5E7EB" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.pixelSize: 18
                            color: "#6B7280"
                        }

                        MouseArea {
                            id: xMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: jogWindow.hide()
                        }
                    }
                }
            }

            // ── Tab bar ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 17
                color: "#E5E7EB"

                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0

                    Rectangle {
                        width: parent.width / 2; height: parent.height; radius: height / 2
                        color: !jogWindow.isJointMode ? "#FFFFFF" : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "Tool"
                            font.pixelSize: 12; font.bold: !jogWindow.isJointMode
                            color: !jogWindow.isJointMode ? "#111827" : "#6B7280"
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: jogWindow.isJointMode = false }
                    }

                    Rectangle {
                        width: parent.width / 2; height: parent.height; radius: height / 2
                        color: jogWindow.isJointMode ? "#FFFFFF" : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "Joints"
                            font.pixelSize: 12; font.bold: jogWindow.isJointMode
                            color: jogWindow.isJointMode ? "#111827" : "#6B7280"
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: jogWindow.isJointMode = true }
                    }
                }
            }

            // ── Step selector ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "STEP"
                    font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                    color: "#6B7280"
                }

                Repeater {
                    model: jogWindow.stepPresets

                    Rectangle {
                        width: 40; height: 26; radius: 13
                        color:        jogWindow.jogStep === modelData ? "#6366F1" : (sm.containsMouse ? "#E5E7EB" : "#FFFFFF")
                        border.color: jogWindow.jogStep === modelData ? "#6366F1" : "#D1D5DB"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11; font.bold: jogWindow.jogStep === modelData
                            color: jogWindow.jogStep === modelData ? "#FFFFFF" : "#374151"
                        }

                        MouseArea {
                            id: sm; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: jogWindow.jogStep = modelData
                        }
                    }
                }

                Text { text: "mm / °"; font.pixelSize: 10; color: "#9CA3AF" }
            }

            Rectangle { height: 1; color: "#E5E7EB"; Layout.fillWidth: true }

            // ── TOOL MODE ─────────────────────────────────────────────────────
            RowLayout {
                visible: !jogWindow.isJointMode
                Layout.fillWidth: true
                spacing: 12

                // Translation
                GridLayout {
                    columns: 2; rowSpacing: 8; columnSpacing: 8

                    Repeater {
                        model: [
                            { l: "X −", a: "x",  d: -1, c: "#E74C3C" },
                            { l: "X +", a: "x",  d:  1, c: "#E74C3C" },
                            { l: "Y −", a: "y",  d: -1, c: "#27AE60" },
                            { l: "Y +", a: "y",  d:  1, c: "#27AE60" },
                            { l: "Z −", a: "z",  d: -1, c: "#2980B9" },
                            { l: "Z +", a: "z",  d:  1, c: "#2980B9" },
                        ]
                        Rectangle {
                            width: 72; height: 36; radius: 18
                            color: bm.pressed ? Qt.darker(modelData.c, 1.3) : (bm.containsMouse ? Qt.darker(modelData.c, 1.1) : modelData.c)
                            Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 12; font.bold: true; color: "#FFF" }
                            MouseArea {
                                id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPressed:  PositionController.jog_cartesian(modelData.a, modelData.d, jogWindow.jogStep)
                                onReleased: PositionController.stop_motion()
                                onCanceled: PositionController.stop_motion()
                            }
                        }
                    }
                }

                // Rotation
                GridLayout {
                    columns: 2; rowSpacing: 8; columnSpacing: 8

                    Repeater {
                        model: [
                            { l: "RX−", a: "rx", d: -1, c: "#C0392B" },
                            { l: "RX+", a: "rx", d:  1, c: "#C0392B" },
                            { l: "RY−", a: "ry", d: -1, c: "#1A7A40" },
                            { l: "RY+", a: "ry", d:  1, c: "#1A7A40" },
                            { l: "RZ−", a: "rz", d: -1, c: "#1A5276" },
                            { l: "RZ+", a: "rz", d:  1, c: "#1A5276" },
                        ]
                        Rectangle {
                            width: 72; height: 36; radius: 18
                            color: bm2.pressed ? Qt.darker(modelData.c, 1.3) : (bm2.containsMouse ? Qt.darker(modelData.c, 1.1) : modelData.c)
                            Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 12; font.bold: true; color: "#FFF" }
                            MouseArea {
                                id: bm2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPressed:  PositionController.jog_cartesian(modelData.a, modelData.d, jogWindow.jogStep)
                                onReleased: PositionController.stop_motion()
                                onCanceled: PositionController.stop_motion()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Cartesian readout — color-coded to match buttons
                GridLayout {
                    columns: 2; rowSpacing: 6; columnSpacing: 10

                    Text { text: "X";  font.pixelSize: 10; font.bold: true; color: "#E74C3C" }
                    Text { text: jogWindow.tcpPose[0].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                    Text { text: "Y";  font.pixelSize: 10; font.bold: true; color: "#27AE60" }
                    Text { text: jogWindow.tcpPose[1].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                    Text { text: "Z";  font.pixelSize: 10; font.bold: true; color: "#2980B9" }
                    Text { text: jogWindow.tcpPose[2].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                    Text { text: "RX"; font.pixelSize: 10; font.bold: true; color: "#C0392B" }
                    Text { text: jogWindow.tcpPose[3].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                    Text { text: "RY"; font.pixelSize: 10; font.bold: true; color: "#1A7A40" }
                    Text { text: jogWindow.tcpPose[4].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                    Text { text: "RZ"; font.pixelSize: 10; font.bold: true; color: "#1A5276" }
                    Text { text: jogWindow.tcpPose[5].toFixed(2); font.pixelSize: 11; font.family: "monospace"; color: "#111827"; Layout.minimumWidth: 62; horizontalAlignment: Text.AlignRight }
                }
            }

            // ── JOINTS MODE ───────────────────────────────────────────────────
            ColumnLayout {
                visible: jogWindow.isJointMode
                Layout.fillWidth: true
                spacing: 8

                property var jColors: ["#E74C3C", "#E67E22", "#D4AC0D", "#27AE60", "#2980B9", "#8E44AD"]

                Repeater {
                    model: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        property color jc: parent.jColors[index]

                        Text {
                            text: "J" + (index + 1)
                            font.pixelSize: 12; font.bold: true; color: jc
                            Layout.minimumWidth: 24
                        }

                        Rectangle {
                            width: 72; height: 36; radius: 18
                            color: jnm.pressed ? Qt.darker(jc, 1.3) : (jnm.containsMouse ? Qt.darker(jc, 1.1) : jc)
                            Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 20; font.bold: true; color: "#FFF" }
                            MouseArea {
                                id: jnm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPressed:  PositionController.jog_joint(index, -1, jogWindow.jogStep)
                                onReleased: PositionController.stop_motion()
                                onCanceled: PositionController.stop_motion()
                            }
                        }

                        Rectangle {
                            width: 72; height: 36; radius: 18
                            color: jpm.pressed ? Qt.darker(jc, 1.3) : (jpm.containsMouse ? Qt.darker(jc, 1.1) : jc)
                            Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 20; font.bold: true; color: "#FFF" }
                            MouseArea {
                                id: jpm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPressed:  PositionController.jog_joint(index, 1, jogWindow.jogStep)
                                onReleased: PositionController.stop_motion()
                                onCanceled: PositionController.stop_motion()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: (typeof jogWindow.jointPose[index] === "number"
                                   ? jogWindow.jointPose[index].toFixed(2) : "0.00") + "°"
                            font.pixelSize: 12; font.family: "monospace"; color: "#111827"
                            horizontalAlignment: Text.AlignRight
                            Layout.minimumWidth: 72
                        }
                    }
                }
            }
        }
    }
}

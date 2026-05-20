import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtWebEngine 1.10
import Qt5Compat.GraphicalEffects

Window {
    id: robotWindow
    title: "3D Viewer"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false

    width:  480
    height: 560

    // Drag tracking
    property real _dx: 0
    property real _dy: 0

    // Position on first show; clamp width to screen if the display is very narrow.
    Component.onCompleted: {
        let maxW = Screen.desktopAvailableWidth - 32
        if (maxW > 0 && maxW < width)
            width = maxW
        x = Screen.width  - width  - 40
        y = (Screen.height - height) / 2
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
            anchors.fill: parent
            anchors.margins: 16
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
                    onPressed:  { robotWindow._dx = mouseX; robotWindow._dy = mouseY }
                    onPositionChanged: {
                        if (pressed) {
                            robotWindow.x += mouseX - robotWindow._dx
                            robotWindow.y += mouseY - robotWindow._dy
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle { width: 8; height: 8; radius: 4; color: "#FE6900" }

                    Text {
                        text: "3D Viewer"
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
                            onClicked: robotWindow.hide()
                        }
                    }
                }
            }

            // ── 3D viewer ─────────────────────────────────────────────────────
            // Lazy-loaded so the WebEngineView (and its WS connection) only
            // exists while the popup is open. Closing the window releases it.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    id: webLoader
                    anchors.fill: parent
                    active: robotWindow.visible
                    sourceComponent: viewerComponent
                }

                // Border traced on top of the masked WebView.
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 10
                    border.color: "#D1D5DB"
                    border.width: 1
                    antialiasing: true
                }
            }
        }
    }

    Component {
        id: viewerComponent
        WebEngineView {
            id: web
            url: typeof robotViewerUrl !== "undefined" ? robotViewerUrl : ""
            backgroundColor: "transparent"
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: web.width
                    height: web.height
                    radius: 10
                }
            }
        }
    }
}

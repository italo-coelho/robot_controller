import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    color: "#0078d4"

    property bool compact: false
    property string currentPage: "Positions"
    signal pageSelected(string pageName)

    // ── Hidden unlock: 10 rapid logo taps emit unlockRequested ────────────────
    // Resets the counter if the user pauses more than 500 ms between taps.
    signal unlockRequested()
    property int _logoTapCount: 0
    property real _lastLogoTapMs: 0

    function _registerLogoTap() {
        let now = Date.now()
        _logoTapCount = (now - _lastLogoTapMs > 500) ? 1 : _logoTapCount + 1
        _lastLogoTapMs = now
        if (_logoTapCount >= 10) {
            _logoTapCount = 0
            unlockRequested()
        }
    }

    readonly property var navModel: [
        { label: "Points",  page: "Positions"    },
        { label: "Systems", page: "Equipamentos" }
    ]

    // ── Wide / vertical layout ────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        visible: !sidebar.compact

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 75
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 10
                height: parent.height
                radius: 16
                clip: true
                color: "transparent"
                visible: logoImage.status === Image.Ready

                Image {
                    id: logoImage
                    anchors.fill: parent
                    source: "../../../assets/icons/logo.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Label {
                anchors.centerIn: parent
                text: "Robotine"
                color: "white"
                font.bold: true
                font.pixelSize: 18
                visible: logoImage.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: sidebar._registerLogoTap()
            }
        }

        Rectangle { height: 1; color: "#2196f3"; Layout.fillWidth: true }

        Repeater {
            model: sidebar.navModel
            delegate: Rectangle {
                width: parent.width
                height: 44
                radius: 8
                color: sidebar.currentPage === modelData.page ? "#2196f3" : "transparent"

                Text {
                    text: modelData.label
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:  if (sidebar.currentPage !== modelData.page) parent.color = "#1a8fe8"
                    onExited:   parent.color = sidebar.currentPage === modelData.page ? "#2196f3" : "transparent"
                    onClicked: {
                        sidebar.currentPage = modelData.page
                        sidebar.pageSelected(modelData.page)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ── Compact / horizontal layout (portrait or narrow widths) ───────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        visible: sidebar.compact

        Item {
            Layout.preferredHeight: 32
            Layout.preferredWidth: compactLogoImage.status === Image.Ready
                                     ? 32 * compactLogoImage.implicitWidth / Math.max(1, compactLogoImage.implicitHeight)
                                     : compactLogoLabel.implicitWidth
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: compactLogoImage
                anchors.fill: parent
                source: "../../../assets/icons/logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
            }

            Label {
                id: compactLogoLabel
                anchors.centerIn: parent
                text: "Robotine"
                color: "white"
                font.bold: true
                font.pixelSize: 16
                visible: compactLogoImage.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: sidebar._registerLogoTap()
            }
        }

        Item { Layout.fillWidth: true }

        Repeater {
            model: sidebar.navModel
            delegate: Rectangle {
                id: navPill
                Layout.preferredWidth: navText.implicitWidth + 24
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 16
                color: {
                    if (sidebar.currentPage === modelData.page) return "#2196f3"
                    return pillMouse.containsMouse ? "#1a8fe8" : "transparent"
                }
                border.color: "#2196f3"
                border.width: 1

                Text {
                    id: navText
                    anchors.centerIn: parent
                    text: modelData.label
                    color: "white"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sidebar.currentPage = modelData.page
                        sidebar.pageSelected(modelData.page)
                    }
                }
            }
        }
    }
}

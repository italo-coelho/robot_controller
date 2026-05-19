import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components/organisms"
import "pages"

ApplicationWindow {
    id: mainWindow
    visible: true
    title: "Robotine Controller"
    visibility: Window.Maximized

    readonly property bool isNarrow: width < 900
    readonly property bool isPortrait: height > width

    // Unlocked for the rest of the session once the user has tapped the logo
    // 10 times rapidly AND entered the correct password. Read by ListPosition
    // via Window.window.deleteUnlocked.
    property bool deleteUnlocked: false

    Rectangle {
        anchors.fill: parent
        color: "#f5f7fa"

        GridLayout {
            anchors.fill: parent
            rows:    mainWindow.isNarrow ? 2 : 1
            columns: mainWindow.isNarrow ? 1 : 2
            rowSpacing: 0
            columnSpacing: 0

            Sidebar {
                id: sidebar
                Layout.preferredWidth:  mainWindow.isNarrow ? -1 : 220
                Layout.fillWidth:       mainWindow.isNarrow
                Layout.preferredHeight: mainWindow.isNarrow ? 56 : -1
                Layout.fillHeight:      !mainWindow.isNarrow
                compact: mainWindow.isNarrow

                onPageSelected: function(pageName) {
                    let pageUrl = Qt.resolvedUrl("pages/" + pageName + "Page.qml")
                    stackView.replace(pageUrl)
                }

                onUnlockRequested: passwordPopup.open()

                Component.onCompleted: {
                    pageSelected("Positions")
                }
            }

            StackView {
                id: stackView
                Layout.fillWidth: true
                Layout.fillHeight: true
                initialItem: Qt.resolvedUrl("pages/PositionsPage.qml")
                clip: true
                focus: true

                replaceEnter: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                }
                replaceExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
                }
            }
        }
    }

    // ── Hidden unlock for the "Delete List" button ────────────────────────────
    Popup {
        id: passwordPopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        closePolicy: Popup.CloseOnEscape
        padding: 24

        width: 360

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#D1D5DB"
            border.width: 1
        }

        function tryUnlock() {
            if (pwField.text === "16072000") {
                mainWindow.deleteUnlocked = true
                close()
            } else {
                pwError.visible = true
                pwField.selectAll()
            }
        }

        onOpened: {
            pwField.text = ""
            pwError.visible = false
            pwField.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            spacing: 14

            Label {
                text: "Unlock"
                font.pixelSize: 18
                font.bold: true
                color: "#111827"
            }

            Label {
                text: "Enter password to enable the Delete List button."
                font.pixelSize: 13
                color: "#6B7280"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            TextField {
                id: pwField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                onAccepted: passwordPopup.tryUnlock()
                onTextChanged: pwError.visible = false
            }

            Label {
                id: pwError
                text: "Incorrect password"
                color: "#DC3545"
                font.pixelSize: 12
                visible: false
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    onClicked: passwordPopup.close()
                }
                Button {
                    text: "Unlock"
                    highlighted: true
                    onClicked: passwordPopup.tryUnlock()
                }
            }
        }
    }
}

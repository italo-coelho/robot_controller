import QtQuick 2.15

Rectangle {
    id: root

    property string label: ""
    property bool isCurrent: false
    property bool isSubItem: false
    // pill = horizontal compact look (centered text, no accent bar)
    property bool pill: false
    // chevron for expandable parents (wide layout only)
    property bool showChevron: false
    property bool expanded: false

    signal clicked()

    radius: pill ? 16 : 10
    antialiasing: true
    implicitHeight: pill ? 32 : 48
    implicitWidth: pill ? labelText.implicitWidth + 28 : 200
    color: isCurrent
           ? "#2196f3"
           : navMouse.pressed
             ? Qt.rgba(1, 1, 1, 0.22)
             : navMouse.containsMouse
               ? Qt.rgba(1, 1, 1, 0.16)
               : Qt.rgba(1, 1, 1, 0.08)
    border.color: isCurrent ? "#64b5f6" : Qt.rgba(1, 1, 1, 0.22)
    border.width: 1

    Behavior on color       { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Active-page accent bar on the left (wide column layout only).
    Rectangle {
        visible: !root.pill && !root.isSubItem
        width: 4
        height: parent.height * 0.55
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: "white"
        opacity: root.isCurrent ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        id: labelText
        text: root.label
        color: "white"
        font.pixelSize: root.isSubItem ? 13 : (root.pill ? 14 : 15)
        font.bold: root.isCurrent
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.pill ? undefined : parent.left
        anchors.leftMargin: root.pill ? 0 : (root.isSubItem ? 32 : 18)
        anchors.horizontalCenter: root.pill ? parent.horizontalCenter : undefined
    }

    Text {
        visible: root.showChevron && !root.pill
        text: root.expanded ? "▾" : "▸"
        color: "white"
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 14
    }

    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

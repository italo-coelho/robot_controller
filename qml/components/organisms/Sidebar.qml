import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.10
import Qt5Compat.GraphicalEffects
import "../molecules"

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

    // Hierarchical nav. Items without a `page` are dropdown headers; their
    // `children` render indented below when expanded.
    readonly property var navModel: [
        { label: "Points",       page: "Positions"    },
        { label: "Trajectories", page: "Trajectories" },
        { label: "Systems",      page: "",            children: [
            { label: "Control",       page: "Equipamentos"  },
            { label: "Configuration", page: "Configuration" }
        ]}
    ]

    // label -> bool. Tracks which dropdown headers are user-expanded.
    property var expanded: ({})

    function _toggleExpanded(label) {
        let m = {}
        for (let k in expanded) m[k] = expanded[k]
        m[label] = !m[label]
        expanded = m
    }

    // True when the item or any descendant is the current page.
    function _isItemActive(item) {
        if (item.page && sidebar.currentPage === item.page) return true
        if (item.children) {
            for (let i = 0; i < item.children.length; ++i)
                if (_isItemActive(item.children[i])) return true
        }
        return false
    }

    function _isHeaderExpanded(item) {
        return !!expanded[item.label] || _isItemActive(item)
    }

    // Flatten leaves (items that have a page) for the compact horizontal row.
    function _flatLeaves(items) {
        let out = []
        for (let i = 0; i < items.length; ++i) {
            const it = items[i]
            if (it.page) out.push(it)
            if (it.children) out = out.concat(_flatLeaves(it.children))
        }
        return out
    }

    readonly property var _compactItems: _flatLeaves(navModel)

    // ── Wide / vertical layout ────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        anchors.bottomMargin: sidebar.compact ? 20 : (robotViewerFrame.height + 32)
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
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                NavButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    label: modelData.label
                    isCurrent: modelData.page
                               ? sidebar.currentPage === modelData.page
                               : sidebar._isItemActive(modelData)
                    showChevron: !!modelData.children
                    expanded: sidebar._isHeaderExpanded(modelData)
                    onClicked: {
                        if (modelData.children && !modelData.page) {
                            sidebar._toggleExpanded(modelData.label)
                        } else {
                            sidebar.currentPage = modelData.page
                            sidebar.pageSelected(modelData.page)
                        }
                    }
                }

                Repeater {
                    model: sidebar._isHeaderExpanded(modelData) && modelData.children
                           ? modelData.children
                           : []
                    delegate: NavButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        isSubItem: true
                        label: modelData.label
                        isCurrent: sidebar.currentPage === modelData.page
                        onClicked: {
                            sidebar.currentPage = modelData.page
                            sidebar.pageSelected(modelData.page)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ── 3D robot viewer (wide layout only) ────────────────────────────────
    // Anchored directly to the sidebar so 90% of the sidebar's full width is
    // honored regardless of the ColumnLayout's inner margins. WebEngineView
    // bypasses scenegraph clipping, so corners are rounded via an OpacityMask
    // layer effect.
    Item {
        id: robotViewerFrame
        visible: !sidebar.compact
        width: Math.round(sidebar.width * 0.9)
        height: width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter

        WebEngineView {
            id: robotViewerWeb
            anchors.fill: parent
            url: typeof robotViewerUrl !== "undefined" ? robotViewerUrl : ""
            backgroundColor: "transparent"
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: robotViewerWeb.width
                    height: robotViewerWeb.height
                    radius: 16
                }
            }
        }

        // Dark-blue rounded border traced on top of the masked WebView.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 16
            border.color: "#0b3d91"
            border.width: 4
            antialiasing: true
        }
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
            model: sidebar._compactItems
            delegate: NavButton {
                Layout.alignment: Qt.AlignVCenter
                pill: true
                label: modelData.label
                isCurrent: sidebar.currentPage === modelData.page
                onClicked: {
                    sidebar.currentPage = modelData.page
                    sidebar.pageSelected(modelData.page)
                }
            }
        }
    }
}

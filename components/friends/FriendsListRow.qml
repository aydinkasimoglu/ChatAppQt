pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: root

    property int rowIndex: 0
    property bool collapsed: false
    property int rowHeight: 62
    readonly property bool hovered: hoverHandler.hovered
    default property alias content: contentRow.data

    width: ListView.view ? ListView.view.width : 0
    height: collapsed ? 0 : rowHeight
    visible: height > 0
    clip: true

    Behavior on height {
        NumberAnimation { duration: Theme.animFast }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: 8
        color: root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        visible: !root.hovered && root.rowIndex > 0 && !root.collapsed
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 1
        color: Theme.surfaceBorder
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
    }

    HoverHandler {
        id: hoverHandler
    }
}
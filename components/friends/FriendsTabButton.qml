pragma ComponentBehavior: Bound
import QtQuick
import "../.."

Item {
    id: root

    required property string tabId
    required property string label
    property bool current: false

    signal clicked(string tabId)

    implicitWidth: tabLabel.implicitWidth + 16
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.current
               ? Qt.rgba(1, 1, 1, 0.1)
               : (hoverHandler.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Text {
        id: tabLabel
        anchors.centerIn: parent
        text: root.label
        color: root.current ? Theme.textPrimary : Theme.textMuted
        font.pixelSize: 14
        font.weight: root.current ? Font.DemiBold : Font.Normal

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        radius: 1
        color: Theme.textPrimary
        visible: root.current
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root.tabId)
    }
}
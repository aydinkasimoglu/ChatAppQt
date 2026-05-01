pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."
import "../.."

Rectangle {
    id: headerBar

    required property string conversationTitle

    implicitHeight: 48
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        Text {
            text: headerBar.conversationTitle.length > 0
                  ? headerBar.conversationTitle
                  : "Direct Messages"
            color: Theme.textPrimary
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
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

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.surfaceBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        DmConversationAvatar {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            name: headerBar.conversationTitle
            fallbackInitial: "D"
            avatarSize: 28
            fontPixelSize: 13
        }

        Text {
            text: headerBar.conversationTitle.length > 0
                  ? headerBar.conversationTitle
                  : "Direct Messages"
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
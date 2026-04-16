pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."
import "../.."

Item {
    id: root

    required property string conversationTitle
    property bool loading: false
    property real sidePadding: 16

    implicitHeight: introColumn.implicitHeight

    ColumnLayout {
        id: introColumn

        x: root.sidePadding
        width: Math.max(0, root.width - root.sidePadding * 2)
        spacing: 8

        DmConversationAvatar {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            name: root.conversationTitle
            avatarSize: 72
            fontPixelSize: 28
        }

        Text {
            text: root.conversationTitle
            color: Theme.textPrimary
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        Text {
            text: root.loading
                  ? qsTr("Loading your direct message history with <b>%1</b>...").arg(root.conversationTitle)
                  : qsTr("This is the beginning of your direct message history with <b>%1</b>.").arg(root.conversationTitle)
            color: Theme.textMuted
            font.pixelSize: 14
            textFormat: Text.StyledText
        }
    }
}
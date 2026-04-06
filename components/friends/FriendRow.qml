pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../.."

FriendsListRow {
    id: root

    required property int listIndex
    required property string friendshipId
    required property string userId
    required property string username
    required property string email
    required property bool isOnline
    property bool onlineOnly: false
    property color avatarColor: Theme.accentBlue

    signal dmRequested(string recipientId, string recipientName)
    signal removeRequested(string friendshipId)

    rowIndex: root.listIndex
    collapsed: root.onlineOnly && !root.isOnline

    FriendAvatar {
        name: root.username
        backgroundColor: root.avatarColor
        showIndicator: true
        indicatorColor: root.isOnline ? "#23a559" : "#80848e"
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.username
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.email
            color: Theme.textMuted
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    Row {
        visible: root.hovered
        spacing: 8

        FriendsIconButton {
            iconSource: "/assets/icons/chat_bubble.svg"
            onClicked: root.dmRequested(root.userId, root.username)
        }

        FriendsIconButton {
            iconSource: "/assets/icons/delete.svg"
            onClicked: root.removeRequested(root.friendshipId)
        }
    }
}
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../.."

FriendsListRow {
    id: root

    required property int listIndex
    required property string userId
    required property string username
    required property string email

    signal unblockRequested(string userId)

    rowIndex: root.listIndex

    FriendAvatar {
        name: root.username
        backgroundColor: Qt.rgba(0.5, 0.5, 0.5, 0.4)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.username
            color: Theme.textMuted
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.email
            color: Theme.textSubtle
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    FriendsTextButton {
        visible: root.hovered
        Layout.alignment: Qt.AlignVCenter
        text: "Unblock"
        normalColor: Theme.surfaceBorder
        hoverColor: "#ed4245"
        normalTextColor: Theme.textPrimary
        hoverTextColor: "#ffffff"
        onClicked: root.unblockRequested(root.userId)
    }
}
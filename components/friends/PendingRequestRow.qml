pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../.."

FriendsListRow {
    id: root

    required property int listIndex
    required property string friendshipId
    required property string username
    required property string direction
    property color avatarColor: Theme.accentBlue

    readonly property bool incomingRequest: direction === "incoming"
    readonly property string directionLabel: incomingRequest ? "Incoming" : "Outgoing"
    readonly property color directionColor: incomingRequest ? Theme.accentBlue : "#80848e"
    readonly property var actions: incomingRequest ? ["accept", "reject"] : ["cancel"]

    signal acceptRequested(string friendshipId)
    signal rejectRequested(string friendshipId)
    signal cancelRequested(string friendshipId)

    function actionSymbol(actionName) {
        return actionName === "accept" ? "\u2713" : "\u2715"
    }

    function triggerAction(actionName) {
        if (actionName === "accept") {
            root.acceptRequested(root.friendshipId)
        } else if (actionName === "reject") {
            root.rejectRequested(root.friendshipId)
        } else {
            root.cancelRequested(root.friendshipId)
        }
    }

    rowIndex: root.listIndex

    FriendAvatar {
        name: root.username
        backgroundColor: root.avatarColor
        showIndicator: true
        indicatorColor: root.directionColor
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
            text: root.directionLabel + " Friend Request"
            color: Theme.textMuted
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    Row {
        visible: root.hovered
        spacing: 8

        Repeater {
            model: root.actions

            delegate: FriendsIconButton {
                required property string modelData

                symbol: root.actionSymbol(modelData)
                onClicked: root.triggerAction(modelData)
            }
        }
    }
}
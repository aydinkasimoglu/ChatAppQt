pragma ComponentBehavior: Bound

import QtQuick
import "."
import "../.."

Item {
    id: bubble

    required property string body
    required property bool isSelf
    required property string timeLabel
    required property string createdAt
    required property string senderUsername

    // False for consecutive messages from the same sender
    property bool showSenderInfo: true

    readonly property int avatarSize: 36
    readonly property int avatarGap: 13
    readonly property int metadataSpacing: 3
    readonly property int bubbleHorizontalPadding: 12
    readonly property int bubbleVerticalPadding: 10
    readonly property real contentLeftInset: bubble.avatarSize + bubble.avatarGap
    readonly property real contentWidth: Math.max(0, bubble.width - bubble.contentLeftInset)
    readonly property real messageMaxWidth: Math.min(bubble.contentWidth, bubble.width * 0.72)

    readonly property string fullTimeLabel: {
        const d = new Date(bubble.createdAt);
        if (isNaN(d.getTime()))
            return bubble.timeLabel;

        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const msgStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const daysDiff = Math.round((todayStart - msgStart) / 86400000);

        if (daysDiff === 0)
            return "Today at " + bubble.timeLabel;
        if (daysDiff === 1)
            return "Yesterday at " + bubble.timeLabel;

        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return months[d.getMonth()] + " " + d.getDate() + " at " + bubble.timeLabel;
    }

    implicitHeight: Math.max(contentColumn.implicitHeight, bubble.showSenderInfo ? bubble.avatarSize : 0) + 6

    // Hover detection for the whole row (used to reveal timestamp on consecutive messages)
    HoverHandler {
        id: rowHover
    }

    DmConversationAvatar {
        visible: bubble.showSenderInfo
        x: 0
        y: 0
        name: bubble.senderUsername
        avatarSize: bubble.avatarSize
    }

    Column {
        id: contentColumn

        x: bubble.contentLeftInset
        width: bubble.contentWidth
        spacing: bubble.metadataSpacing

        // Username + full timestamp — only on first message of a group.
        Row {
            visible: bubble.showSenderInfo
            spacing: 6

            Text {
                text: bubble.senderUsername
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                text: bubble.fullTimeLabel
                color: Theme.textSubtle
                font.pixelSize: 11
            }
        }

        Item {
            width: contentColumn.width
            height: bubbleBackground.height

            Rectangle {
                id: bubbleBackground

                width: Math.max(0, Math.min(messageContent.implicitWidth + bubble.bubbleHorizontalPadding * 2,
                                            bubble.messageMaxWidth))
                height: messageContent.implicitHeight + bubble.bubbleVerticalPadding * 2
                radius: 5
                color: bubble.isSelf ? Theme.accentBlue : Theme.surfaceMid

                TextEdit {
                    id: messageContent

                    x: bubble.bubbleHorizontalPadding
                    y: bubble.bubbleVerticalPadding
                    width: bubbleBackground.width - bubble.bubbleHorizontalPadding * 2
                    text: bubble.body
                    color: bubble.isSelf ? "#ffffff" : Theme.textPrimary
                    font.pixelSize: 14
                    wrapMode: TextEdit.Wrap

                    readOnly: true
                    selectByMouse: true
                    selectByKeyboard: true
                    selectedTextColor: bubble.isSelf ? Theme.accentBlue : "#ffffff"
                    selectionColor: bubble.isSelf ? Qt.rgba(1, 1, 1, 0.35) : Theme.accentBlue
                }
            }

            // Hover-only timestamp for consecutive messages.
            Text {
                visible: !bubble.showSenderInfo
                x: bubbleBackground.width + 8
                anchors.verticalCenter: bubbleBackground.verticalCenter
                opacity: rowHover.hovered ? 1.0 : 0.0
                text: bubble.timeLabel
                color: Theme.textSubtle
                font.pixelSize: 11

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }
        }
    }
}

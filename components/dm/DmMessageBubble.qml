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
    required property int selectionIndex
    required property bool groupedWithNewerMessage
    required property Item selectionSourceItem
    required property var selectionController

    // False for consecutive messages from the same sender
    property bool showSenderInfo: true

    readonly property int avatarSize: 40
    readonly property int avatarGap: 15
    readonly property int metadataSpacing: 3
    readonly property int rowHorizontalPadding: 16
    readonly property int bubbleHorizontalPadding: 0
    readonly property int bubbleVerticalPadding: 4
    readonly property int messageVerticalPadding: 4
    readonly property real contentWidth: Math.max(0,
                                                  bubble.width - bubble.rowHorizontalPadding * 2
                                                  - bubble.avatarSize - bubble.avatarGap)
    readonly property real messageMaxWidth: Math.min(bubble.contentWidth, bubble.width * 0.72)
    readonly property real rowContentHeight: Math.max(contentColumn.implicitHeight,
                                                      bubble.showSenderInfo ? bubble.avatarSize : 0)
    readonly property int bottomSpacing: bubble.groupedWithNewerMessage ? 0 : 15

    function cursorPositionFromSourcePoint(sourceX, sourceY) {
        const mappedPoint = messageContent.mapFromItem(bubble.selectionSourceItem, sourceX, sourceY);
        const clampedX = Math.max(0, Math.min(mappedPoint.x, messageContent.width));
        const clampedY = Math.max(0, Math.min(mappedPoint.y, messageContent.height));
        return messageContent.positionAt(clampedX, clampedY);
    }

    function applySelectionRange(active, startPosition, endPosition) {
        if (!active) {
            messageContent.deselect();
            return;
        }

        const maxPosition = messageContent.length;
        const rangeStart = Math.max(0, Math.min(startPosition, maxPosition));
        const rangeEnd = endPosition < 0
                ? maxPosition
                : Math.max(0, Math.min(endPosition, maxPosition));

        if (rangeStart === rangeEnd) {
            messageContent.deselect();
            return;
        }

        messageContent.select(Math.min(rangeStart, rangeEnd), Math.max(rangeStart, rangeEnd));
    }

    Component.onCompleted: bubble.selectionController.registerSelectionBubble(bubble)
    Component.onDestruction: bubble.selectionController.unregisterSelectionBubble(bubble)

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

    implicitHeight: bubble.rowContentHeight + bubble.bubbleVerticalPadding * 2 + bubble.bottomSpacing

    // Hover detection for the whole row (used to reveal timestamp on consecutive messages)
    HoverHandler {
        id: rowHover
    }

    Rectangle {
        width: bubble.width
        height: bubble.rowContentHeight + bubble.bubbleVerticalPadding * 2
        radius: 8
        color: Theme.surfaceHover
        opacity: rowHover.hovered ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 50 }
        }
    }

    Row {
        x: bubble.rowHorizontalPadding
        y: bubble.bubbleVerticalPadding
        width: Math.max(0, bubble.width - bubble.rowHorizontalPadding * 2)
        spacing: bubble.avatarGap

        DmConversationAvatar {
            anchors.verticalCenter: parent.verticalCenter
            opacity: bubble.showSenderInfo ? 1.0 : 0.0
            height: bubble.showSenderInfo ? bubble.avatarSize : 1
            name: bubble.senderUsername
            avatarSize: bubble.avatarSize
        }

        Column {
            id: contentColumn
            anchors.verticalCenter: parent.verticalCenter

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
                    font.family: "Open Sans"
                }

                Text {
                    text: bubble.fullTimeLabel
                    color: Theme.textSubtle
                    font.pixelSize: 11
                    font.family: "Open Sans"
                }
            }

            Row {
                spacing: 5

                Rectangle {
                    id: bubbleBackground

                    width: Math.max(0, Math.min(messageContent.implicitWidth + bubble.bubbleHorizontalPadding * 2,
                                                bubble.messageMaxWidth))
                    height: messageContent.implicitHeight + bubble.messageVerticalPadding * 2
                    color: "transparent"

                    TextEdit {
                        id: messageContent

                        anchors {
                            fill: parent
                            leftMargin: bubble.bubbleHorizontalPadding
                            rightMargin: bubble.bubbleHorizontalPadding
                            topMargin: bubble.messageVerticalPadding
                            bottomMargin: bubble.messageVerticalPadding
                        }

                        text: bubble.body
                        color: bubble.isSelf ? "#ffffff" : Theme.textPrimary
                        font.pixelSize: 14
                        font.family: "Open Sans"
                        wrapMode: TextEdit.Wrap

                        readOnly: true
                        selectByMouse: false
                        selectByKeyboard: true
                    }

                    MouseArea {
                        id: selectionArea

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.IBeamCursor
                        preventStealing: true

                        onPressed: mouse => {
                            const sourcePoint = selectionArea.mapToItem(bubble.selectionSourceItem, mouse.x, mouse.y);
                            bubble.selectionController.beginTextSelection(bubble, sourcePoint.x, sourcePoint.y);
                            mouse.accepted = true;
                        }

                        onPositionChanged: mouse => {
                            if (!(mouse.buttons & Qt.LeftButton))
                                return;

                            const sourcePoint = selectionArea.mapToItem(bubble.selectionSourceItem, mouse.x, mouse.y);
                            bubble.selectionController.updateTextSelection(sourcePoint.x, sourcePoint.y);
                        }

                        onReleased: bubble.selectionController.finishTextSelection()
                        onCanceled: bubble.selectionController.finishTextSelection()
                    }
                }

                // Hover-only timestamp for consecutive messages.
                Text {
                    id: hoverTime

                    visible: !bubble.showSenderInfo
                    anchors.verticalCenter: parent.verticalCenter
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
}

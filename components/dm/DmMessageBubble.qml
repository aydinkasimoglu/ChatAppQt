pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."
import "../.."

Item {
    id: bubble

    required property string body
    required property bool isSelf
    required property string timeLabel

    implicitHeight: messageRow.implicitHeight + 6

    RowLayout {
        id: messageRow

        width: parent.width
        layoutDirection: Qt.LeftToRight
        spacing: 8

        Rectangle {
            Layout.maximumWidth: messageRow.width * 0.72
            Layout.preferredWidth: messageContent.implicitWidth + 24
            implicitHeight: messageContent.implicitHeight + 16
            radius: 18
            color: bubble.isSelf ? Theme.accentBlue : Theme.surfaceMid

            ColumnLayout {
                id: messageContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 12
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: bubble.body
                    color: bubble.isSelf ? "#ffffff" : Theme.textPrimary
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }

                Text {
                    Layout.alignment: Qt.AlignLeft
                    text: bubble.timeLabel
                    color: bubble.isSelf ? Qt.rgba(1, 1, 1, 0.55) : Theme.textSubtle
                    font.pixelSize: 10
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."
import "../.."

Rectangle {
    id: root

    required property bool canCompose
    required property string conversationTitle

    signal sendRequested(string text)

    property alias text: messageInput.text

    implicitHeight: Math.max(44, inputRow.implicitHeight + 12)
    radius: 8
    color: Theme.surfaceMid
    opacity: root.canCompose ? 1.0 : 0.72

    function clear() {
        messageInput.clear()
    }

    function blurInput() {
        messageInput.focus = false
    }

    function submit() {
        const body = messageInput.text.trim()
        if (body.length === 0 || !root.canCompose)
            return

        root.sendRequested(body)
    }

    RowLayout {
        id: inputRow

        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            readonly property real lineH: messageInput.font.pixelSize * 1.45
            implicitHeight: Math.min(messageInput.contentHeight, lineH * 5)

            Text {
                anchors.fill: parent
                visible: !messageInput.activeFocus && messageInput.length === 0
                text: root.canCompose
                      ? qsTr("Message @%1").arg(root.conversationTitle)
                      : "Select a conversation to start messaging"
                color: Theme.textSubtle
                font: messageInput.font
                verticalAlignment: Text.AlignVCenter
            }

            TextEdit {
                id: messageInput

                anchors.fill: parent
                color: Theme.textPrimary
                font.pixelSize: 14
                selectionColor: "#8a93f7"
                selectedTextColor: Theme.textPrimary
                wrapMode: TextEdit.Wrap
                enabled: root.canCompose
                activeFocusOnTab: true
                clip: true

                Keys.onReturnPressed: (event) => {
                    if (event.modifiers & Qt.ShiftModifier) {
                        event.accepted = false
                    } else {
                        root.submit()
                        event.accepted = true
                    }
                }

                Keys.onEscapePressed: (event) => {
                    root.blurInput()
                }
            }
        }

        Rectangle {
            width: 32
            height: 32
            radius: 8
            opacity: root.canCompose && messageInput.length > 0 ? 1.0 : 0.0
            visible: opacity > 0
            color: sendHover.hovered ? Qt.lighter(Theme.accentBlue, 1.15) : Theme.accentBlue

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Behavior on color {
                ColorAnimation { duration: 100 }
            }

            HoverHandler {
                id: sendHover
            }

            TapHandler {
                onTapped: root.submit()
            }

            Image {
                anchors.centerIn: parent
                source: "/assets/icons/arrow_upward.svg"
                width: 16
                height: 16
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                smooth: true
                mipmap: true
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
        }
    }
}
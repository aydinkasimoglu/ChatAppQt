pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "."
import "../.."

Rectangle {
    id: root

    RectangularShadow {
        anchors.fill: root
        radius: root.radius
        blur: 12
        spread: 0
        color: "#22000000"
    }

    required property bool canCompose
    required property string conversationTitle

    signal sendRequested(string text)

    property alias text: messageInput.text

    implicitHeight: Math.max(44, inputRow.implicitHeight + 12)
    radius: 16
    color: Theme.surfaceRaised
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

        anchors {
            fill: parent
            leftMargin: 22
            rightMargin: 22
        }
        spacing: 6

        RoundButton {
            id: attachButton

            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            flat: true
            padding: 5

            icon.source: "/assets/icons/plus.svg"
            icon.color: "white"

            background: Rectangle {
                color: attachButton.hovered ? Theme.surfaceRaised : "transparent"
                radius: 8
                scale: attachButton.hovered ? 1.08 : 0.45
                transformOrigin: Item.Center

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animMid
                        easing.type: Easing.OutBack
                    }
                }
            }
            
            onClicked: console.log("Attach clicked")

            ToolTip {
                id: attachTooltip
                text: qsTr("Attach")
                delay: 1000
                visible: attachButton.hovered
                padding: 8

                contentItem: Text {
                    text: attachTooltip.text
                    font: attachTooltip.font
                    color: Theme.textSecondary
                }

                background: Rectangle {
                    color: Theme.surfaceDeep
                    border.color: Theme.surfaceBorder
                    border.width: 1
                    radius: 6
                }
            }
        }

        TextField {
            id: messageInput

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            color: Theme.textPrimary

            background: Item {}
            font.pixelSize: 14
            selectionColor: "#8a93f7"
            selectedTextColor: Theme.textPrimary
            wrapMode: TextField.Wrap
            enabled: root.canCompose
            activeFocusOnTab: true
            clip: true

            placeholderText: root.canCompose
                    ? qsTr("Message @%1").arg(root.conversationTitle)
                    : "Select a conversation to start messaging"
            placeholderTextColor: Theme.textSubtle

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

        RoundButton {
            id: sendButton

            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            flat: true
            padding: 5
            enabled: root.canCompose && messageInput.text.trim().length > 0

            icon.source: "/assets/icons/paper_plane.svg"
            icon.color: "white"

            background: Rectangle {
                color: sendButton.hovered && sendButton.enabled ? Theme.surfaceRaised : "transparent"
                radius: 8

                scale: sendButton.hovered ? 1.08 : 0.45
                transformOrigin: Item.Center

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animMid
                        easing.type: Easing.OutBack
                    }
                }
            }

            onClicked: root.submit()

            ToolTip {
                id: sendTooltip
                text: qsTr("Send")
                delay: 1000
                visible: sendButton.hovered
                padding: 8

                contentItem: Text {
                    text: sendTooltip.text
                    font: sendTooltip.font
                    color: Theme.textSecondary
                }

                background: Rectangle {
                    color: Theme.surfaceDeep
                    border.color: Theme.surfaceBorder
                    border.width: 1
                    radius: 6
                }
            }
        }
    }
}
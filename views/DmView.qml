pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

// DmView — direct-message conversation view.

Rectangle {
    id: root

    color: Theme.surfaceRaised

    // ── Public API ────────────────────────────────────────────────────────
    required property string recipientId
    required property string recipientName

    signal messageSent(string text)

    // ── Private helpers ───────────────────────────────────────────────────
    readonly property var _palette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]

    function _avatarColor(name: string): color {
        return _palette[name.charCodeAt(0) % _palette.length]
    }

    function _scrollHistoryToBottom() {
        historyPane.contentY = Math.max(0, historyPane.contentHeight - historyPane.height)
    }

    function _send() {
        const body = messageInput.text.trim()
        if (body.length === 0)
            return
        messageModel.append({
            body:      body,
            isSelf:    true,
            timeLabel: Qt.formatTime(new Date(), "hh:mm")
        })
        messageInput.clear()
        Qt.callLater(root._scrollHistoryToBottom)
        root.messageSent(body)
    }

    // ── State reactions ───────────────────────────────────────────────────
    // Clear content when switching conversations, but never steal focus —
    // the user decides when they want to start typing.
    onRecipientIdChanged: {
        messageModel.clear()
        messageInput.clear()
        messageInput.focus = false
        Qt.callLater(root._scrollHistoryToBottom)
    }

    onVisibleChanged: {
        if (!visible)
            messageInput.focus = false
    }

    // ── Data model ────────────────────────────────────────────────────────
    ListModel { id: messageModel }

    // ── Inline component — message bubble ─────────────────────────────────
    component MessageBubble: Item {
        id: bubble

        required property string body
        required property bool   isSelf
        required property string timeLabel

        implicitHeight: row.implicitHeight + 6

        RowLayout {
            id: row
            width: parent.width
            layoutDirection: Qt.LeftToRight
            spacing: 8

            Rectangle {
                Layout.maximumWidth: row.width * 0.72
                implicitWidth:  content.implicitWidth  + 24
                implicitHeight: content.implicitHeight + 16
                radius: 18
                color: bubble.isSelf ? Theme.accentBlue : Theme.surfaceMid

                ColumnLayout {
                    id: content
                    anchors {
                        left: parent.left;  right:  parent.right
                        top:  parent.top;   bottom: parent.bottom
                        margins: 12
                    }
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text:      bubble.body
                        color:     bubble.isSelf ? "#ffffff" : Theme.textPrimary
                        font.pixelSize: 14
                        wrapMode:  Text.Wrap
                    }

                    Text {
                        Layout.alignment: Qt.AlignLeft
                        text:  bubble.timeLabel
                        color: bubble.isSelf ? Qt.rgba(1, 1, 1, 0.55) : Theme.textSubtle
                        font.pixelSize: 10
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top bar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredHeight: 48
            color: "transparent"

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color:  Theme.surfaceBorder
            }

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  16
                    rightMargin: 16
                }
                spacing: 10

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: root._avatarColor(root.recipientName)

                    Text {
                        anchors.centerIn: parent
                        text:  root.recipientName.charAt(0).toUpperCase()
                        color: "#ffffff"
                        font { pixelSize: 13; weight: Font.DemiBold }
                    }
                }

                Text {
                    text:  root.recipientName
                    color: Theme.textPrimary
                    font { pixelSize: 15; weight: Font.DemiBold }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ── Message history ───────────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: historyPane

                anchors.fill: parent
                contentWidth: width
                contentHeight: Math.max(height, historyStack.implicitHeight + historyPane.bottomPadding)
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                clip: true

                readonly property real sidePadding:   16
                readonly property real bottomPadding:  8

                Column {
                    id: historyStack

                    x: historyPane.sidePadding
                    y: historyPane.contentHeight - implicitHeight - historyPane.bottomPadding
                    width: Math.max(0, historyPane.width - historyPane.sidePadding * 2)
                    spacing: messageModel.count > 0 ? 16 : 0

                    ColumnLayout {
                        id: introBlock

                        width:   parent.width
                        spacing: 8

                        Rectangle {
                            width: 72; height: 72; radius: 36
                            color: root._avatarColor(root.recipientName)

                            Text {
                                anchors.centerIn: parent
                                text:  root.recipientName.charAt(0).toUpperCase()
                                color: "#ffffff"
                                font { pixelSize: 28; weight: Font.DemiBold }
                            }
                        }

                        Text {
                            text:  root.recipientName
                            color: Theme.textPrimary
                            font { pixelSize: 22; weight: Font.DemiBold }
                        }

                        Text {
                            text: qsTr("This is the beginning of your direct message history with <b>%1</b>.").arg(root.recipientName)
                            color:      Theme.textMuted
                            font.pixelSize: 14
                            textFormat: Text.StyledText
                        }
                    }

                    ListView {
                        id: messageList

                        width: parent.width
                        height: messageModel.count > 0 ? contentHeight : 0
                        interactive: false
                        model:   messageModel
                        spacing: 4
                        clip:    true
                        visible: messageModel.count > 0

                        onCountChanged: Qt.callLater(root._scrollHistoryToBottom)

                        delegate: MessageBubble {
                            width: ListView.view ? ListView.view.width : 0
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: historyPane.contentHeight > historyPane.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }

        // ── Input bar ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth:    true
            Layout.leftMargin:   16
            Layout.rightMargin:  16
            Layout.bottomMargin: 24
            implicitHeight: Math.max(44, inputRow.implicitHeight + 12)
            radius: 8
            color:  Theme.surfaceMid

            RowLayout {
                id: inputRow
                anchors {
                    fill:         parent
                    leftMargin:   16
                    rightMargin:  8
                    topMargin:    6
                    bottomMargin: 6
                }
                spacing: 8

                // Wrapper Item owns the height cap and hosts the placeholder.
                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real lineH: messageInput.font.pixelSize * 1.45
                    implicitHeight: Math.min(messageInput.contentHeight, lineH * 5)

                    // Placeholder — only visible when unfocused and empty
                    Text {
                        anchors.fill:          parent
                        visible:               !messageInput.activeFocus && messageInput.length === 0
                        text:                  qsTr("Message @%1").arg(root.recipientName)
                        color:                 Theme.textSubtle
                        font:                  messageInput.font
                        verticalAlignment:     Text.AlignVCenter
                    }

                    TextEdit {
                        id: messageInput
                        anchors.fill: parent

                        color:             Theme.textPrimary
                        font.pixelSize:    14
                        selectionColor:    "#8a93f7"
                        selectedTextColor: Theme.textPrimary
                        wrapMode:          TextEdit.Wrap
                        activeFocusOnTab:  true
                        clip:              true
                        // No `focus: true` — input is idle until the user clicks it

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false
                            } else {
                                root._send()
                                event.accepted = true
                            }
                        }

                        Keys.onEscapePressed: (event) => {
                            messageInput.focus = false
                        }
                    }
                }

                // Send button — fades in when there is text
                Rectangle {
                    width: 32; height: 32; radius: 8

                    opacity: messageInput.length > 0 ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    color: sendHover.hovered ? Qt.lighter(Theme.accentBlue, 1.15) : Theme.accentBlue
                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: sendHover }
                    TapHandler   { onTapped: root._send() }

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
    }
}

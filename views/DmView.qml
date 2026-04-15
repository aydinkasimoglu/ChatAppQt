pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

Rectangle {
    id: dmViewRoot

    color: Theme.surfaceRaised

    required property string conversationId
    required property string conversationTitle

    signal messageSent(string text)

    readonly property var _palette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]
    readonly property bool hasConversation: conversationTitle.length > 0 || conversationId.length > 0
    readonly property bool canCompose: conversationId.length > 0
    property bool autoScrollPending: false

    function _avatarColor(name) {
        if (!name || name.length === 0)
            return _palette[0]
        return _palette[name.charCodeAt(0) % _palette.length]
    }

    function _scrollHistoryToBottom() {
        historyPane.contentY = Math.max(0, historyPane.contentHeight - historyPane.height)
    }

    function _scrollHistoryToBottomAndAcknowledge() {
        dmViewRoot._scrollHistoryToBottom()
        Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
    }

    function _maybeAcknowledgeVisibleMessages() {
        if (!dmViewRoot.visible
                || !DmManager.currentConversationReadActive
                || dmViewRoot.conversationId.length === 0
                || !historyPane.atBottom) {
            return
        }

        DmManager.acknowledgeCurrentConversationMessages()
    }

    function _send() {
        const body = messageInput.text.trim()
        if (body.length === 0 || !canCompose)
            return

        dmViewRoot.autoScrollPending = historyPane.atBottom || DmManager.messages.count === 0
        DmManager.sendMessage(body)
        dmViewRoot.messageSent(body)
    }

    onConversationIdChanged: {
        dmViewRoot.autoScrollPending = true
        messageInput.clear()
        messageInput.focus = false
    }

    onVisibleChanged: {
        if (!visible)
            messageInput.focus = false

        Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
    }

    Connections {
        target: DmManager

        function onMessageSent() {
            if (!dmViewRoot.visible)
                return

            messageInput.clear()
        }

        function onCurrentConversationReadActiveChanged() {
            Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
        }

        function onMessagesLoadingChanged() {
            if (!DmManager.messagesLoading && dmViewRoot.autoScrollPending && DmManager.messages.count === 0)
                dmViewRoot.autoScrollPending = false
        }
    }

    Connections {
        target: DmManager.messages

        function onRowsAboutToBeInserted(parent, first, last) {
            if (dmViewRoot.visible && historyPane.atBottom)
                dmViewRoot.autoScrollPending = true
        }
    }

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

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
                    color: dmViewRoot._avatarColor(dmViewRoot.conversationTitle)

                    Text {
                        anchors.centerIn: parent
                        text:  dmViewRoot.conversationTitle.length > 0
                               ? dmViewRoot.conversationTitle.charAt(0).toUpperCase()
                               : "D"
                        color: "#ffffff"
                        font { pixelSize: 13; weight: Font.DemiBold }
                    }
                }

                Text {
                    text:  dmViewRoot.conversationTitle.length > 0
                           ? dmViewRoot.conversationTitle
                           : "Direct Messages"
                    color: Theme.textPrimary
                    font { pixelSize: 15; weight: Font.DemiBold }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip: true

            Text {
                anchors.centerIn: parent
                visible: !dmViewRoot.hasConversation
                text: "Select a conversation to view your direct message history."
                color: Theme.textMuted
                font.pixelSize: 14
            }

            Flickable {
                id: historyPane

                anchors.fill: parent
                visible: dmViewRoot.hasConversation
                contentWidth: width
                contentHeight: Math.max(height, historyStack.implicitHeight + historyPane.bottomPadding)
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                clip: true

                readonly property real sidePadding:   16
                readonly property real bottomPadding:  8
                readonly property bool atBottom: contentY >= Math.max(0, contentHeight - height - 4)

                onAtBottomChanged: {
                    if (atBottom)
                        Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
                }

                Column {
                    id: historyStack

                    x: historyPane.sidePadding
                    y: historyPane.contentHeight - implicitHeight - historyPane.bottomPadding
                    width: Math.max(0, historyPane.width - historyPane.sidePadding * 2)
                    spacing: DmManager.messages.count > 0 ? 16 : 0

                    ColumnLayout {
                        id: introBlock

                        width:   parent.width
                        spacing: 8

                        Rectangle {
                            width: 72; height: 72; radius: 36
                            color: dmViewRoot._avatarColor(dmViewRoot.conversationTitle)

                            Text {
                                anchors.centerIn: parent
                                text:  dmViewRoot.conversationTitle.charAt(0).toUpperCase()
                                color: "#ffffff"
                                font { pixelSize: 28; weight: Font.DemiBold }
                            }
                        }

                        Text {
                            text:  dmViewRoot.conversationTitle
                            color: Theme.textPrimary
                            font { pixelSize: 22; weight: Font.DemiBold }
                        }

                        Text {
                                    text: DmManager.openingConversation && !dmViewRoot.conversationId.length
                                  ? qsTr("Starting a direct message with <b>%1</b>...").arg(dmViewRoot.conversationTitle)
                                        : (DmManager.messagesLoading && DmManager.messages.count === 0
                                     ? qsTr("Loading your direct message history with <b>%1</b>...").arg(dmViewRoot.conversationTitle)
                                     : qsTr("This is the beginning of your direct message history with <b>%1</b>.").arg(dmViewRoot.conversationTitle))
                            color:      Theme.textMuted
                            font.pixelSize: 14
                            textFormat: Text.StyledText
                        }
                    }

                    ListView {
                        id: messageList

                        width: parent.width
                        height: DmManager.messages.count > 0 ? contentHeight : 0
                        interactive: false
                        model:   DmManager.messages
                        spacing: 4
                        clip:    true
                        visible: DmManager.messages.count > 0

                        onCountChanged: {
                            if (DmManager.messages.count > 0 && dmViewRoot.autoScrollPending) {
                                dmViewRoot.autoScrollPending = false
                                Qt.callLater(dmViewRoot._scrollHistoryToBottomAndAcknowledge)
                            }
                        }

                        delegate: MessageBubble {
                            width: ListView.view ? ListView.view.width : 0
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: DmManager.messagesLoading && DmManager.messages.count === 0 && dmViewRoot.conversationId.length > 0
                    text: "Loading messages..."
                    color: Theme.textMuted
                    font.pixelSize: 13
                }

                ScrollBar.vertical: ScrollBar {
                    policy: historyPane.contentHeight > historyPane.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }

        Rectangle {
            Layout.fillWidth:    true
            Layout.leftMargin:   16
            Layout.rightMargin:  16
            Layout.bottomMargin: 24
            implicitHeight: Math.max(44, inputRow.implicitHeight + 12)
            radius: 8
            color:  Theme.surfaceMid
            opacity: dmViewRoot.canCompose ? 1.0 : 0.72

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

                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real lineH: messageInput.font.pixelSize * 1.45
                    implicitHeight: Math.min(messageInput.contentHeight, lineH * 5)

                    Text {
                        anchors.fill:          parent
                        visible:               !messageInput.activeFocus && messageInput.length === 0
                        text:                  dmViewRoot.canCompose
                                               ? qsTr("Message @%1").arg(dmViewRoot.conversationTitle)
                                               : "Select a conversation to start messaging"
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
                        enabled:           dmViewRoot.canCompose
                        activeFocusOnTab:  true
                        clip:              true

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false
                            } else {
                                dmViewRoot._send()
                                event.accepted = true
                            }
                        }

                        Keys.onEscapePressed: (event) => {
                            messageInput.focus = false
                        }
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 8

                    opacity: dmViewRoot.canCompose && messageInput.length > 0 ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    color: sendHover.hovered ? Qt.lighter(Theme.accentBlue, 1.15) : Theme.accentBlue
                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: sendHover }
                    TapHandler   { onTapped: dmViewRoot._send() }

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

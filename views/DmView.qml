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
    readonly property real olderMessagesPrefetchDistance: 400
    property bool autoScrollPending: false
    property bool initialBottomScrollPending: false
    property bool ownSendPending: false
    property bool prependActive: false
    property real prependBaseContentY: 0
    property real prependBaseContentHeight: 0

    function _avatarColor(name) {
        if (!name || name.length === 0)
            return _palette[0]
        return _palette[name.charCodeAt(0) % _palette.length]
    }

    function _clearPrependState() {
        dmViewRoot.prependActive = false
        dmViewRoot.prependBaseContentY = 0
        dmViewRoot.prependBaseContentHeight = 0
    }

    function _distanceFromTop() {
        return historyList.contentY + historyList.topMargin
    }

    function _distanceFromBottom() {
        return Math.max(0, historyList.contentHeight - historyList.height - historyList.contentY)
    }

    function _scrollHistoryToBottom() {
        if (DmManager.messages.count === 0)
            return

        scrollToBottomAnim.stop()
        historyList.forceLayout()
        historyList.positionViewAtIndex(DmManager.messages.count - 1, ListView.End)
    }

    function _smoothScrollToBottom() {
        if (DmManager.messages.count === 0)
            return

        historyList.forceLayout()
        const dist = dmViewRoot._distanceFromBottom()
        if (dist < 1) {
            dmViewRoot.autoScrollPending = false
            Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
            return
        }

        if (dist > 600) {
            historyList.positionViewAtIndex(DmManager.messages.count - 1, ListView.End)
            dmViewRoot.autoScrollPending = false
            Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
            return
        }

        scrollToBottomAnim.stop()
        scrollToBottomAnim.from = historyList.contentY
        scrollToBottomAnim.to = historyList.contentY + dist
        scrollToBottomAnim.duration = Math.min(300, Math.max(120, dist * 0.4))
        scrollToBottomAnim.start()
    }

    function _armOpenToLatest() {
        dmViewRoot.autoScrollPending = true
        dmViewRoot.initialBottomScrollPending = true
        Qt.callLater(dmViewRoot._flushPendingAutoScroll)
    }

    function _flushPendingAutoScroll() {
        if (!dmViewRoot.autoScrollPending
                || !dmViewRoot.visible
                || DmManager.messages.count === 0) {
            return
        }

        if (dmViewRoot.initialBottomScrollPending || dmViewRoot.ownSendPending) {
            dmViewRoot._scrollHistoryToBottom()
            dmViewRoot.autoScrollPending = false
            dmViewRoot.initialBottomScrollPending = false
            dmViewRoot.ownSendPending = false
            Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
        } else {
            dmViewRoot.initialBottomScrollPending = false
            dmViewRoot._smoothScrollToBottom()
        }
    }

    function _requestOlderMessagesIfNeeded() {
        if (!dmViewRoot.visible
                || dmViewRoot.conversationId.length === 0
                || DmManager.messages.count === 0
                || DmManager.messagesLoading
                || DmManager.loadingOlderMessages
                || DmManager.historyStartReached
                || dmViewRoot.autoScrollPending
                || dmViewRoot.initialBottomScrollPending
                || dmViewRoot.prependActive
                || dmViewRoot._distanceFromTop() > dmViewRoot.olderMessagesPrefetchDistance) {
            return
        }

        dmViewRoot.prependActive = true
        dmViewRoot.prependBaseContentY = historyList.contentY
        dmViewRoot.prependBaseContentHeight = historyList.contentHeight
        DmManager.loadOlderMessages()
    }

    function _maybeAcknowledgeVisibleMessages() {
        if (!dmViewRoot.visible
                || !DmManager.currentConversationReadActive
                || dmViewRoot.conversationId.length === 0
                || !historyList.atBottom) {
            return
        }

        DmManager.acknowledgeCurrentConversationMessages()
    }

    function _send() {
        const body = messageInput.text.trim()
        if (body.length === 0 || !canCompose)
            return

        dmViewRoot.autoScrollPending = true
        dmViewRoot.ownSendPending = true
        DmManager.sendMessage(body)
        dmViewRoot.messageSent(body)
    }

    onConversationIdChanged: {
        scrollToBottomAnim.stop()
        dmViewRoot.initialBottomScrollPending = true
        dmViewRoot._clearPrependState()
        messageInput.clear()
        messageInput.focus = false
        dmViewRoot._armOpenToLatest()
    }

    onVisibleChanged: {
        if (!visible)
            messageInput.focus = false

        if (visible && dmViewRoot.hasConversation) {
            dmViewRoot._armOpenToLatest()
        }

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

        function onLoadingOlderMessagesChanged() {
            if (!DmManager.loadingOlderMessages && dmViewRoot.prependActive) {
                Qt.callLater(function() {
                    historyList.forceLayout()
                    dmViewRoot._clearPrependState()
                })
            }
        }
    }

    Connections {
        target: DmManager.messages

        function onCountChanged() {
            if (dmViewRoot.autoScrollPending)
                Qt.callLater(dmViewRoot._flushPendingAutoScroll)
        }

        function onRowsAboutToBeInserted(parent, first, last) {
            if (first > 0 && dmViewRoot.visible && historyList.atBottom)
                dmViewRoot.autoScrollPending = true
        }
    }

    Component {
        id: introHeaderComponent

        Item {
            width: historyList.width
            implicitHeight: introColumn.implicitHeight

            ColumnLayout {
                id: introColumn

                x: historyList.sidePadding
                width: Math.max(0, parent.width - historyList.sidePadding * 2)
                spacing: 8

                Rectangle {
                    width: 72; height: 72; radius: 36
                    color: dmViewRoot._avatarColor(dmViewRoot.conversationTitle)

                    Text {
                        anchors.centerIn: parent
                        text: dmViewRoot.conversationTitle.charAt(0).toUpperCase()
                        color: "#ffffff"
                        font { pixelSize: 28; weight: Font.DemiBold }
                    }
                }

                Text {
                    text: dmViewRoot.conversationTitle
                    color: Theme.textPrimary
                    font { pixelSize: 22; weight: Font.DemiBold }
                }

                Text {
                    text: DmManager.messagesLoading && DmManager.messages.count === 0
                          ? qsTr("Loading your direct message history with <b>%1</b>...").arg(dmViewRoot.conversationTitle)
                          : qsTr("This is the beginning of your direct message history with <b>%1</b>.").arg(dmViewRoot.conversationTitle)
                    color: Theme.textMuted
                    font.pixelSize: 14
                    textFormat: Text.StyledText
                }
            }
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

            ListView {
                id: historyList

                anchors.fill: parent
                visible: dmViewRoot.hasConversation
                model: DmManager.messages
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                reuseItems: true
                cacheBuffer: 2000
                pixelAligned: true
                flickDeceleration: 1500
                maximumFlickVelocity: 4000

                readonly property real sidePadding: 16
                readonly property real bottomPadding: 8
                readonly property bool atBottom: dmViewRoot._distanceFromBottom() <= 16

                topMargin: Math.max(0, height - contentHeight)
                footer: Item {
                    width: historyList.width
                    height: historyList.bottomPadding
                }
                header: DmManager.historyStartReached && dmViewRoot.hasConversation ? introHeaderComponent : null

                NumberAnimation {
                    id: scrollToBottomAnim
                    target: historyList
                    property: "contentY"
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && dmViewRoot.autoScrollPending) {
                            dmViewRoot.autoScrollPending = false
                            Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
                        }
                    }
                }

                onMovementStarted: scrollToBottomAnim.stop()

                onAtBottomChanged: {
                    if (atBottom)
                        Qt.callLater(dmViewRoot._maybeAcknowledgeVisibleMessages)
                }

                onContentYChanged: {
                    if (!dmViewRoot.prependActive
                            && !scrollToBottomAnim.running
                            && dmViewRoot._distanceFromTop() <= dmViewRoot.olderMessagesPrefetchDistance) {
                        Qt.callLater(dmViewRoot._requestOlderMessagesIfNeeded)
                    }
                }

                onContentHeightChanged: {
                    if (dmViewRoot.prependActive) {
                        if (dmViewRoot.prependBaseContentHeight >= historyList.height) {
                            const delta = historyList.contentHeight - dmViewRoot.prependBaseContentHeight
                            historyList.contentY = dmViewRoot.prependBaseContentY + delta
                            dmViewRoot.prependBaseContentHeight = historyList.contentHeight
                            dmViewRoot.prependBaseContentY = historyList.contentY
                        } else if (historyList.contentHeight > historyList.height) {
                            dmViewRoot.autoScrollPending = true
                            Qt.callLater(dmViewRoot._flushPendingAutoScroll)
                        }
                    } else if (dmViewRoot.autoScrollPending) {
                        Qt.callLater(dmViewRoot._flushPendingAutoScroll)
                    }
                }

                delegate: MessageBubble {
                    required property string messageId

                    x: historyList.sidePadding
                    width: historyList.width - historyList.sidePadding * 2
                }

                ScrollBar.vertical: ScrollBar {
                    policy: historyList.contentHeight > historyList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }

            Rectangle {
                anchors.horizontalCenter: historyList.horizontalCenter
                anchors.top: historyList.top
                anchors.topMargin: 10
                visible: dmViewRoot.hasConversation && DmManager.loadingOlderMessages && DmManager.messages.count > 0
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.18)
                implicitWidth: loadingOlderLabel.implicitWidth + 20
                implicitHeight: loadingOlderLabel.implicitHeight + 10

                Text {
                    id: loadingOlderLabel

                    anchors.centerIn: parent
                    text: "Loading older messages..."
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            Text {
                anchors.centerIn: parent
                visible: DmManager.messagesLoading && DmManager.messages.count === 0 && dmViewRoot.conversationId.length > 0
                text: "Loading messages..."
                color: Theme.textMuted
                font.pixelSize: 13
            }

            Rectangle {
                id: scrollToBottomBtn

                anchors.horizontalCenter: historyList.horizontalCenter
                anchors.bottom: historyList.bottom
                anchors.bottomMargin: 16
                width: 36; height: 36; radius: 18
                color: scrollToBottomHover.hovered ? Qt.lighter(Theme.surfaceMid, 1.3) : Theme.surfaceMid
                border.width: 1
                border.color: Theme.surfaceBorder
                visible: dmViewRoot.hasConversation
                         && !historyList.atBottom
                         && !dmViewRoot.autoScrollPending
                         && DmManager.messages.count > 0
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 100 } }

                HoverHandler { id: scrollToBottomHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        dmViewRoot.autoScrollPending = true
                        dmViewRoot.ownSendPending = true
                        Qt.callLater(dmViewRoot._flushPendingAutoScroll)
                    }
                }

                Image {
                    anchors.centerIn: parent
                    source: "/assets/icons/arrow_upward.svg"
                    rotation: 180
                    width: 16; height: 16
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                    smooth: true; mipmap: true
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

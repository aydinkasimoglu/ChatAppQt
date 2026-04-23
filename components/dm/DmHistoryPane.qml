pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import "."
import "../.."

Item {
    id: historyPane

    required property string conversationId
    required property string conversationTitle
    required property bool hasConversation
    required property bool viewVisible

    readonly property real olderMessagesPrefetchDistance: 800
    property bool autoScrollPending: false
    property bool initialBottomScrollPending: false
    property bool ownSendPending: false

    clip: true

    function _distanceFromTop() {
        return Math.max(0, historyList.contentY - historyList.originY)
    }

    function _distanceFromBottom() {
        return Math.max(0, historyList.contentHeight - historyList.height - historyList.contentY)
    }

    function _scrollHistoryToBottom() {
        if (DmManager.messages.count === 0)
            return

        historyList.forceLayout()
        historyList.positionViewAtBeginning()
    }

    function armOpenToLatest() {
        historyPane.autoScrollPending = true
        historyPane.initialBottomScrollPending = true
        Qt.callLater(historyPane._flushPendingAutoScroll)
    }

    function prepareOwnSend() {
        historyPane.autoScrollPending = true
        historyPane.ownSendPending = true
    }

    function resetForConversationChange() {
        historyPane.initialBottomScrollPending = true
    }

    function scheduleAcknowledgeVisibleMessages() {
        Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
    }

    function _flushPendingAutoScroll() {
        if (!historyPane.autoScrollPending
                || !historyPane.viewVisible
                || DmManager.messages.count === 0) {
            return
        }

        historyPane._scrollHistoryToBottom()
        historyPane.autoScrollPending = false
        historyPane.initialBottomScrollPending = false
        historyPane.ownSendPending = false
        Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
        Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
    }

    function _requestOlderMessagesIfNeeded() {
        if (!historyPane.viewVisible
                || historyPane.conversationId.length === 0
                || DmManager.messages.count === 0
                || DmManager.messagesLoading
                || DmManager.loadingOlderMessages
                || DmManager.historyStartReached
                || historyPane.autoScrollPending
                || historyPane.initialBottomScrollPending
                || historyPane._distanceFromTop() > historyPane.olderMessagesPrefetchDistance) {
            return
        }

        DmManager.loadOlderMessages()
    }

    function _maybeAcknowledgeVisibleMessages() {
        if (!historyPane.viewVisible
                || !DmManager.currentConversationReadActive
                || historyPane.conversationId.length === 0
                || !historyList.atBottom) {
            return
        }

        DmManager.acknowledgeCurrentConversationMessages()
    }

    Connections {
        target: DmManager

        function onCurrentConversationReadActiveChanged() {
            Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
        }

        function onLoadingOlderMessagesChanged() {
            if (!DmManager.loadingOlderMessages)
                Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
        }
    }

    Connections {
        target: DmManager.messages

        function onCountChanged() {
            if (historyPane.autoScrollPending)
                Qt.callLater(historyPane._flushPendingAutoScroll)
        }

        function onRowsAboutToBeInserted(parent, first, last) {
            if (first === 0 && historyPane.viewVisible && historyList.atBottom)
                historyPane.autoScrollPending = true
        }
    }

    Component {
        id: introFooterComponent

        DmHistoryIntro {
            width: historyList.width
            conversationTitle: historyPane.conversationTitle
            sidePadding: historyList.sidePadding
            loading: DmManager.messagesLoading && DmManager.messages.count === 0
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !historyPane.hasConversation
        text: "Select a conversation to view your direct message history."
        color: Theme.textMuted
        font.pixelSize: 14
    }

    ListView {
        id: historyList

        anchors.fill: parent
        visible: historyPane.hasConversation
        model: DmManager.messages
        spacing: 4
        leftMargin: 15
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        verticalLayoutDirection: ListView.BottomToTop
        reuseItems: true
        cacheBuffer: 1500
        displayMarginBeginning: 400
        displayMarginEnd: 400
        pixelAligned: true
        flickDeceleration: 1500
        maximumFlickVelocity: 4000

        readonly property real sidePadding: 16
        readonly property real bottomPadding: 8
        property bool atBottom: false

        header: Item {
            width: historyList.width
            height: historyList.bottomPadding
        }

        footer: historyPane.hasConversation ? historyFooterComponent : null

        Component {
            id: historyFooterComponent

            Item {
                width: historyList.width
                implicitHeight: footerColumn.implicitHeight

                Column {
                    id: footerColumn

                    width: parent.width
                    spacing: 10

                    Item {
                        width: parent.width
                        height: DmManager.loadingOlderMessages && DmManager.messages.count > 0 ? 60 : 0

                        BusyIndicator {
                            anchors.centerIn: parent
                            visible: parent.height > 0
                            running: visible
                        }
                    }

                    Loader {
                        width: parent.width
                        active: DmManager.historyStartReached
                        sourceComponent: introFooterComponent
                    }
                }
            }
        }

        onAtBottomChanged: {
            if (atBottom)
                Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
        }

        onContentYChanged: {
            historyList.atBottom = historyPane._distanceFromBottom() <= 16
            if (historyPane._distanceFromTop() <= historyPane.olderMessagesPrefetchDistance) {
                Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
            }
        }

        onContentHeightChanged: {
            historyList.atBottom = historyPane._distanceFromBottom() <= 16
            if (historyPane.autoScrollPending) {
                Qt.callLater(historyPane._flushPendingAutoScroll)
            } else if (historyPane._distanceFromTop() <= historyPane.olderMessagesPrefetchDistance) {
                Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
            }
        }

        delegate: DmMessageBubble {
            required property int index
            required property string messageId
            readonly property int messageCount: DmManager.messages.count

            x: historyList.sidePadding
            width: historyList.width - historyList.sidePadding * 2
            showSenderInfo: messageCount >= 0 && DmManager.messages.shouldShowSenderInfo(index)
        }

        ScrollBar.vertical: ScrollBar {
            policy: historyList.contentHeight > historyList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }
    }

    Text {
        anchors.centerIn: parent
        visible: DmManager.messagesLoading && DmManager.messages.count === 0 && historyPane.conversationId.length > 0
        text: "Loading messages..."
        color: Theme.textMuted
        font.pixelSize: 13
    }
}
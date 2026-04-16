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

    readonly property real olderMessagesPrefetchDistance: 400
    property bool autoScrollPending: false
    property bool initialBottomScrollPending: false
    property bool ownSendPending: false
    property bool prependActive: false
    property real prependBaseContentY: 0
    property real prependBaseContentHeight: 0

    clip: true

    function _clearPrependState() {
        historyPane.prependActive = false
        historyPane.prependBaseContentY = 0
        historyPane.prependBaseContentHeight = 0
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
        historyList.contentY = historyList.contentHeight - historyList.height
    }

    function _smoothScrollToBottom() {
        if (DmManager.messages.count === 0)
            return

        historyList.forceLayout()
        const dist = historyPane._distanceFromBottom()
        if (dist < 1) {
            historyPane.autoScrollPending = false
            Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
            return
        }

        if (dist > 600) {
            historyList.positionViewAtIndex(DmManager.messages.count - 1, ListView.End)
            historyPane.autoScrollPending = false
            Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
            return
        }

        scrollToBottomAnim.stop()
        scrollToBottomAnim.from = historyList.contentY
        scrollToBottomAnim.to = historyList.contentY + dist
        scrollToBottomAnim.duration = Math.min(300, Math.max(120, dist * 0.4))
        scrollToBottomAnim.start()
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
        scrollToBottomAnim.stop()
        historyPane.initialBottomScrollPending = true
        historyPane._clearPrependState()
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

        if (historyPane.initialBottomScrollPending || historyPane.ownSendPending) {
            historyPane._scrollHistoryToBottom()
            historyPane.autoScrollPending = false
            historyPane.initialBottomScrollPending = false
            historyPane.ownSendPending = false
            Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
        } else {
            historyPane.initialBottomScrollPending = false
            historyPane._smoothScrollToBottom()
        }
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
                || historyPane.prependActive
                || historyPane._distanceFromTop() > historyPane.olderMessagesPrefetchDistance) {
            return
        }

        historyPane.prependActive = true
        historyPane.prependBaseContentY = historyList.contentY
        historyPane.prependBaseContentHeight = historyList.contentHeight
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
            if (!DmManager.loadingOlderMessages && historyPane.prependActive) {
                Qt.callLater(function() {
                    historyList.forceLayout()
                    historyPane._clearPrependState()
                })
            }
        }
    }

    Connections {
        target: DmManager.messages

        function onCountChanged() {
            if (historyPane.autoScrollPending)
                Qt.callLater(historyPane._flushPendingAutoScroll)
        }

        function onRowsAboutToBeInserted(parent, first, last) {
            if (first > 0 && historyPane.viewVisible && historyList.atBottom)
                historyPane.autoScrollPending = true
        }
    }

    Component {
        id: introHeaderComponent

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
        readonly property bool atBottom: historyPane._distanceFromBottom() <= 16

        topMargin: Math.max(0, height - contentHeight)

        footer: Item {
            width: historyList.width
            height: historyList.bottomPadding
        }

        header: DmManager.historyStartReached && historyPane.hasConversation ? introHeaderComponent : null

        NumberAnimation {
            id: scrollToBottomAnim

            target: historyList
            property: "contentY"
            easing.type: Easing.OutCubic

            onRunningChanged: {
                if (!running && historyPane.autoScrollPending) {
                    historyPane.autoScrollPending = false
                    Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
                }
            }
        }

        onMovementStarted: scrollToBottomAnim.stop()

        onAtBottomChanged: {
            if (atBottom)
                Qt.callLater(historyPane._maybeAcknowledgeVisibleMessages)
        }

        onContentYChanged: {
            if (!historyPane.prependActive
                    && !scrollToBottomAnim.running
                    && historyPane._distanceFromTop() <= historyPane.olderMessagesPrefetchDistance) {
                Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
            }
        }

        onContentHeightChanged: {
            if (historyPane.prependActive) {
                if (historyPane.prependBaseContentHeight >= historyList.height) {
                    const delta = historyList.contentHeight - historyPane.prependBaseContentHeight
                    historyList.contentY = historyPane.prependBaseContentY + delta
                    historyPane.prependBaseContentHeight = historyList.contentHeight
                    historyPane.prependBaseContentY = historyList.contentY
                } else if (historyList.contentHeight > historyList.height) {
                    historyPane.autoScrollPending = true
                    Qt.callLater(historyPane._flushPendingAutoScroll)
                }
            } else if (historyPane.autoScrollPending) {
                Qt.callLater(historyPane._flushPendingAutoScroll)
            }
        }

        delegate: DmMessageBubble {
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
        visible: historyPane.hasConversation && DmManager.loadingOlderMessages && DmManager.messages.count > 0
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
        visible: DmManager.messagesLoading && DmManager.messages.count === 0 && historyPane.conversationId.length > 0
        text: "Loading messages..."
        color: Theme.textMuted
        font.pixelSize: 13
    }

    Rectangle {
        id: scrollToBottomButton

        anchors.horizontalCenter: historyList.horizontalCenter
        anchors.bottom: historyList.bottom
        anchors.bottomMargin: 16
        width: 36
        height: 36
        radius: 18
        color: scrollToBottomHover.hovered ? Qt.lighter(Theme.surfaceMid, 1.3) : Theme.surfaceMid
        border.width: 1
        border.color: Theme.surfaceBorder
        visible: historyPane.hasConversation
                 && DmManager.messages.count > 0
                 && !historyPane.autoScrollPending
                 && historyList.contentHeight > historyList.height
                 && historyPane._distanceFromBottom() > 150
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        HoverHandler {
            id: scrollToBottomHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: {
                historyPane.autoScrollPending = true
                historyPane.ownSendPending = true
                Qt.callLater(historyPane._flushPendingAutoScroll)
            }
        }

        Image {
            anchors.centerIn: parent
            source: "/assets/icons/arrow_upward.svg"
            rotation: 180
            width: 16
            height: 16
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            smooth: true
            mipmap: true
        }
    }
}
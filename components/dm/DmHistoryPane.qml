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

    activeFocusOnTab: historyPane.hasConversation

    readonly property real olderMessagesPrefetchDistance: 800
    property bool autoScrollPending: false
    property bool initialBottomScrollPending: false
    property bool ownSendPending: false
    property bool selectionDragActive: false
    property bool selectionDragMoved: false
    property int selectionAnchorIndex: -1
    property int selectionAnchorPosition: -1
    property int selectionFocusIndex: -1
    property int selectionFocusPosition: -1
    property real selectionPointerContentX: 0
    property real selectionPointerViewportY: 0
    property var selectionBubbles: []

    readonly property real selectionEdgeAutoScrollZone: 48
    readonly property real selectionEdgeAutoScrollStep: 24

    readonly property bool hasSelectionCursor: selectionAnchorIndex >= 0
                                                && selectionFocusIndex >= 0

    readonly property bool hasTextSelection: hasSelectionCursor
                                            && (selectionAnchorIndex !== selectionFocusIndex
                                                || selectionAnchorPosition !== selectionFocusPosition)

    clip: true

    function _selectionPointComesBefore(indexA, positionA, indexB, positionB) {
        if (indexA === indexB)
            return positionA <= positionB;

        return indexA > indexB;
    }

    function _updateSelectionPointer(contentX, contentY) {
        selectionPointerContentX = contentX;
        selectionPointerViewportY = contentY - historyList.contentY;
    }

    function _selectionAutoScrollDelta() {
        if (!selectionDragActive || !historyList.visible || historyList.height <= 0)
            return 0;

        if (selectionPointerViewportY < 0) {
            const topProgress = Math.min(selectionEdgeAutoScrollZone,
                                         Math.max(0, -selectionPointerViewportY))
                    / selectionEdgeAutoScrollZone;
            return -selectionEdgeAutoScrollStep * topProgress;
        }

        if (selectionPointerViewportY > historyList.height) {
            const bottomProgress = Math.min(selectionEdgeAutoScrollZone,
                                            Math.max(0, selectionPointerViewportY - historyList.height))
                    / selectionEdgeAutoScrollZone;
            return selectionEdgeAutoScrollStep * bottomProgress;
        }

        return 0;
    }

    function _updateSelectionAutoScrollState() {
        selectionAutoScrollTimer.running = selectionDragActive && _selectionAutoScrollDelta() !== 0;
    }

    function _stepSelectionAutoScroll() {
        const delta = _selectionAutoScrollDelta();
        if (delta === 0) {
            selectionAutoScrollTimer.running = false;
            return;
        }

        const minContentY = historyList.originY;
        const maxContentY = historyList.originY + Math.max(0, historyList.contentHeight - historyList.height);
        const nextContentY = Math.max(minContentY, Math.min(maxContentY, historyList.contentY + delta));
        if (nextContentY === historyList.contentY) {
            selectionAutoScrollTimer.running = false;
            return;
        }

        historyList.contentY = nextContentY;
        _updateSelectionFocus(selectionPointerContentX, historyList.contentY + selectionPointerViewportY);
    }

    function _messageBodyLength(index) {
        return DmManager.messages.bodyAt(index).length;
    }

    function _setCollapsedSelection(index, position) {
        selectionDragActive = false;
        selectionDragMoved = false;
        selectionAnchorIndex = index;
        selectionAnchorPosition = position;
        selectionFocusIndex = index;
        selectionFocusPosition = position;
        _refreshVisibleSelection();
    }

    function _ensureKeyboardSelectionStart() {
        if (DmManager.messages.count === 0)
            return false;

        if (hasSelectionCursor)
            return true;

        _setCollapsedSelection(0, _messageBodyLength(0));
        return true;
    }

    function _nextHorizontalSelectionPoint(index, position, direction) {
        if (direction < 0) {
            if (position > 0) {
                return {
                    index: index,
                    position: position - 1,
                };
            }

            if (index + 1 < DmManager.messages.count) {
                return {
                    index: index + 1,
                    position: _messageBodyLength(index + 1),
                };
            }
        } else if (direction > 0) {
            const messageLength = _messageBodyLength(index);
            if (position < messageLength) {
                return {
                    index: index,
                    position: position + 1,
                };
            }

            if (index - 1 >= 0) {
                return {
                    index: index - 1,
                    position: 0,
                };
            }
        }

        return {
            index: index,
            position: position,
        };
    }

    function _nextVerticalSelectionPoint(index, position, direction) {
        const nextIndex = Math.max(0, Math.min(DmManager.messages.count - 1, index + direction));
        return {
            index: nextIndex,
            position: Math.max(0, Math.min(position, _messageBodyLength(nextIndex))),
        };
    }

    function _applyKeyboardSelectionPoint(point, extendSelection) {
        if (extendSelection) {
            selectionFocusIndex = point.index;
            selectionFocusPosition = point.position;
            _refreshVisibleSelection();
        } else {
            _setCollapsedSelection(point.index, point.position);
        }

        historyList.positionViewAtIndex(point.index, ListView.Visible);
    }

    function _moveSelectionHorizontally(direction, extendSelection) {
        if (!_ensureKeyboardSelectionStart())
            return false;

        const point = _nextHorizontalSelectionPoint(selectionFocusIndex,
                                                    selectionFocusPosition,
                                                    direction);
        _applyKeyboardSelectionPoint(point, extendSelection);
        return true;
    }

    function _moveSelectionVertically(direction, extendSelection) {
        if (!_ensureKeyboardSelectionStart())
            return false;

        const point = _nextVerticalSelectionPoint(selectionFocusIndex,
                                                  selectionFocusPosition,
                                                  direction);
        _applyKeyboardSelectionPoint(point, extendSelection);
        return true;
    }

    function selectAllText() {
        if (DmManager.messages.count === 0)
            return;

        selectionDragActive = false;
        selectionDragMoved = false;
        selectionAnchorIndex = DmManager.messages.count - 1;
        selectionAnchorPosition = 0;
        selectionFocusIndex = 0;
        selectionFocusPosition = _messageBodyLength(0);
        _refreshVisibleSelection();
    }

    function _selectionBounds() {
        if (selectionAnchorIndex < 0 || selectionFocusIndex < 0) {
            return {
                valid: false,
                startIndex: -1,
                startPosition: -1,
                endIndex: -1,
                endPosition: -1,
            };
        }

        if (_selectionPointComesBefore(selectionAnchorIndex,
                                       selectionAnchorPosition,
                                       selectionFocusIndex,
                                       selectionFocusPosition)) {
            return {
                valid: true,
                startIndex: selectionAnchorIndex,
                startPosition: selectionAnchorPosition,
                endIndex: selectionFocusIndex,
                endPosition: selectionFocusPosition,
            };
        }

        return {
            valid: true,
            startIndex: selectionFocusIndex,
            startPosition: selectionFocusPosition,
            endIndex: selectionAnchorIndex,
            endPosition: selectionAnchorPosition,
        };
    }

    function _selectionRangeForIndex(index) {
        const bounds = _selectionBounds();
        if (!bounds.valid || !hasTextSelection) {
            return {
                active: false,
                start: 0,
                end: 0,
            };
        }

        const minIndex = Math.min(bounds.startIndex, bounds.endIndex);
        const maxIndex = Math.max(bounds.startIndex, bounds.endIndex);
        if (index < minIndex || index > maxIndex) {
            return {
                active: false,
                start: 0,
                end: 0,
            };
        }

        if (bounds.startIndex === bounds.endIndex) {
            return {
                active: true,
                start: bounds.startPosition,
                end: bounds.endPosition,
            };
        }

        if (index === bounds.startIndex) {
            return {
                active: true,
                start: bounds.startPosition,
                end: -1,
            };
        }

        if (index === bounds.endIndex) {
            return {
                active: true,
                start: 0,
                end: bounds.endPosition,
            };
        }

        return {
            active: true,
            start: 0,
            end: -1,
        };
    }

    function _refreshVisibleSelection() {
        for (let i = 0; i < selectionBubbles.length; ++i) {
            const bubbleItem = selectionBubbles[i];
            if (!bubbleItem)
                continue;

            const range = _selectionRangeForIndex(bubbleItem.selectionIndex);
            bubbleItem.applySelectionRange(range.active, range.start, range.end);
        }
    }

    function _selectionBubbleAtContentY(contentY) {
        let nearestBubble = null;
        let nearestDistance = Number.MAX_VALUE;

        for (let i = 0; i < selectionBubbles.length; ++i) {
            const bubbleItem = selectionBubbles[i];
            if (!bubbleItem || !bubbleItem.visible)
                continue;

            const bubbleTop = bubbleItem.y;
            const bubbleBottom = bubbleItem.y + bubbleItem.height;
            if (contentY >= bubbleTop && contentY <= bubbleBottom)
                return bubbleItem;

            const distance = contentY < bubbleTop ? bubbleTop - contentY : contentY - bubbleBottom;
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestBubble = bubbleItem;
            }
        }

        return nearestBubble;
    }

    function _updateSelectionFocus(contentX, contentY) {
        const bubbleItem = _selectionBubbleAtContentY(contentY);
        if (!bubbleItem)
            return;

        const nextIndex = bubbleItem.selectionIndex;
        const nextPosition = bubbleItem.cursorPositionFromSourcePoint(contentX, contentY);

        selectionDragMoved = selectionDragMoved
                || nextIndex !== selectionFocusIndex
                || nextPosition !== selectionFocusPosition;
        selectionFocusIndex = nextIndex;
        selectionFocusPosition = nextPosition;
        _refreshVisibleSelection();
    }

    function registerSelectionBubble(bubbleItem) {
        if (selectionBubbles.indexOf(bubbleItem) !== -1)
            return;

        selectionBubbles = selectionBubbles.concat([bubbleItem]);
        _refreshVisibleSelection();
    }

    function unregisterSelectionBubble(bubbleItem) {
        const index = selectionBubbles.indexOf(bubbleItem);
        if (index < 0)
            return;

        const nextBubbles = selectionBubbles.slice();
        nextBubbles.splice(index, 1);
        selectionBubbles = nextBubbles;
    }

    function clearTextSelection() {
        selectionDragActive = false;
        selectionDragMoved = false;
        selectionAnchorIndex = -1;
        selectionAnchorPosition = -1;
        selectionFocusIndex = -1;
        selectionFocusPosition = -1;
        selectionAutoScrollTimer.running = false;
        _refreshVisibleSelection();
    }

    function beginTextSelection(bubbleItem, contentX, contentY) {
        if (!bubbleItem)
            return;

        historyPane.forceActiveFocus();
        const anchorPosition = bubbleItem.cursorPositionFromSourcePoint(contentX, contentY);
        _updateSelectionPointer(contentX, contentY);
        selectionDragActive = true;
        selectionDragMoved = false;
        selectionAnchorIndex = bubbleItem.selectionIndex;
        selectionAnchorPosition = anchorPosition;
        selectionFocusIndex = bubbleItem.selectionIndex;
        selectionFocusPosition = anchorPosition;
        _updateSelectionAutoScrollState();
        _refreshVisibleSelection();
    }

    function updateTextSelection(contentX, contentY) {
        if (!selectionDragActive)
            return;

        _updateSelectionPointer(contentX, contentY);
        _updateSelectionFocus(contentX, contentY);
        _updateSelectionAutoScrollState();
    }

    function finishTextSelection() {
        if (!selectionDragActive)
            return;

        selectionDragActive = false;
        selectionAutoScrollTimer.running = false;
        if (!selectionDragMoved)
            _setCollapsedSelection(selectionFocusIndex, selectionFocusPosition);
    }

    function selectedText() {
        const bounds = _selectionBounds();
        if (!bounds.valid || !hasTextSelection)
            return "";

        const parts = [];
        for (let row = bounds.startIndex; row >= bounds.endIndex; --row) {
            const body = DmManager.messages.bodyAt(row);
            if (row === bounds.startIndex && row === bounds.endIndex) {
                parts.push(body.slice(bounds.startPosition, bounds.endPosition));
            } else if (row === bounds.startIndex) {
                parts.push(body.slice(bounds.startPosition));
            } else if (row === bounds.endIndex) {
                parts.push(body.slice(0, bounds.endPosition));
            } else {
                parts.push(body);
            }
        }

        return parts.join("\n");
    }

    function copySelectedText() {
        const text = selectedText();
        if (text.length === 0)
            return;

        clipboardProxy.text = text;
        clipboardProxy.selectAll();
        clipboardProxy.copy();
        clipboardProxy.deselect();
    }

    Keys.onPressed: event => {
        const extendSelection = (event.modifiers & Qt.ShiftModifier) !== 0;

        switch (event.key) {
        case Qt.Key_Left:
            event.accepted = historyPane._moveSelectionHorizontally(-1, extendSelection);
            break;
        case Qt.Key_Right:
            event.accepted = historyPane._moveSelectionHorizontally(1, extendSelection);
            break;
        case Qt.Key_Up:
            event.accepted = historyPane._moveSelectionVertically(1, extendSelection);
            break;
        case Qt.Key_Down:
            event.accepted = historyPane._moveSelectionVertically(-1, extendSelection);
            break;
        case Qt.Key_A:
            if ((event.modifiers & Qt.ControlModifier) !== 0) {
                historyPane.selectAllText();
                event.accepted = true;
            }
            break;
        case Qt.Key_Escape:
            if (historyPane.hasSelectionCursor) {
                historyPane.clearTextSelection();
                event.accepted = true;
            }
            break;
        default:
            break;
        }
    }

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
        historyPane.clearTextSelection()
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

            if (historyPane.hasTextSelection)
                historyPane.clearTextSelection()
        }

        function onRowsAboutToBeInserted(parent, first, last) {
            if (first === 0 && historyPane.viewVisible && historyList.atBottom)
                historyPane.autoScrollPending = true
        }
    }

    Shortcut {
        enabled: historyPane.hasTextSelection
        sequence: StandardKey.Copy
        context: Qt.WindowShortcut
        onActivated: historyPane.copySelectedText()
    }

    TextEdit {
        id: clipboardProxy

        visible: false
        width: 0
        height: 0
        readOnly: false
        textFormat: TextEdit.PlainText
    }

    Timer {
        id: selectionAutoScrollTimer

        interval: 16
        repeat: true
        running: false
        onTriggered: historyPane._stepSelectionAutoScroll()
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
            historyPane._refreshVisibleSelection()
            if (historyPane.selectionDragActive)
                historyPane._updateSelectionAutoScrollState()
            if (historyPane._distanceFromTop() <= historyPane.olderMessagesPrefetchDistance) {
                Qt.callLater(historyPane._requestOlderMessagesIfNeeded)
            }
        }

        onContentHeightChanged: {
            historyList.atBottom = historyPane._distanceFromBottom() <= 16
            historyPane._refreshVisibleSelection()
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
            selectionIndex: index
            selectionSourceItem: historyList.contentItem
            selectionController: historyPane
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
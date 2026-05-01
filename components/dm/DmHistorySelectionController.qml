pragma ComponentBehavior: Bound

import QtQuick
import "../.." as AppRoot

Item {
    id: selectionController

    property var historyList: null
    property Item focusTarget: null
    property var messagesModel: null

    visible: false
    width: 0
    height: 0

    property bool dragActive: false
    property bool dragMoved: false
    property int anchorIndex: -1
    property int anchorPosition: -1
    property int focusIndex: -1
    property int focusPosition: -1
    property real pointerContentX: 0
    property real pointerViewportY: 0
    property var bubbles: []

    readonly property real edgeAutoScrollZone: 48
    readonly property real edgeAutoScrollStep: 24

    readonly property bool hasSelectionCursor: anchorIndex >= 0 && focusIndex >= 0
    readonly property bool hasTextSelection: hasSelectionCursor
                                            && (anchorIndex !== focusIndex
                                                || anchorPosition !== focusPosition)

    function _selectionPointComesBefore(indexA, positionA, indexB, positionB) {
        if (indexA === indexB)
            return positionA <= positionB;

        return indexA > indexB;
    }

    function _updatePointer(contentX, contentY) {
        if (!historyList)
            return;

        pointerContentX = contentX;
        pointerViewportY = contentY - historyList.contentY;
    }

    function _autoScrollDelta() {
        if (!historyList || !dragActive || !historyList.visible || historyList.height <= 0)
            return 0;

        if (pointerViewportY < 0) {
            const topProgress = Math.min(edgeAutoScrollZone,
                                         Math.max(0, -pointerViewportY))
                    / edgeAutoScrollZone;
            return -edgeAutoScrollStep * topProgress;
        }

        if (pointerViewportY > historyList.height) {
            const bottomProgress = Math.min(edgeAutoScrollZone,
                                            Math.max(0, pointerViewportY - historyList.height))
                    / edgeAutoScrollZone;
            return edgeAutoScrollStep * bottomProgress;
        }

        return 0;
    }

    function _updateAutoScrollState() {
        selectionAutoScrollTimer.running = dragActive && _autoScrollDelta() !== 0;
    }

    function _stepAutoScroll() {
        if (!historyList) {
            selectionAutoScrollTimer.running = false;
            return;
        }

        const delta = _autoScrollDelta();
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
        _updateFocus(pointerContentX, historyList.contentY + pointerViewportY);
    }

    function _messageBodyLength(index) {
        if (!messagesModel)
            return 0;

        return messagesModel.bodyAt(index).length;
    }

    function _setCollapsedSelection(index, position) {
        dragActive = false;
        dragMoved = false;
        anchorIndex = index;
        anchorPosition = position;
        focusIndex = index;
        focusPosition = position;
        refreshVisibleSelection();
    }

    function _ensureKeyboardSelectionStart() {
        if (!messagesModel || messagesModel.count === 0)
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

            if (index + 1 < messagesModel.count) {
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
        const nextIndex = Math.max(0, Math.min(messagesModel.count - 1, index + direction));
        return {
            index: nextIndex,
            position: Math.max(0, Math.min(position, _messageBodyLength(nextIndex))),
        };
    }

    function _applyKeyboardSelectionPoint(point, extendSelection) {
        if (extendSelection) {
            focusIndex = point.index;
            focusPosition = point.position;
            refreshVisibleSelection();
        } else {
            _setCollapsedSelection(point.index, point.position);
        }

        if (historyList)
            historyList.positionViewAtIndex(point.index, ListView.Visible);
    }

    function _selectionBounds() {
        if (anchorIndex < 0 || focusIndex < 0) {
            return {
                valid: false,
                startIndex: -1,
                startPosition: -1,
                endIndex: -1,
                endPosition: -1,
            };
        }

        if (_selectionPointComesBefore(anchorIndex,
                                       anchorPosition,
                                       focusIndex,
                                       focusPosition)) {
            return {
                valid: true,
                startIndex: anchorIndex,
                startPosition: anchorPosition,
                endIndex: focusIndex,
                endPosition: focusPosition,
            };
        }

        return {
            valid: true,
            startIndex: focusIndex,
            startPosition: focusPosition,
            endIndex: anchorIndex,
            endPosition: anchorPosition,
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

    function _selectionBubbleAtContentY(contentY) {
        let nearestBubble = null;
        let nearestDistance = Number.MAX_VALUE;

        for (let i = 0; i < bubbles.length; ++i) {
            const bubbleItem = bubbles[i];
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

    function _updateFocus(contentX, contentY) {
        const bubbleItem = _selectionBubbleAtContentY(contentY);
        if (!bubbleItem)
            return;

        const nextIndex = bubbleItem.selectionIndex;
        const nextPosition = bubbleItem.cursorPositionFromSourcePoint(contentX, contentY);

        dragMoved = dragMoved
                || nextIndex !== focusIndex
                || nextPosition !== focusPosition;
        focusIndex = nextIndex;
        focusPosition = nextPosition;
        refreshVisibleSelection();
    }

    function moveSelectionHorizontally(direction, extendSelection) {
        if (!_ensureKeyboardSelectionStart())
            return false;

        const point = _nextHorizontalSelectionPoint(focusIndex,
                                                    focusPosition,
                                                    direction);
        _applyKeyboardSelectionPoint(point, extendSelection);
        return true;
    }

    function moveSelectionVertically(direction, extendSelection) {
        if (!_ensureKeyboardSelectionStart())
            return false;

        const point = _nextVerticalSelectionPoint(focusIndex,
                                                  focusPosition,
                                                  direction);
        _applyKeyboardSelectionPoint(point, extendSelection);
        return true;
    }

    function selectAllText() {
        if (!messagesModel || messagesModel.count === 0)
            return;

        dragActive = false;
        dragMoved = false;
        anchorIndex = messagesModel.count - 1;
        anchorPosition = 0;
        focusIndex = 0;
        focusPosition = _messageBodyLength(0);
        refreshVisibleSelection();
    }

    function refreshVisibleSelection() {
        for (let i = 0; i < bubbles.length; ++i) {
            const bubbleItem = bubbles[i];
            if (!bubbleItem)
                continue;

            const range = _selectionRangeForIndex(bubbleItem.selectionIndex);
            bubbleItem.applySelectionRange(range.active, range.start, range.end);
        }
    }

    function syncAfterViewportChanged() {
        if (!historyList)
            return;

        refreshVisibleSelection();

        if (dragActive)
            _updateAutoScrollState();
    }

    function registerSelectionBubble(bubbleItem) {
        if (bubbles.indexOf(bubbleItem) !== -1)
            return;

        bubbles = bubbles.concat([bubbleItem]);
        refreshVisibleSelection();
    }

    function unregisterSelectionBubble(bubbleItem) {
        const index = bubbles.indexOf(bubbleItem);
        if (index < 0)
            return;

        const nextBubbles = bubbles.slice();
        nextBubbles.splice(index, 1);
        bubbles = nextBubbles;
    }

    function clearTextSelection() {
        dragActive = false;
        dragMoved = false;
        anchorIndex = -1;
        anchorPosition = -1;
        focusIndex = -1;
        focusPosition = -1;
        selectionAutoScrollTimer.running = false;
        refreshVisibleSelection();
    }

    function beginTextSelection(bubbleItem, contentX, contentY) {
        if (!bubbleItem || !focusTarget || !historyList)
            return;

        focusTarget.forceActiveFocus();
        const nextAnchorPosition = bubbleItem.cursorPositionFromSourcePoint(contentX, contentY);
        _updatePointer(contentX, contentY);
        dragActive = true;
        dragMoved = false;
        anchorIndex = bubbleItem.selectionIndex;
        anchorPosition = nextAnchorPosition;
        focusIndex = bubbleItem.selectionIndex;
        focusPosition = nextAnchorPosition;
        _updateAutoScrollState();
        refreshVisibleSelection();
    }

    function updateTextSelection(contentX, contentY) {
        if (!dragActive)
            return;

        _updatePointer(contentX, contentY);
        _updateFocus(contentX, contentY);
        _updateAutoScrollState();
    }

    function finishTextSelection() {
        if (!dragActive)
            return;

        dragActive = false;
        selectionAutoScrollTimer.running = false;
        if (!dragMoved)
            _setCollapsedSelection(focusIndex, focusPosition);
    }

    function selectedText() {
        if (!messagesModel)
            return "";

        const bounds = _selectionBounds();
        if (!bounds.valid || !hasTextSelection)
            return "";

        const parts = [];
        for (let row = bounds.startIndex; row >= bounds.endIndex; --row) {
            const body = messagesModel.bodyAt(row);
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
        if (text.length > 0)
            AppRoot.ClipboardHelper.copyText(text);
    }

    Timer {
        id: selectionAutoScrollTimer

        interval: 16
        repeat: true
        running: false
        onTriggered: selectionController._stepAutoScroll()
    }
}
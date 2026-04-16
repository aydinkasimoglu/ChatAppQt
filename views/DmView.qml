pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../components/dm"

Rectangle {
    id: dmViewRoot

    color: Theme.surfaceRaised

    required property string conversationId
    required property string conversationTitle

    signal messageSent(string text)

    readonly property bool hasConversation: conversationTitle.length > 0 || conversationId.length > 0
    readonly property bool canCompose: conversationId.length > 0

    function _send(body) {
        historyPane.prepareOwnSend()
        DmManager.sendMessage(body)
        dmViewRoot.messageSent(body)
    }

    onConversationIdChanged: {
        historyPane.resetForConversationChange()
        composer.clear()
        composer.blurInput()
        historyPane.armOpenToLatest()
    }

    onVisibleChanged: {
        if (!visible)
            composer.blurInput()

        if (visible && dmViewRoot.hasConversation)
            historyPane.armOpenToLatest()

        historyPane.scheduleAcknowledgeVisibleMessages()
    }

    Connections {
        target: DmManager

        function onMessageSent() {
            if (!dmViewRoot.visible)
                return

            composer.clear()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        DmHeaderBar {
            id: headerBar

            Layout.fillWidth: true
            Layout.preferredHeight: headerBar.implicitHeight
            conversationTitle: dmViewRoot.conversationTitle
        }

        DmHistoryPane {
            id: historyPane

            Layout.fillWidth: true
            Layout.fillHeight: true
            conversationId: dmViewRoot.conversationId
            conversationTitle: dmViewRoot.conversationTitle
            hasConversation: dmViewRoot.hasConversation
            viewVisible: dmViewRoot.visible
        }

        DmComposer {
            id: composer

            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 24
            canCompose: dmViewRoot.canCompose
            conversationTitle: dmViewRoot.conversationTitle
            onSendRequested: (text) => dmViewRoot._send(text)
        }
    }
}

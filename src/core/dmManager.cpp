#include "dmManager.h"
#include "authClient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>

namespace {

constexpr int MessagePageSize = 50;

bool responseHasOlderMessages(const QJsonObject &response)
{
    const QJsonValue hasOlderValue = response.value(QStringLiteral("has_older"));
    if (hasOlderValue.isBool())
        return hasOlderValue.toBool();

    return !response.value(QStringLiteral("next_before_message_id")).toString().isEmpty();
}

}

DmManager::DmManager(QObject *parent)
    : QObject(parent)
{}

void DmManager::fetchConversations()
{
    setConversationsLoading(true);

    QNetworkReply *reply = NetworkClient::instance().get("/conversations?limit=50", true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setConversationsLoading(false);

        const JsonObjectResponse response = NetworkClient::instance().jsonResponse<QJsonObject>(
            reply,
            QStringLiteral("Couldn't load direct messages."),
            QStringLiteral("Invalid direct message history response."));
        if (!response.ok) {
            emit conversationsLoadFailed(response.errorMessage);
            return;
        }

        const QJsonValue itemsValue = response.data.value("items");
        if (!itemsValue.isArray()) {
            emit conversationsLoadFailed(QStringLiteral("Invalid direct message history response."));
            return;
        }

        m_conversations.reset(itemsValue.toArray(), AuthClient::instance()->userId());
        syncCurrentConversationFromModel();
    });
}

void DmManager::openDirectConversation(const QString &userId, const QString &username)
{
    if (userId.trimmed().isEmpty()) {
        emit conversationOpenFailed(QStringLiteral("Invalid DM recipient."));
        return;
    }

    const QString existingConversationId = m_conversations.conversationIdForDirectPartner(userId);
    if (!existingConversationId.isEmpty()) {
        const QVariantMap conversation = m_conversations.conversationById(existingConversationId);
        selectConversation(existingConversationId,
                           conversation.value(QStringLiteral("displayTitle"), username).toString(),
                           conversation.value(QStringLiteral("directPartnerId"), userId).toString());
        return;
    }

    setCurrentConversation(QString(), username, userId);
    m_messages.clear();
    setOpeningConversation(true);

    QJsonObject payload;
    payload["participant_ids"] = QJsonArray{ userId };

    QNetworkReply *reply = NetworkClient::instance().post("/conversations", payload, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, userId, username]() {
        reply->deleteLater();

        // Check if the user navigated away while the POST was running
        if (m_currentDirectPartnerId != userId) {
            return; 
        }

        setOpeningConversation(false);

        const JsonObjectResponse response = NetworkClient::instance().jsonResponse<QJsonObject>(
            reply,
            QStringLiteral("Couldn't open direct message."),
            QStringLiteral("Invalid direct message response."));
        if (!response.ok) {
            setCurrentConversation(QString(), QString(), QString());
            m_messages.clear();
            emit conversationOpenFailed(response.errorMessage);
            return;
        }

        const QString conversationId = response.data.value("conversation_id").toString();
        if (conversationId.isEmpty()) {
            setCurrentConversation(QString(), QString(), QString());
            m_messages.clear();
            emit conversationOpenFailed(QStringLiteral("Invalid direct message response."));
            return;
        }

        const QString title = response.data.value("display_title").toString(username);
        const QString directPartnerId = response.data.value("direct_partner_id").toString(userId);

        setCurrentConversation(conversationId, title, directPartnerId);
        loadMessages(conversationId);
        fetchConversations();
    });
}

void DmManager::selectConversation(const QString &conversationId,
                                   const QString &title,
                                   const QString &directPartnerId)
{
    if (conversationId.trimmed().isEmpty())
        return;

    if (conversationId == m_currentConversationId) {
        setCurrentConversation(conversationId, title, directPartnerId);
        return;
    }

    setOpeningConversation(false);
    setCurrentConversation(conversationId, title, directPartnerId);
    m_messages.clear();
    loadMessages(conversationId);
}

void DmManager::setCurrentConversationReadActive(bool active)
{
    if (m_currentConversationReadActive == active)
        return;

    m_currentConversationReadActive = active;
    emit currentConversationReadActiveChanged();
}

void DmManager::acknowledgeCurrentConversationMessages()
{
    if (!m_currentConversationReadActive || m_currentConversationId.isEmpty())
        return;

    const QString latestMessageId = m_messages.latestMessageId();
    if (latestMessageId.isEmpty())
        return;

    markConversationRead(m_currentConversationId, latestMessageId);
}

void DmManager::loadOlderMessages()
{
    if (m_currentConversationId.isEmpty()
        || m_messagesLoading
        || m_loadingOlderMessages
        || m_historyStartReached) {
        return;
    }

    const QString beforeMessageId = m_messages.oldestMessageId();
    if (beforeMessageId.isEmpty()) {
        setHistoryStartReached(true);
        return;
    }

    const QString conversationId = m_currentConversationId;

    setLoadingOlderMessages(true);

    QNetworkReply *reply = NetworkClient::instance().get(
        QStringLiteral("/conversations/%1/messages?limit=%2&before_message_id=%3")
            .arg(conversationId)
            .arg(MessagePageSize)
            .arg(beforeMessageId),
        true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, conversationId]() {
        reply->deleteLater();

        if (conversationId != m_currentConversationId) {
            return;
        }

        const JsonObjectResponse response = NetworkClient::instance().jsonResponse<QJsonObject>(
            reply,
            QStringLiteral("Couldn't load older direct messages."),
            QStringLiteral("Invalid direct message history response."));
        if (!response.ok) {
            setLoadingOlderMessages(false);
            emit messagesLoadFailed(response.errorMessage);
            return;
        }

        const QJsonValue itemsValue = response.data.value("items");
        if (!itemsValue.isArray()) {
            setLoadingOlderMessages(false);
            emit messagesLoadFailed(QStringLiteral("Invalid direct message history response."));
            return;
        }

        const QJsonArray items = itemsValue.toArray();
        const bool hasOlder = responseHasOlderMessages(response.data);
        setHistoryStartReached(!hasOlder);

        if (!items.isEmpty())
            m_messages.appendOlderPage(items, AuthClient::instance()->userId());

        setLoadingOlderMessages(false);
    });
}

void DmManager::sendMessage(const QString &text)
{
    const QString content = text.trimmed();
    if (content.isEmpty())
        return;

    if (m_currentConversationId.isEmpty()) {
        emit messageSendFailed(QStringLiteral("No direct message is selected."));
        return;
    }

    const QString conversationId = m_currentConversationId;
    QJsonObject payload;
    payload["content"] = content;

    QNetworkReply *reply = NetworkClient::instance().post(
        QStringLiteral("/conversations/") + conversationId + QStringLiteral("/messages"),
        payload,
        true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, conversationId]() {
        reply->deleteLater();

        const JsonObjectResponse response = NetworkClient::instance().jsonResponse<QJsonObject>(
            reply,
            QStringLiteral("Couldn't send direct message."),
            QStringLiteral("Invalid direct message response."));
        if (!response.ok) {
            emit messageSendFailed(response.errorMessage);
            return;
        }

        if (conversationId == m_currentConversationId)
            m_messages.prependMessage(response.data, AuthClient::instance()->userId());

        m_conversations.updateConversationFromMessage(
            conversationId,
            response.data.toVariantMap(), 
            AuthClient::instance()->userId(), 
            true
        );
        emit messageSent();
    });
}

void DmManager::handleIncomingMessage(const QString &conversationId, const QVariantMap &message)
{
    const bool isActive = (conversationId == m_currentConversationId);

    // Update conversation list locally (Title, unread counts, moves to top)
    m_conversations.updateConversationFromMessage(conversationId, message, AuthClient::instance()->userId(), isActive);

    // If it is NOT in our list (like a brand new DM), fetch from the server
    if (!m_conversations.containsConversation(conversationId)) {
        fetchConversations();
    }

    // Show the new message immediately if we are looking at this chat
    if (isActive) {
        m_messages.prependMessage(message, AuthClient::instance()->userId());
    }
}

void DmManager::resetState()
{
    setCurrentConversationReadActive(false);
    setOpeningConversation(false);
    setConversationsLoading(false);
    setMessagesLoading(false);
    resetMessagePaginationState();
    setCurrentConversation(QString(), QString(), QString());
    m_conversations.clear();
    m_messages.clear();
}

void DmManager::loadMessages(const QString &conversationId)
{
    if (conversationId.isEmpty()) {
        resetMessagePaginationState();
        m_messages.clear();
        return;
    }

    resetMessagePaginationState();
    setMessagesLoading(true);

    QNetworkReply *reply = NetworkClient::instance().get(
        QStringLiteral("/conversations/") + conversationId
            + QStringLiteral("/messages?limit=%1").arg(MessagePageSize),
        true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, conversationId]() {
        reply->deleteLater();

        if (conversationId != m_currentConversationId) {
            return;
        }

        setMessagesLoading(false);

        const JsonObjectResponse response = NetworkClient::instance().jsonResponse<QJsonObject>(
            reply,
            QStringLiteral("Couldn't load direct message history."),
            QStringLiteral("Invalid direct message history response."));
        if (!response.ok) {
            emit messagesLoadFailed(response.errorMessage);
            return;
        }

        const QJsonValue itemsValue = response.data.value("items");
        if (!itemsValue.isArray()) {
            emit messagesLoadFailed(QStringLiteral("Invalid direct message history response."));
            return;
        }

        const QJsonArray items = itemsValue.toArray();
        const bool hasOlder = responseHasOlderMessages(response.data);
        setHistoryStartReached(!hasOlder);
        m_messages.reset(items, AuthClient::instance()->userId());
    });
}

void DmManager::markConversationRead(const QString &conversationId, const QString &messageId)
{
    if (conversationId.isEmpty() || messageId.isEmpty())
        return;

    QJsonObject payload;
    payload["up_to_message_id"] = messageId;

    QNetworkReply *reply = NetworkClient::instance().patch(
        QStringLiteral("/conversations/") + conversationId + QStringLiteral("/read"),
        payload,
        true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, conversationId]() {
        reply->deleteLater();

        const NetworkResponse response = NetworkClient::instance().response(reply);
        if (!response.ok)
            return;

        m_conversations.clearUnreadCount(conversationId);
    });
}

void DmManager::setConversationsLoading(bool loading)
{
    if (m_conversationsLoading == loading)
        return;

    m_conversationsLoading = loading;
    emit conversationsLoadingChanged();
}

void DmManager::setMessagesLoading(bool loading)
{
    if (m_messagesLoading == loading)
        return;

    m_messagesLoading = loading;
    emit messagesLoadingChanged();
}

void DmManager::setLoadingOlderMessages(bool loading)
{
    if (m_loadingOlderMessages == loading)
        return;

    m_loadingOlderMessages = loading;
    emit loadingOlderMessagesChanged();
}

void DmManager::setHistoryStartReached(bool reached)
{
    if (m_historyStartReached == reached)
        return;

    m_historyStartReached = reached;
    emit historyStartReachedChanged();
}

void DmManager::setOpeningConversation(bool loading)
{
    if (m_openingConversation == loading)
        return;

    m_openingConversation = loading;
    emit openingConversationChanged();
}

void DmManager::setCurrentConversation(const QString &conversationId,
                                       const QString &title,
                                       const QString &directPartnerId)
{
    if (m_currentConversationId == conversationId
        && m_currentConversationTitle == title
        && m_currentDirectPartnerId == directPartnerId) {
        return;
    }

    m_currentConversationId = conversationId;
    m_currentConversationTitle = title;
    m_currentDirectPartnerId = directPartnerId;
    emit currentConversationChanged();
}

void DmManager::syncCurrentConversationFromModel()
{
    if (m_currentConversationId.isEmpty())
        return;

    const QVariantMap conversation = m_conversations.conversationById(m_currentConversationId);
    if (conversation.isEmpty())
        return;

    setCurrentConversation(
        m_currentConversationId,
        conversation.value(QStringLiteral("displayTitle"), m_currentConversationTitle).toString(),
        conversation.value(QStringLiteral("directPartnerId"), m_currentDirectPartnerId).toString());
}

void DmManager::resetMessagePaginationState()
{
    setLoadingOlderMessages(false);
    setHistoryStartReached(false);
}
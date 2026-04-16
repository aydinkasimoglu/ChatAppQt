#include "dmConversationListModel.h"

#include <QJsonObject>

DmConversationListModel::DmConversationListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(this, &QAbstractListModel::rowsInserted, this, &DmConversationListModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved, this, &DmConversationListModel::countChanged);
    connect(this, &QAbstractListModel::modelReset, this, &DmConversationListModel::countChanged);
}

int DmConversationListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_conversations.count();
}

QVariant DmConversationListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_conversations.count())
        return {};

    const ConversationItem &conversation = m_conversations.at(index.row());
    switch (role) {
    case ConversationIdRole:
        return conversation.conversationId;
    case KindRole:
        return conversation.kind;
    case DisplayTitleRole:
        return conversation.displayTitle;
    case DirectPartnerIdRole:
        return conversation.directPartnerId;
    case ParticipantCountRole:
        return conversation.participantCount;
    case UnreadCountRole:
        return conversation.unreadCount;
    case HasUnreadRole:
        return conversation.unreadCount > 0;
    case LastMessagePreviewRole:
        return conversation.lastMessagePreview;
    case LastActivityAtRole:
        return conversation.lastActivityAt;
    default:
        return {};
    }
}

QHash<int, QByteArray> DmConversationListModel::roleNames() const
{
    return {
        { ConversationIdRole, "conversationId" },
        { KindRole, "kind" },
        { DisplayTitleRole, "displayTitle" },
        { DirectPartnerIdRole, "directPartnerId" },
        { ParticipantCountRole, "participantCount" },
        { UnreadCountRole, "unreadCount" },
        { HasUnreadRole, "hasUnread" },
        { LastMessagePreviewRole, "lastMessagePreview" },
        { LastActivityAtRole, "lastActivityAt" },
    };
}

void DmConversationListModel::reset(const QJsonArray &conversations, const QString &currentUserId)
{
    beginResetModel();
    m_conversations.clear();

    for (const QJsonValue &value : conversations) {
        if (!value.isObject())
            continue;

        m_conversations.append(conversationFromJson(value.toObject(), currentUserId));
    }

    endResetModel();
}

void DmConversationListModel::clear()
{
    beginResetModel();
    m_conversations.clear();
    endResetModel();
}

bool DmConversationListModel::containsConversation(const QString &conversationId) const
{
    for (const ConversationItem &conversation : m_conversations) {
        if (conversation.conversationId == conversationId)
            return true;
    }

    return false;
}

QVariantMap DmConversationListModel::conversationById(const QString &conversationId) const
{
    for (const ConversationItem &conversation : m_conversations) {
        if (conversation.conversationId == conversationId)
            return toVariantMap(conversation);
    }

    return {};
}

QString DmConversationListModel::conversationIdForDirectPartner(const QString &directPartnerId) const
{
    for (const ConversationItem &conversation : m_conversations) {
        if (conversation.directPartnerId == directPartnerId)
            return conversation.conversationId;
    }

    return {};
}

DmConversationListModel::ConversationItem DmConversationListModel::conversationFromJson(
    const QJsonObject &object, const QString &currentUserId)
{
    ConversationItem conversation;
    conversation.conversationId = object.value("conversation_id").toString();
    conversation.kind = object.value("kind").toString();
    conversation.displayTitle = object.value("display_title").toString();
    conversation.directPartnerId = object.value("direct_partner_id").toString();
    conversation.participantCount = static_cast<int>(object.value("participant_count").toInteger());
    conversation.unreadCount = static_cast<int>(object.value("unread_count").toInteger());
    conversation.lastActivityAt = object.value("last_activity_at").toString();

    const QJsonObject lastMessage = object.value("last_message").toObject();
    if (lastMessage.isEmpty()) {
        conversation.lastMessagePreview = QStringLiteral("Start a conversation");
        return conversation;
    }

    const QString senderId = lastMessage.value("sender_id").toString();
    const QString content = lastMessage.value("content").toString();
    const QString basePreview = content.isEmpty() ? QStringLiteral("Message deleted") : content;

    if (!currentUserId.isEmpty() && senderId == currentUserId)
        conversation.lastMessagePreview = QStringLiteral("You: %1").arg(basePreview);
    else
        conversation.lastMessagePreview = basePreview;

    return conversation;
}

QVariantMap DmConversationListModel::toVariantMap(const ConversationItem &conversation)
{
    return {
        { QStringLiteral("conversationId"), conversation.conversationId },
        { QStringLiteral("kind"), conversation.kind },
        { QStringLiteral("displayTitle"), conversation.displayTitle },
        { QStringLiteral("directPartnerId"), conversation.directPartnerId },
        { QStringLiteral("participantCount"), conversation.participantCount },
        { QStringLiteral("unreadCount"), conversation.unreadCount },
        { QStringLiteral("lastMessagePreview"), conversation.lastMessagePreview },
        { QStringLiteral("lastActivityAt"), conversation.lastActivityAt },
    };
}

void DmConversationListModel::updateConversationFromMessage(const QString &conversationId, 
                                                            const QVariantMap &message, 
                                                            const QString &currentUserId, 
                                                            bool isCurrentOpenConversation)
{
    int foundIndex = -1;
    for (int i = 0; i < m_conversations.size(); ++i) {
        if (m_conversations[i].conversationId == conversationId) {
            foundIndex = i;
            break;
        }
    }

    ConversationItem item;

    if (foundIndex != -1) {
        // Remove it from its current position to move it to the top
        beginRemoveRows({}, foundIndex, foundIndex);
        item = m_conversations.takeAt(foundIndex);
        endRemoveRows();
    } else {
        // If the conversation is brand new (not in the list), 
        // fall back to fetching from the server.
        return; 
    }

    // 1. Update the snippet
    const QString senderId = message.value(QStringLiteral("sender_id")).toString();
    const QString content = message.value(QStringLiteral("content")).toString();
    const QString basePreview = content.isEmpty() ? tr("Message deleted") : content;

    if (!currentUserId.isEmpty() && senderId == currentUserId)
        item.lastMessagePreview = tr("You: %1").arg(basePreview);
    else
        item.lastMessagePreview = basePreview;

    // 2. Update metadata
    item.lastActivityAt = message.value(QStringLiteral("created_at")).toString();

    // 3. Increment unread count if it's from someone else and we aren't looking at it
    if (!isCurrentOpenConversation && senderId != currentUserId) {
        item.unreadCount++;
    }

    // 4. Insert at the top of the list
    beginInsertRows({}, 0, 0);
    m_conversations.prepend(item);
    endInsertRows();
}
#include "dmMessageListModel.h"

#include <QDateTime>
#include <QJsonObject>

DmMessageListModel::DmMessageListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    connect(this, &QAbstractListModel::rowsInserted, this, &DmMessageListModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved, this, &DmMessageListModel::countChanged);
    connect(this, &QAbstractListModel::modelReset, this, &DmMessageListModel::countChanged);
}

int DmMessageListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_messages.count();
}

QVariant DmMessageListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_messages.count())
        return {};

    const MessageItem &message = m_messages.at(index.row());
    switch (role) {
    case MessageIdRole:
        return message.messageId;
    case ConversationIdRole:
        return message.conversationId;
    case SenderIdRole:
        return message.senderId;
    case SenderUsernameRole:
        return message.senderUsername;
    case BodyRole:
        return message.body;
    case TimeLabelRole:
        return message.timeLabel;
    case CreatedAtRole:
        return message.createdAt;
    case IsSelfRole:
        return message.isSelf;
    case IsDeletedRole:
        return message.isDeleted;
    default:
        return {};
    }
}

QHash<int, QByteArray> DmMessageListModel::roleNames() const
{
    return {
        { MessageIdRole, "messageId" },
        { ConversationIdRole, "conversationId" },
        { SenderIdRole, "senderId" },
        { SenderUsernameRole, "senderUsername" },
        { BodyRole, "body" },
        { TimeLabelRole, "timeLabel" },
        { CreatedAtRole, "createdAt" },
        { IsSelfRole, "isSelf" },
        { IsDeletedRole, "isDeleted" },
    };
}

void DmMessageListModel::reset(const QJsonArray &messages, const QString &currentUserId)
{
    beginResetModel();
    m_messages.clear();

    for (int index = messages.size() - 1; index >= 0; --index) {
        const QJsonValue value = messages.at(index);
        if (!value.isObject())
            continue;

        m_messages.append(messageFromJson(value.toObject(), currentUserId));
    }

    endResetModel();
}

void DmMessageListModel::prepend(const QJsonArray &messages, const QString &currentUserId)
{
    if (messages.isEmpty())
        return;

    QList<MessageItem> pageItems;
    pageItems.reserve(messages.size());

    for (int index = messages.size() - 1; index >= 0; --index) {
        const QJsonValue value = messages.at(index);
        if (!value.isObject())
            continue;

        QJsonObject obj = value.toObject();
        if (!containsMessage(obj.value("message_id").toString())) {
            pageItems.append(messageFromJson(obj, currentUserId));
        }
    }

    if (pageItems.isEmpty())
        return;

    beginInsertRows({}, 0, pageItems.size() - 1);
    // Efficiently prepend by creating a new list, reserving exact capacity, 
    // and appending the blocks.
    QList<MessageItem> combined;
    combined.reserve(pageItems.size() + m_messages.size());
    combined.append(pageItems);
    combined.append(m_messages);
    m_messages = std::move(combined);

    endInsertRows();
}

void DmMessageListModel::append(const QJsonObject &message, const QString &currentUserId)
{
    const QString messageId = message.value("message_id").toString();
    if (messageId.isEmpty() || containsMessage(messageId))
        return;

    const int insertRow = m_messages.count();
    beginInsertRows({}, insertRow, insertRow);
    m_messages.append(messageFromJson(message, currentUserId));
    endInsertRows();
}

void DmMessageListModel::append(const QVariantMap &message, const QString &currentUserId)
{
    append(QJsonObject::fromVariantMap(message), currentUserId);
}

void DmMessageListModel::clear()
{
    beginResetModel();
    m_messages.clear();
    endResetModel();
}

QString DmMessageListModel::latestMessageId() const
{
    return m_messages.isEmpty() ? QString() : m_messages.constLast().messageId;
}

bool DmMessageListModel::containsMessage(const QString &messageId) const
{
    for (const MessageItem &message : m_messages) {
        if (message.messageId == messageId)
            return true;
    }

    return false;
}

DmMessageListModel::MessageItem DmMessageListModel::messageFromJson(const QJsonObject &object,
                                                                    const QString &currentUserId)
{
    MessageItem message;
    message.messageId = object.value("message_id").toString();
    message.conversationId = object.value("conversation_id").toString();
    message.senderId = object.value("sender_id").toString();
    message.senderUsername = object.value("sender_username").toString();
    message.createdAt = object.value("created_at").toString();
    message.timeLabel = formatTimeLabel(message.createdAt);
    message.isSelf = !currentUserId.isEmpty() && message.senderId == currentUserId;
    message.isDeleted = !object.value("deleted_at").isNull() && !object.value("deleted_at").toString().isEmpty();

    const QString content = object.value("content").toString();
    message.body = content.isEmpty() ? QStringLiteral("Message deleted") : content;

    return message;
}

QString DmMessageListModel::formatTimeLabel(const QString &createdAt)
{
    QDateTime timestamp = QDateTime::fromString(createdAt, Qt::ISODateWithMs);
    if (!timestamp.isValid())
        timestamp = QDateTime::fromString(createdAt, Qt::ISODate);

    if (!timestamp.isValid())
        return {};

    return QLocale().toString(timestamp.toLocalTime().time(), QLocale::ShortFormat);
}
#include "dmMessageListModel.h"

#include <QDateTime>
#include <QJsonObject>
#include <QLocale>
#include <qabstractitemmodel.h>
#include <qlatin1stringview.h>

namespace
{
    constexpr qint64 messageGroupWindowSeconds = 5 * 60;

    QString messageIdFromJson(const QJsonObject &object)
    {
        return object.value(QLatin1String("message_id")).toString();
    }

    QDateTime parseCreatedAt(const QString &createdAt)
    {
        QDateTime timestamp = QDateTime::fromString(createdAt, Qt::ISODateWithMs);
        if (!timestamp.isValid())
            timestamp = QDateTime::fromString(createdAt, Qt::ISODate);

        return timestamp;
    }

    QString formatTimeLabel(const QString &createdAt)
    {
        const QDateTime timestamp = parseCreatedAt(createdAt);

        if (!timestamp.isValid())
            return {};

        return QLocale().toString(timestamp.toLocalTime().time(), QLocale::ShortFormat);
    }
}

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

bool DmMessageListModel::shouldShowSenderInfo(const int row) const
{
    const qsizetype messageCount = m_messages.size();

    if (row < 0 || row >= messageCount || row + 1 >= messageCount)
        return true;

    const MessageItem &message = m_messages.at(row);
    const MessageItem &previousMessage = m_messages.at(row + 1);

    if (message.senderId.isEmpty() || previousMessage.senderId.isEmpty())
        return true;

    if (message.senderId != previousMessage.senderId)
        return true;

    const QDateTime messageTime = parseCreatedAt(message.createdAt);
    const QDateTime previousMessageTime = parseCreatedAt(previousMessage.createdAt);

    if (!messageTime.isValid() || !previousMessageTime.isValid())
        return true;

    const qint64 messageGapSeconds = previousMessageTime.secsTo(messageTime);
    return messageGapSeconds < 0 || messageGapSeconds > messageGroupWindowSeconds;
}

void DmMessageListModel::reset(const QJsonArray &messages, const QString &currentUserId)
{
    beginResetModel();
    m_messages.clear();
    m_messageIds.clear();

    const qsizetype messageCount = messages.size();

    m_messages.reserve(messageCount); 
    m_messageIds.reserve(messageCount);

    for (int index = 0; index < messageCount; ++index) {
        const QJsonValue value = messages.at(index);
        if (!value.isObject())
            continue;

        const QJsonObject object = value.toObject();
        const QString messageId = messageIdFromJson(object);
        if (!shouldInsertMessage(messageId))
            continue;

        m_messages.append(messageFromJson(object, currentUserId));
        m_messageIds.insert(messageId);
    }

    endResetModel();
}

void DmMessageListModel::appendOlderPage(const QJsonArray &messages, const QString &currentUserId)
{
    if (messages.isEmpty())
        return;

    QList<MessageItem> pageItems;
    pageItems.reserve(messages.size());

    constexpr QLatin1String messageIdKey("message_id");

    for (int index = 0; index < messages.size(); ++index) {
        const QJsonValue value = messages.at(index);
        if (!value.isObject())
            continue;

        const QJsonObject obj = value.toObject();
        const QString messageId = messageIdFromJson(obj);
        if (!shouldInsertMessage(messageId))
            continue;

        pageItems.append(messageFromJson(obj, currentUserId));
        m_messageIds.insert(messageId);
    }

    if (pageItems.isEmpty())
        return;

    const qsizetype rowCount = m_messages.size();
    const qsizetype itemCount = pageItems.size();
    beginInsertRows(QModelIndex(), rowCount, rowCount + itemCount - 1);
    
    m_messages.reserve(rowCount + itemCount);

    for (auto &message : pageItems) {
        m_messages.append(std::move(message));
    }

    endInsertRows();
}

void DmMessageListModel::prependMessage(const QJsonObject &message, const QString &currentUserId)
{
    const QString messageId = messageIdFromJson(message);
    if (!shouldInsertMessage(messageId))
        return;

    beginInsertRows(QModelIndex(), 0, 0);
    m_messages.prepend(messageFromJson(message, currentUserId));
    m_messageIds.insert(messageId);
    endInsertRows();
}

void DmMessageListModel::prependMessage(const QVariantMap &message, const QString &currentUserId)
{
    prependMessage(QJsonObject::fromVariantMap(message), currentUserId);
}

void DmMessageListModel::clear()
{
    beginResetModel();
    m_messages.clear();
    m_messageIds.clear();
    endResetModel();
}

QString DmMessageListModel::latestMessageId() const
{
    return m_messages.isEmpty() ? QString() : m_messages.constFirst().messageId;
}

QString DmMessageListModel::oldestMessageId() const
{
    return m_messages.isEmpty() ? QString() : m_messages.constLast().messageId;
}

bool DmMessageListModel::containsMessage(const QString &messageId) const noexcept
{
    return m_messageIds.contains(messageId);
}

bool DmMessageListModel::shouldInsertMessage(const QString &messageId) const noexcept
{
    return !messageId.isEmpty() && !containsMessage(messageId);
}

DmMessageListModel::MessageItem DmMessageListModel::messageFromJson(const QJsonObject &object,
                                                                    const QString &currentUserId)
{
    MessageItem message;
    message.messageId      = object.value(QLatin1String("message_id")).toString();
    message.conversationId = object.value(QLatin1String("conversation_id")).toString();
    message.senderId       = object.value(QLatin1String("sender_id")).toString();
    message.senderUsername = object.value(QLatin1String("sender_username")).toString();
    message.createdAt      = object.value(QLatin1String("created_at")).toString();
    message.timeLabel = formatTimeLabel(message.createdAt);
    message.isSelf = !currentUserId.isEmpty() && message.senderId == currentUserId;
    constexpr QLatin1String deletedAtKey = QLatin1String("deleted_at");
    message.isDeleted = !object.value(deletedAtKey).isNull() && !object.value(deletedAtKey).toString().isEmpty();

    const QString content = object.value(QLatin1String("content")).toString();
    message.body = message.isDeleted || content.isEmpty()
        ? QStringLiteral("Message deleted")
        : content;

    return message;
}
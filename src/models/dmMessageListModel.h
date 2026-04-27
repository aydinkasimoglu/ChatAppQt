#ifndef DMMESSAGELISTMODEL_H
#define DMMESSAGELISTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonObject>
#include <QSet>
#include <QVariantMap>
#include <qqmlintegration.h>

class DmMessageListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        MessageIdRole = Qt::UserRole + 1,
        ConversationIdRole,
        SenderIdRole,
        SenderUsernameRole,
        BodyRole,
        TimeLabelRole,
        CreatedAtRole,
        IsSelfRole,
        IsDeletedRole,
    };

    explicit DmMessageListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QString bodyAt(int row) const;
    Q_INVOKABLE bool shouldShowSenderInfo(int row) const;

    void reset(const QJsonArray &messages, const QString &currentUserId);
    void appendOlderPage(const QJsonArray &messages, const QString &currentUserId);
    void prependMessage(const QJsonObject &message, const QString &currentUserId);
    void prependMessage(const QVariantMap &message, const QString &currentUserId);
    void clear();

    QString latestMessageId() const;
    QString oldestMessageId() const;
    bool containsMessage(const QString &messageId) const noexcept;

signals:
    void countChanged();

private:
    struct MessageItem {
        QString messageId;
        QString conversationId;
        QString senderId;
        QString senderUsername;
        QString body;
        QString timeLabel;
        QString createdAt;
        bool isSelf = false;
        bool isDeleted = false;
    };

    bool shouldInsertMessage(const QString &messageId) const noexcept;
    static MessageItem messageFromJson(const QJsonObject &object, const QString &currentUserId);

    QList<MessageItem> m_messages;
    QSet<QString> m_messageIds;
};

#endif // DMMESSAGELISTMODEL_H
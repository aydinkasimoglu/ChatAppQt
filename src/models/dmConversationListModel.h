#ifndef DMCONVERSATIONLISTMODEL_H
#define DMCONVERSATIONLISTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonObject>
#include <QVariantMap>
#include <qqmlintegration.h>

class DmConversationListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        ConversationIdRole = Qt::UserRole + 1,
        KindRole,
        DisplayTitleRole,
        DirectPartnerIdRole,
        ParticipantCountRole,
        UnreadCountRole,
        HasUnreadRole,
        LastMessagePreviewRole,
        LastActivityAtRole,
    };

    explicit DmConversationListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void reset(const QJsonArray &conversations, const QString &currentUserId);
    void clear();

    bool containsConversation(const QString &conversationId) const;
    QVariantMap conversationById(const QString &conversationId) const;
    QString conversationIdForDirectPartner(const QString &directPartnerId) const;

signals:
    void countChanged();

private:
    struct ConversationItem {
        QString conversationId;
        QString kind;
        QString displayTitle;
        QString directPartnerId;
        int participantCount = 0;
        int unreadCount = 0;
        QString lastMessagePreview;
        QString lastActivityAt;
    };

    static ConversationItem conversationFromJson(const QJsonObject &object,
                                                 const QString &currentUserId);
    static QVariantMap toVariantMap(const ConversationItem &conversation);

    QList<ConversationItem> m_conversations;
};

#endif // DMCONVERSATIONLISTMODEL_H
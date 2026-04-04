#ifndef FRIENDLISTMODEL_H
#define FRIENDLISTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QSet>
#include <qqmlintegration.h>

// ── FriendListModel ───────────────────────────────────────────────────────────
// Roles: friendshipId, userId, username, email, friendsSince, isOnline

class FriendListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count       READ rowCount   NOTIFY countChanged)
    Q_PROPERTY(int onlineCount READ onlineCount NOTIFY onlineCountChanged)

public:
    enum Roles {
        FriendshipIdRole = Qt::UserRole + 1,
        UserIdRole,
        UsernameRole,
        EmailRole,
        FriendsSinceRole,
        IsOnlineRole,
    };

    explicit FriendListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void reset(const QJsonArray &friends);
    void removeFriend(const QString &friendshipId);

    void setOnlineUsers(const QSet<QString> &onlineUserIds);
    Q_INVOKABLE void setOnlineUsersList(const QStringList &onlineUserIds);
    Q_INVOKABLE void setUserOnline(const QString &userId, bool online);
    int onlineCount() const { return m_onlineCount; }

signals:
    void countChanged();
    void onlineCountChanged();

private:
    void recalcOnlineCount();

    QList<QVariantMap> m_friends;
    QSet<QString> m_onlineUsers;
    int m_onlineCount = 0;
};

#endif // FRIENDLISTMODEL_H

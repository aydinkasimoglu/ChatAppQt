#ifndef PENDINGREQUESTMODEL_H
#define PENDINGREQUESTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <qqmlintegration.h>

// ── PendingRequestModel ───────────────────────────────────────────────────────
// Roles: friendshipId, userId, username, email, direction ("incoming"|"outgoing"), createdAt

class PendingRequestModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        FriendshipIdRole = Qt::UserRole + 1,
        UserIdRole,
        UsernameRole,
        EmailRole,
        DirectionRole,
        CreatedAtRole,
    };

    explicit PendingRequestModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void resetFromBoth(const QJsonArray &incoming, const QJsonArray &outgoing);
    void removeRequest(const QString &friendshipId);

signals:
    void countChanged();

private:
    QList<QVariantMap> m_requests;
};

#endif // PENDINGREQUESTMODEL_H

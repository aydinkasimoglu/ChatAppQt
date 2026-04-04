#ifndef SERVERLISTMODEL_H
#define SERVERLISTMODEL_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QAbstractListModel>
#include <qqmlintegration.h>

// ── ServerListModel ───────────────────────────────────────────────────────────
// A list model exposing server objects to QML.
// Roles: serverId, ownerId, name, description, isPublic

class ServerListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

public:
    enum Roles {
        ServerIdRole = Qt::UserRole + 1,
        OwnerIdRole,
        NameRole,
        DescriptionRole,
        IsPublicRole,
    };

    explicit ServerListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void reset(const QJsonArray &servers);
    void appendServer(const QJsonObject &server);
    void removeServer(const QString &serverId);
    void updateServer(const QJsonObject &server);

private:
    QList<QVariantMap> m_servers;
};

#endif // SERVERLISTMODEL_H
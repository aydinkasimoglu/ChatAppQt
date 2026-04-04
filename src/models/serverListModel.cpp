#include "serverListModel.h"

// ── ServerListModel ───────────────────────────────────────────────────────────

ServerListModel::ServerListModel(QObject *parent) : QAbstractListModel(parent) {}

int ServerListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_servers.count();
}

QVariant ServerListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_servers.count())
        return {};

    const QVariantMap &server = m_servers.at(index.row());
    switch (role) {
    case ServerIdRole:    return server.value("serverId");
    case OwnerIdRole:     return server.value("ownerId");
    case NameRole:        return server.value("name");
    case DescriptionRole: return server.value("description");
    case IsPublicRole:    return server.value("isPublic");
    default:              return {};
    }
}

QHash<int, QByteArray> ServerListModel::roleNames() const
{
    return {
        { ServerIdRole,    "serverId"    },
        { OwnerIdRole,     "ownerId"     },
        { NameRole,        "name"        },
        { DescriptionRole, "description" },
        { IsPublicRole,    "isPublic"    },
    };
}

static QVariantMap serverFromJson(const QJsonObject &obj)
{
    return {
        { "serverId",    obj.value("server_id").toString()   },
        { "ownerId",     obj.value("owner_id").toString()    },
        { "name",        obj.value("name").toString()        },
        { "description", obj.value("description").toString() },
        { "isPublic",    obj.value("is_public").toBool()     },
    };
}

void ServerListModel::reset(const QJsonArray &servers)
{
    beginResetModel();
    m_servers.clear();
    for (const QJsonValue &val : servers)
        m_servers.append(serverFromJson(val.toObject()));
    endResetModel();
}

void ServerListModel::appendServer(const QJsonObject &obj)
{
    beginInsertRows({}, m_servers.count(), m_servers.count());
    m_servers.append(serverFromJson(obj));
    endInsertRows();
}

void ServerListModel::removeServer(const QString &serverId)
{
    for (int i = 0; i < m_servers.count(); ++i) {
        if (m_servers.at(i).value("serverId").toString() == serverId) {
            beginRemoveRows({}, i, i);
            m_servers.removeAt(i);
            endRemoveRows();
            return;
        }
    }
}

void ServerListModel::updateServer(const QJsonObject &obj)
{
    const QString id = obj.value("server_id").toString();
    for (int i = 0; i < m_servers.count(); ++i) {
        if (m_servers.at(i).value("serverId").toString() == id) {
            m_servers[i] = serverFromJson(obj);
            const QModelIndex idx = index(i);
            emit dataChanged(idx, idx);
            return;
        }
    }
}
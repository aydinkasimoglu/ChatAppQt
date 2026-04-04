#include "pendingRequestModel.h"

#include <QJsonObject>

PendingRequestModel::PendingRequestModel(QObject *parent) : QAbstractListModel(parent)
{
    connect(this, &QAbstractListModel::rowsInserted, this, &PendingRequestModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved,  this, &PendingRequestModel::countChanged);
    connect(this, &QAbstractListModel::modelReset,   this, &PendingRequestModel::countChanged);
}

int PendingRequestModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_requests.count();
}

QVariant PendingRequestModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_requests.count())
        return {};

    const QVariantMap &r = m_requests.at(index.row());
    switch (role) {
    case FriendshipIdRole: return r.value("friendshipId");
    case UserIdRole:       return r.value("userId");
    case UsernameRole:     return r.value("username");
    case EmailRole:        return r.value("email");
    case DirectionRole:    return r.value("direction");
    case CreatedAtRole:    return r.value("createdAt");
    default:               return {};
    }
}

QHash<int, QByteArray> PendingRequestModel::roleNames() const
{
    return {
        { FriendshipIdRole, "friendshipId" },
        { UserIdRole,       "userId"       },
        { UsernameRole,     "username"     },
        { EmailRole,        "email"        },
        { DirectionRole,    "direction"    },
        { CreatedAtRole,    "createdAt"    },
    };
}

static QVariantMap pendingFromJson(const QJsonObject &obj, const QString &direction)
{
    return {
        { "friendshipId", obj.value("friendship_id").toString() },
        { "userId",       obj.value("user_id").toString()       },
        { "username",     obj.value("username").toString()      },
        { "email",        obj.value("email").toString()         },
        { "direction",    direction                             },
        { "createdAt",    obj.value("created_at").toString()    },
    };
}

void PendingRequestModel::resetFromBoth(const QJsonArray &incoming, const QJsonArray &outgoing)
{
    beginResetModel();
    m_requests.clear();
    for (const QJsonValue &val : incoming)
        m_requests.append(pendingFromJson(val.toObject(), QStringLiteral("incoming")));
    for (const QJsonValue &val : outgoing)
        m_requests.append(pendingFromJson(val.toObject(), QStringLiteral("outgoing")));
    endResetModel();
}

void PendingRequestModel::removeRequest(const QString &friendshipId)
{
    for (int i = 0; i < m_requests.count(); ++i) {
        if (m_requests.at(i).value("friendshipId").toString() == friendshipId) {
            beginRemoveRows({}, i, i);
            m_requests.removeAt(i);
            endRemoveRows();
            return;
        }
    }
}

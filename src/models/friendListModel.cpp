#include "friendListModel.h"

#include <QJsonObject>

FriendListModel::FriendListModel(QObject *parent) : QAbstractListModel(parent)
{
    connect(this, &QAbstractListModel::rowsInserted, this, &FriendListModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved,  this, &FriendListModel::countChanged);
    connect(this, &QAbstractListModel::modelReset,   this, &FriendListModel::countChanged);
}

int FriendListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_friends.count();
}

QVariant FriendListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_friends.count())
        return {};

    const QVariantMap &f = m_friends.at(index.row());
    switch (role) {
    case FriendshipIdRole: return f.value("friendshipId");
    case UserIdRole:       return f.value("userId");
    case UsernameRole:     return f.value("username");
    case EmailRole:        return f.value("email");
    case FriendsSinceRole: return f.value("friendsSince");
    case IsOnlineRole:     return m_onlineUsers.contains(f.value("userId").toString());
    default:               return {};
    }
}

QHash<int, QByteArray> FriendListModel::roleNames() const
{
    return {
        { FriendshipIdRole, "friendshipId" },
        { UserIdRole,       "userId"       },
        { UsernameRole,     "username"     },
        { EmailRole,        "email"        },
        { FriendsSinceRole, "friendsSince" },
        { IsOnlineRole,     "isOnline"     },
    };
}

static QVariantMap friendFromJson(const QJsonObject &obj)
{
    return {
        { "friendshipId", obj.value("friendship_id").toString() },
        { "userId",       obj.value("user_id").toString()       },
        { "username",     obj.value("username").toString()      },
        { "email",        obj.value("email").toString()         },
        { "friendsSince", obj.value("friends_since").toString() },
    };
}

void FriendListModel::reset(const QJsonArray &friends)
{
    beginResetModel();
    m_friends.clear();
    for (const QJsonValue &val : friends)
        m_friends.append(friendFromJson(val.toObject()));
    endResetModel();
}

void FriendListModel::removeFriend(const QString &friendshipId)
{
    for (int i = 0; i < m_friends.count(); ++i) {
        if (m_friends.at(i).value("friendshipId").toString() == friendshipId) {
            beginRemoveRows({}, i, i);
            m_friends.removeAt(i);
            endRemoveRows();
            recalcOnlineCount();
            return;
        }
    }
}

void FriendListModel::setOnlineUsers(const QSet<QString> &onlineUserIds)
{
    m_onlineUsers = onlineUserIds;
    if (!m_friends.isEmpty())
        emit dataChanged(index(0), index(m_friends.count() - 1), { IsOnlineRole });
    recalcOnlineCount();
}

void FriendListModel::setOnlineUsersList(const QStringList &onlineUserIds)
{
    setOnlineUsers(QSet<QString>(onlineUserIds.begin(), onlineUserIds.end()));
}

void FriendListModel::setUserOnline(const QString &userId, bool online)
{
    if (online)
        m_onlineUsers.insert(userId);
    else
        m_onlineUsers.remove(userId);

    for (int i = 0; i < m_friends.count(); ++i) {
        if (m_friends.at(i).value("userId").toString() == userId) {
            emit dataChanged(index(i), index(i), { IsOnlineRole });
            break;
        }
    }
    recalcOnlineCount();
}

void FriendListModel::recalcOnlineCount()
{
    int count = 0;
    for (const auto &f : m_friends) {
        if (m_onlineUsers.contains(f.value("userId").toString()))
            ++count;
    }
    if (count != m_onlineCount) {
        m_onlineCount = count;
        emit onlineCountChanged();
    }
}

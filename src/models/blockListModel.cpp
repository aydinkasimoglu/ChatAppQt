#include "blockListModel.h"

#include <QJsonObject>

BlockListModel::BlockListModel(QObject *parent) : QAbstractListModel(parent)
{
    connect(this, &QAbstractListModel::rowsInserted, this, &BlockListModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved,  this, &BlockListModel::countChanged);
    connect(this, &QAbstractListModel::modelReset,   this, &BlockListModel::countChanged);
}

int BlockListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_blocks.count();
}

QVariant BlockListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_blocks.count())
        return {};

    const QVariantMap &b = m_blocks.at(index.row());
    switch (role) {
    case BlockIdRole:   return b.value("blockId");
    case UserIdRole:    return b.value("userId");
    case UsernameRole:  return b.value("username");
    case EmailRole:     return b.value("email");
    case CreatedAtRole: return b.value("createdAt");
    default:            return {};
    }
}

QHash<int, QByteArray> BlockListModel::roleNames() const
{
    return {
        { BlockIdRole,   "blockId"   },
        { UserIdRole,    "userId"    },
        { UsernameRole,  "username"  },
        { EmailRole,     "email"     },
        { CreatedAtRole, "createdAt" },
    };
}

static QVariantMap blockFromJson(const QJsonObject &obj)
{
    return {
        { "blockId",   obj.value("block_id").toString()         },
        { "userId",    obj.value("blocked_user_id").toString()  },
        { "username",  obj.value("blocked_username").toString() },
        { "email",     obj.value("blocked_email").toString()    },
        { "createdAt", obj.value("created_at").toString()       },
    };
}

void BlockListModel::reset(const QJsonArray &blocks)
{
    beginResetModel();
    m_blocks.clear();
    for (const QJsonValue &val : blocks)
        m_blocks.append(blockFromJson(val.toObject()));
    endResetModel();
}

void BlockListModel::removeBlock(const QString &userId)
{
    for (int i = 0; i < m_blocks.count(); ++i) {
        if (m_blocks.at(i).value("userId").toString() == userId) {
            beginRemoveRows({}, i, i);
            m_blocks.removeAt(i);
            endRemoveRows();
            return;
        }
    }
}

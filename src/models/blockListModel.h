#ifndef BLOCKLISTMODEL_H
#define BLOCKLISTMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <qqmlintegration.h>

// ── BlockListModel ────────────────────────────────────────────────────────────
// Roles: blockId, userId, username, email, createdAt

class BlockListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        BlockIdRole = Qt::UserRole + 1,
        UserIdRole,
        UsernameRole,
        EmailRole,
        CreatedAtRole,
    };

    explicit BlockListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void reset(const QJsonArray &blocks);
    void removeBlock(const QString &userId);

signals:
    void countChanged();

private:
    QList<QVariantMap> m_blocks;
};

#endif // BLOCKLISTMODEL_H

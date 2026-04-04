#ifndef SERVERMANAGER_H
#define SERVERMANAGER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QJSEngine>
#include <QQmlEngine>
#include <qqmlintegration.h>

#include "networkClient.h"
#include "serverListModel.h"

class ServerManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(ServerListModel* myServers    READ myServers    CONSTANT)
    Q_PROPERTY(ServerListModel* publicServers READ publicServers CONSTANT)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit ServerManager(QObject *parent = nullptr);

    static ServerManager *create(QQmlEngine *, QJSEngine *) { return new ServerManager(); }

    ServerListModel *myServers()     { return &m_myServers; }
    ServerListModel *publicServers() { return &m_publicServers; }
    bool loading() const             { return m_loading; }

    Q_INVOKABLE void fetchMyServers();
    Q_INVOKABLE void fetchPublicServers();
    Q_INVOKABLE void createServer(const QString &name, bool isPublic,
                                  const QString &description = QString());
    Q_INVOKABLE void updateServer(const QString &serverId, const QString &name,
                                  bool isPublic, const QString &description = QString());
    Q_INVOKABLE void deleteServer(const QString &serverId);

signals:
    void loadingChanged();

    void serverCreated();
    void serverCreateFailed(QString message);

    void serverUpdated();
    void serverUpdateFailed(QString message);

    void serverDeleted(QString serverId);
    void serverDeleteFailed(QString message);

private:
    NetworkClient m_networkClient;
    ServerListModel m_myServers;
    ServerListModel m_publicServers;
    bool m_loading = false;

    void setLoading(bool loading);
};

#endif // SERVERMANAGER_H
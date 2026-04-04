#include "serverManager.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>

ServerManager::ServerManager(QObject *parent) : QObject(parent) {}

void ServerManager::setLoading(bool loading)
{
    if (m_loading == loading) return;
    m_loading = loading;
    emit loadingChanged();
}

void ServerManager::fetchMyServers()
{
    setLoading(true);
    QNetworkReply *reply = m_networkClient.get("/servers/mine", true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setLoading(false);

        const JsonArrayResponse response = m_networkClient.jsonResponse<QJsonArray>(reply);
        if (!response.ok) {
            if (response.networkError != QNetworkReply::NoError) {
                qDebug() << "[ServerManager] fetchMyServers network error:"
                         << response.networkError << response.errorMessage;
            } else {
                qDebug() << "[ServerManager] fetchMyServers parse error:" << response.errorMessage;
            }
            return;
        }

        qDebug() << "[ServerManager] fetchMyServers: received" << response.data.size() << "servers";
        m_myServers.reset(response.data);
    });
}

void ServerManager::fetchPublicServers()
{
    setLoading(true);
    QNetworkReply *reply = m_networkClient.get("/servers/public");
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setLoading(false);

        const JsonArrayResponse response = m_networkClient.jsonResponse<QJsonArray>(reply);
        if (!response.ok) return;

        m_publicServers.reset(response.data);
    });
}

void ServerManager::createServer(const QString &name, bool isPublic, const QString &description)
{
    QJsonObject body;
    body["name"]      = name;
    body["is_public"] = isPublic;
    if (!description.isEmpty())
        body["description"] = description;

    QNetworkReply *reply = m_networkClient.post("/servers", body, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        const JsonObjectResponse response = m_networkClient.jsonResponse<QJsonObject>(reply);
        if (!response.ok) {
            emit serverCreateFailed(response.errorMessage);
            return;
        }

        m_myServers.appendServer(response.data);
        emit serverCreated();
    });
}

void ServerManager::updateServer(const QString &serverId, const QString &name,
                                  bool isPublic, const QString &description)
{
    QJsonObject body;
    if (!name.isEmpty())
        body["name"] = name;
    body["is_public"] = isPublic;
    if (!description.isEmpty())
        body["description"] = description;

    QNetworkReply *reply = m_networkClient.put("/servers/" + serverId, body, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        const JsonObjectResponse response = m_networkClient.jsonResponse<QJsonObject>(reply);
        if (!response.ok) {
            emit serverUpdateFailed(response.errorMessage);
            return;
        }

        m_myServers.updateServer(response.data);
        emit serverUpdated();
    });
}

void ServerManager::deleteServer(const QString &serverId)
{
    QNetworkReply *reply = m_networkClient.deleteResource("/servers/" + serverId, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, serverId]() {
        reply->deleteLater();

        const NetworkResponse response = m_networkClient.response(reply);
        if (!response.ok) {
            emit serverDeleteFailed(response.errorMessage);
            return;
        }

        m_myServers.removeServer(serverId);
        emit serverDeleted(serverId);
    });
}


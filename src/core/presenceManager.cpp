#include "presenceManager.h"
#include "networkClient.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

static const QString WS_BASE_URL = QStringLiteral("ws://localhost:3000/ws");

PresenceManager::PresenceManager(QObject *parent)
    : QObject(parent)
{
    connect(&m_socket, &QWebSocket::connected,
            this, &PresenceManager::onWsConnected);
    connect(&m_socket, &QWebSocket::disconnected,
            this, &PresenceManager::onWsDisconnected);
    connect(&m_socket, &QWebSocket::textMessageReceived,
            this, &PresenceManager::onWsTextMessage);
    connect(&m_socket, &QWebSocket::errorOccurred,
            this, &PresenceManager::onWsError);

    m_heartbeatTimer.setInterval(HeartbeatIntervalMs);
    connect(&m_heartbeatTimer, &QTimer::timeout,
            this, &PresenceManager::sendHeartbeat);

    m_reconnectTimer.setSingleShot(true);
    connect(&m_reconnectTimer, &QTimer::timeout,
            this, &PresenceManager::attemptReconnect);
}

void PresenceManager::connectToServer()
{
    if (m_socket.state() == QAbstractSocket::ConnectedState
        || m_socket.state() == QAbstractSocket::ConnectingState)
        return;

    m_intentionalClose = false;

    const QString &token = NetworkClient::accessToken();
    if (token.isEmpty()) {
        qWarning() << "[PresenceManager] No access token, cannot connect";
        return;
    }

    QNetworkRequest request(QUrl(WS_BASE_URL + "/presence"));
    request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    m_socket.open(request);
}

void PresenceManager::disconnectFromServer()
{
    m_intentionalClose = true;
    m_heartbeatTimer.stop();
    m_reconnectTimer.stop();

    if (m_socket.state() != QAbstractSocket::UnconnectedState)
        m_socket.close();

    if (!m_onlineUsers.isEmpty()) {
        m_onlineUsers.clear();
        emit onlineUsersChanged();
    }

    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

bool PresenceManager::isUserOnline(const QString &userId) const
{
    return m_onlineUsers.contains(userId);
}

QStringList PresenceManager::onlineUserIds() const
{
    return QStringList(m_onlineUsers.begin(), m_onlineUsers.end());
}

// ── WebSocket slots ──────────────────────────────────────────────────────────

void PresenceManager::onWsConnected()
{
    qDebug() << "[PresenceManager] WebSocket connected";
    m_connected = true;
    resetReconnectBackoff();
    m_heartbeatTimer.start();
    emit connectedChanged();
}

void PresenceManager::onWsDisconnected()
{
    qDebug() << "[PresenceManager] WebSocket disconnected";
    m_heartbeatTimer.stop();

    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }

    if (!m_onlineUsers.isEmpty()) {
        m_onlineUsers.clear();
        emit onlineUsersChanged();
    }

    if (!m_intentionalClose)
        m_reconnectTimer.start(m_reconnectDelay);
}

void PresenceManager::onWsError(QAbstractSocket::SocketError error)
{
    qWarning() << "[PresenceManager] WebSocket error:" << error << m_socket.errorString();
}

void PresenceManager::onWsTextMessage(const QString &message)
{
    const QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    if (!doc.isObject())
        return;

    const QJsonObject obj = doc.object();
    const QString type = obj.value("type").toString();

    if (type == "online_friends") {
        handleOnlineFriends(obj.value("friends").toArray());
    } else if (type == "presence_update") {
        handlePresenceUpdate(
            obj.value("user_id").toString(),
            obj.value("username").toString(),
            obj.value("status").toString());
    }
}

void PresenceManager::sendHeartbeat()
{
    if (m_socket.state() != QAbstractSocket::ConnectedState)
        return;

    static const QByteArray heartbeat =
        QJsonDocument(QJsonObject{{"type", "heartbeat"}, {"status", "online"}}).toJson(QJsonDocument::Compact);
    m_socket.sendTextMessage(QString::fromUtf8(heartbeat));
}

void PresenceManager::attemptReconnect()
{
    qDebug() << "[PresenceManager] Reconnecting (delay:" << m_reconnectDelay << "ms)";
    m_reconnectDelay = qMin(m_reconnectDelay * 2, MaxReconnectDelayMs);
    connectToServer();
}

// ── Message handlers ─────────────────────────────────────────────────────────

void PresenceManager::handleOnlineFriends(const QJsonArray &friends)
{
    m_onlineUsers.clear();
    for (const QJsonValue &val : friends) {
        const QString userId = val.toObject().value("user_id").toString();
        if (!userId.isEmpty())
            m_onlineUsers.insert(userId);
    }
    emit onlineUsersChanged();
}

void PresenceManager::handlePresenceUpdate(const QString &userId, const QString &username,
                                           const QString &status)
{
    Q_UNUSED(username)

    if (status == "online" || status == "idle") {
        if (!m_onlineUsers.contains(userId)) {
            m_onlineUsers.insert(userId);
            emit userWentOnline(userId);
            emit onlineUsersChanged();
        }
    } else {
        if (m_onlineUsers.remove(userId)) {
            emit userWentOffline(userId);
            emit onlineUsersChanged();
        }
    }
}

void PresenceManager::resetReconnectBackoff()
{
    m_reconnectDelay = 1000;
}

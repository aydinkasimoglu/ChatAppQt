#ifndef PRESENCEMANAGER_H
#define PRESENCEMANAGER_H

#include <QObject>
#include <QWebSocket>
#include <QTimer>
#include <QSet>
#include <QJsonArray>
#include <QJSEngine>
#include <QQmlEngine>
#include <qqmlintegration.h>

class FriendListModel;

class PresenceManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
    explicit PresenceManager(QObject *parent = nullptr);

    static PresenceManager *create(QQmlEngine *, QJSEngine *) { return new PresenceManager(); }

    bool isConnected() const { return m_connected; }

    Q_INVOKABLE void connectToServer();
    Q_INVOKABLE void disconnectFromServer();
    Q_INVOKABLE bool isUserOnline(const QString &userId) const;
    Q_INVOKABLE QStringList onlineUserIds() const;

signals:
    void connectedChanged();
    void userWentOnline(const QString &userId);
    void userWentOffline(const QString &userId);
    void onlineUsersChanged();

private slots:
    void onWsConnected();
    void onWsDisconnected();
    void onWsTextMessage(const QString &message);
    void onWsError(QAbstractSocket::SocketError error);
    void sendHeartbeat();
    void attemptReconnect();

private:
    void handleOnlineFriends(const QJsonArray &friends);
    void handlePresenceUpdate(const QString &userId, const QString &username, const QString &status);
    void resetReconnectBackoff();

    QWebSocket m_socket;
    QTimer     m_heartbeatTimer;
    QTimer     m_reconnectTimer;

    QSet<QString> m_onlineUsers;
    bool m_connected       = false;
    bool m_intentionalClose = false;
    int  m_reconnectDelay  = 1000;

    static constexpr int HeartbeatIntervalMs  = 20000;
    static constexpr int MaxReconnectDelayMs  = 30000;
};

#endif // PRESENCEMANAGER_H

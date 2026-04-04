#ifndef FRIENDSHIPMANAGER_H
#define FRIENDSHIPMANAGER_H

#include "networkClient.h"
#include "friendListModel.h"
#include "pendingRequestModel.h"
#include "blockListModel.h"
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <qqmlintegration.h>

class FriendshipManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(FriendListModel     *friends         READ friends         CONSTANT)
    Q_PROPERTY(PendingRequestModel *pendingRequests READ pendingRequests CONSTANT)
    Q_PROPERTY(BlockListModel      *blockedUsers    READ blockedUsers    CONSTANT)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit FriendshipManager(QObject *parent = nullptr);

    static FriendshipManager *create(QQmlEngine *, QJSEngine *) { return new FriendshipManager(); }

    FriendListModel     *friends()         { return &m_friends; }
    PendingRequestModel *pendingRequests() { return &m_pendingRequests; }
    BlockListModel      *blockedUsers()    { return &m_blockedUsers; }
    bool loading() const                   { return m_loading; }

    Q_INVOKABLE void fetchFriends();
    Q_INVOKABLE void fetchPendingRequests();
    Q_INVOKABLE void fetchBlockedUsers();
    Q_INVOKABLE void sendFriendRequest(const QString &username);
    Q_INVOKABLE void acceptRequest(const QString &friendshipId);
    Q_INVOKABLE void rejectRequest(const QString &friendshipId);
    Q_INVOKABLE void cancelRequest(const QString &friendshipId);
    Q_INVOKABLE void removeFriend(const QString &friendshipId);
    Q_INVOKABLE void unblockUser(const QString &userId);

signals:
    void loadingChanged();

    void friendRequestSent();
    void friendRequestFailed(QString message);

    void requestAccepted();
    void requestAcceptFailed(QString message);

    void requestRejected();
    void requestRejectFailed(QString message);

    void requestCancelled();
    void requestCancelFailed(QString message);

    void friendRemoved();
    void friendRemoveFailed(QString message);

    void userUnblocked();
    void unblockFailed(QString message);

private:
    NetworkClient       m_networkClient;
    FriendListModel     m_friends;
    PendingRequestModel m_pendingRequests;
    BlockListModel      m_blockedUsers;
    bool m_loading    = false;
    int  m_activeLoads = 0;

    void beginLoad();
    void endLoad();
};

#endif // FRIENDSHIPMANAGER_H
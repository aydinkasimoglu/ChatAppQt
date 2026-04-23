#include "friendshipManager.h"
#include <QNetworkReply>
#include <memory>

FriendshipManager::FriendshipManager(QObject *parent) : QObject(parent) {}

void FriendshipManager::beginLoad()
{
    if (m_activeLoads++ == 0) {
        m_loading = true;
        emit loadingChanged();
    }
}

void FriendshipManager::endLoad()
{
    if (--m_activeLoads == 0) {
        m_loading = false;
        emit loadingChanged();
    }
}

void FriendshipManager::fetchFriends()
{
    beginLoad();
    QNetworkReply *reply = NetworkClient::instance().get("/friends", true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        endLoad();

        const JsonArrayResponse r = NetworkClient::instance().jsonResponse<QJsonArray>(reply);
        if (!r.ok) {
            qDebug() << "[FriendshipManager] fetchFriends failed:" << r.errorMessage;
            return;
        }

        m_friends.reset(r.data);
    });
}

void FriendshipManager::fetchPendingRequests()
{
    struct State { QJsonArray incoming, outgoing; int done = 0; };
    auto s = std::make_shared<State>();

    beginLoad();

    QNetworkReply *inReply = NetworkClient::instance().get("/friends/requests/incoming", true);
    connect(inReply, &QNetworkReply::finished, this, [this, inReply, s]() {
        inReply->deleteLater();
        const JsonArrayResponse r = NetworkClient::instance().jsonResponse<QJsonArray>(inReply);
        if (r.ok)
            s->incoming = r.data;
        else
            qDebug() << "[FriendshipManager] fetchIncomingRequests failed:" << r.errorMessage;
        if (++s->done == 2) {
            endLoad();
            m_pendingRequests.resetFromBoth(s->incoming, s->outgoing);
        }
    });

    QNetworkReply *outReply = NetworkClient::instance().get("/friends/requests/outgoing", true);
    connect(outReply, &QNetworkReply::finished, this, [this, outReply, s]() {
        outReply->deleteLater();
        const JsonArrayResponse r = NetworkClient::instance().jsonResponse<QJsonArray>(outReply);
        if (r.ok)
            s->outgoing = r.data;
        else
            qDebug() << "[FriendshipManager] fetchOutgoingRequests failed:" << r.errorMessage;
        if (++s->done == 2) {
            endLoad();
            m_pendingRequests.resetFromBoth(s->incoming, s->outgoing);
        }
    });
}

void FriendshipManager::sendFriendRequest(const QString &username)
{
    QJsonObject body;
    body["username"] = username;

    QNetworkReply *reply = NetworkClient::instance().post("/friends/requests", body, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        const JsonObjectResponse r = NetworkClient::instance().jsonResponse<QJsonObject>(reply);
        if (!r.ok) {
            emit friendRequestFailed(r.errorMessage);
            return;
        }

        emit friendRequestSent();
    });
}

void FriendshipManager::acceptRequest(const QString &friendshipId)
{
    QNetworkReply *reply = NetworkClient::instance().put(
        "/friends/requests/" + friendshipId + "/accept", {}, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, friendshipId]() {
        reply->deleteLater();

        const JsonObjectResponse r = NetworkClient::instance().jsonResponse<QJsonObject>(reply);
        if (!r.ok) {
            emit requestAcceptFailed(r.errorMessage);
            return;
        }

        m_pendingRequests.removeRequest(friendshipId);
        emit requestAccepted();
        fetchFriends();
    });
}

void FriendshipManager::rejectRequest(const QString &friendshipId)
{
    QNetworkReply *reply = NetworkClient::instance().put(
        "/friends/requests/" + friendshipId + "/reject", {}, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, friendshipId]() {
        reply->deleteLater();

        const JsonObjectResponse r = NetworkClient::instance().jsonResponse<QJsonObject>(reply);
        if (!r.ok) {
            emit requestRejectFailed(r.errorMessage);
            return;
        }

        m_pendingRequests.removeRequest(friendshipId);
        emit requestRejected();
    });
}

void FriendshipManager::cancelRequest(const QString &friendshipId)
{
    QNetworkReply *reply = NetworkClient::instance().deleteResource(
        "/friends/requests/" + friendshipId + "/cancel", true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, friendshipId]() {
        reply->deleteLater();

        const NetworkResponse r = NetworkClient::instance().response(reply);
        if (!r.ok) {
            emit requestCancelFailed(r.errorMessage);
            return;
        }

        m_pendingRequests.removeRequest(friendshipId);
        emit requestCancelled();
    });
}

void FriendshipManager::removeFriend(const QString &friendshipId)
{
    QNetworkReply *reply = NetworkClient::instance().deleteResource("/friends/" + friendshipId, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, friendshipId]() {
        reply->deleteLater();

        const NetworkResponse r = NetworkClient::instance().response(reply);
        if (!r.ok) {
            emit friendRemoveFailed(r.errorMessage);
            return;
        }

        m_friends.removeFriend(friendshipId);
        emit friendRemoved();
    });
}

void FriendshipManager::fetchBlockedUsers()
{
    beginLoad();
    QNetworkReply *reply = NetworkClient::instance().get("/blocks", true);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        endLoad();

        const JsonArrayResponse r = NetworkClient::instance().jsonResponse<QJsonArray>(reply);
        if (!r.ok) {
            qDebug() << "[FriendshipManager] fetchBlockedUsers failed:" << r.errorMessage;
            return;
        }

        m_blockedUsers.reset(r.data);
    });
}

void FriendshipManager::unblockUser(const QString &userId)
{
    QNetworkReply *reply = NetworkClient::instance().deleteResource("/blocks/" + userId, true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, userId]() {
        reply->deleteLater();

        const NetworkResponse r = NetworkClient::instance().response(reply);
        if (!r.ok) {
            emit unblockFailed(r.errorMessage);
            return;
        }

        m_blockedUsers.removeBlock(userId);
        emit userUnblocked();
    });
}
#include "networkClient.h"

#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

static const QString BASE_URL = QStringLiteral("http://localhost:3000");

QString NetworkClient::defaultInvalidJsonMessage(const QString &invalidMessage)
{
    return invalidMessage.isEmpty() ? QStringLiteral("Invalid server response") : invalidMessage;
}

NetworkClient::NetworkClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{}

QNetworkReply *NetworkClient::get(const QString &path, bool withAuth)
{
    return m_networkManager->get(makeRequest(path, withAuth));
}

QNetworkReply *NetworkClient::post(const QString &path, const QJsonObject &payload, bool withAuth)
{
    return m_networkManager->post(makeRequest(path, withAuth), QJsonDocument(payload).toJson());
}

QNetworkReply *NetworkClient::put(const QString &path, const QJsonObject &payload, bool withAuth)
{
    return m_networkManager->put(makeRequest(path, withAuth), QJsonDocument(payload).toJson());
}

QNetworkReply *NetworkClient::deleteResource(const QString &path, bool withAuth)
{
    return m_networkManager->deleteResource(makeRequest(path, withAuth));
}

NetworkResponse NetworkClient::response(QNetworkReply *reply, const QString &fallbackMessage) const
{
    NetworkResponse result;
    if (reply == nullptr) {
        result.errorMessage = fallbackMessage;
        return result;
    }

    result.statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    result.networkError = reply->error();
    result.body = reply->readAll();

    if (result.networkError != QNetworkReply::NoError) {
        result.errorMessage = errorMessage(result.body, reply, fallbackMessage);
        return result;
    }

    result.ok = true;
    return result;
}

QString NetworkClient::errorMessage(const QByteArray &body, QNetworkReply *reply,
                                    const QString &fallbackMessage) const
{
    if (reply == nullptr)
        return fallbackMessage;

    if (!body.isEmpty()) {
        const QJsonDocument doc = QJsonDocument::fromJson(body);
        if (doc.isObject()) {
            const QJsonObject obj = doc.object();
            const QStringList keys = { "error", "message", "detail" };
            for (const QString &key : keys) {
                const QJsonValue value = obj.value(key);
                if (value.isString() && !value.toString().isEmpty())
                    return value.toString();
            }
        }
    }

    if (!fallbackMessage.isEmpty())
        return fallbackMessage;

    return reply->errorString();
}

QNetworkRequest NetworkClient::makeRequest(const QString &path, bool withAuth) const
{
    QNetworkRequest request(QUrl(BASE_URL + path));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setTransferTimeout(30000);
    if (withAuth)
        request.setRawHeader("Authorization", "Bearer " + s_accessToken.toUtf8());
    return request;
}

void NetworkClient::setAccessToken(const QString &token)
{
    s_accessToken = token;
}

void NetworkClient::clearAccessToken()
{
    s_accessToken.clear();
}

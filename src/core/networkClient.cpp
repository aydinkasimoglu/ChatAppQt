#include "networkClient.h"

#include "authclient.h"

#include <QEventLoop>
#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

static const QString BASE_URL = QStringLiteral("http://localhost:3000");

constexpr const char *MethodProperty = "chatappMethod";
constexpr const char *PathProperty = "chatappPath";
constexpr const char *BodyProperty = "chatappBody";
constexpr const char *WithAuthProperty = "chatappWithAuth";
constexpr const char *AuthRetryCountProperty = "chatappAuthRetryCount";
constexpr const char *AuthTokenProperty = "chatappAuthToken";

QString NetworkClient::defaultInvalidJsonMessage(const QString &invalidMessage)
{
    return invalidMessage.isEmpty() ? QStringLiteral("Invalid server response") : invalidMessage;
}

NetworkClient &NetworkClient::instance()
{
    static NetworkClient s_instance;
    return s_instance;
}

NetworkClient::NetworkClient()
    : m_networkManager(std::make_unique<QNetworkAccessManager>())
{}

NetworkClient::~NetworkClient() = default;

QNetworkReply *NetworkClient::get(const QString &path, bool withAuth)
{
    return send(QStringLiteral("GET"), path, QByteArray(), withAuth);
}

QNetworkReply *NetworkClient::post(const QString &path, const QJsonObject &payload, bool withAuth)
{
    return send(QStringLiteral("POST"), path, QJsonDocument(payload).toJson(), withAuth);
}

QNetworkReply *NetworkClient::patch(const QString &path, const QJsonObject &payload, bool withAuth)
{
    return send(QStringLiteral("PATCH"), path, QJsonDocument(payload).toJson(), withAuth);
}

QNetworkReply *NetworkClient::put(const QString &path, const QJsonObject &payload, bool withAuth)
{
    return send(QStringLiteral("PUT"), path, QJsonDocument(payload).toJson(), withAuth);
}

QNetworkReply *NetworkClient::deleteResource(const QString &path, bool withAuth)
{
    return send(QStringLiteral("DELETE"), path, QByteArray(), withAuth);
}

QNetworkReply *NetworkClient::send(const QString &method,
                                   const QString &path,
                                   const QByteArray &body,
                                   bool withAuth,
                                   int authRetryCount) const
{
    const QNetworkRequest request = makeRequest(path, withAuth);

    QNetworkReply *reply = nullptr;
    if (method == QLatin1String("GET")) {
        reply = m_networkManager->get(request);
    } else if (method == QLatin1String("POST")) {
        reply = m_networkManager->post(request, body);
    } else if (method == QLatin1String("PATCH")) {
        reply = m_networkManager->sendCustomRequest(request, "PATCH", body);
    } else if (method == QLatin1String("PUT")) {
        reply = m_networkManager->put(request, body);
    } else if (method == QLatin1String("DELETE")) {
        reply = m_networkManager->deleteResource(request);
    }

    if (reply == nullptr)
        return nullptr;

    reply->setProperty(MethodProperty, method);
    reply->setProperty(PathProperty, path);
    reply->setProperty(BodyProperty, body);
    reply->setProperty(WithAuthProperty, withAuth);
    reply->setProperty(AuthRetryCountProperty, authRetryCount);
    reply->setProperty(AuthTokenProperty, withAuth ? s_accessToken : QString());

    return reply;
}

NetworkResponse NetworkClient::response(QNetworkReply *reply, const QString &fallbackMessage) const
{
    NetworkResponse result = buildResponse(reply, fallbackMessage);
    if (reply == nullptr)
        return result;

    const QString method = reply->property(MethodProperty).toString();
    const QString path = reply->property(PathProperty).toString();
    const QByteArray body = reply->property(BodyProperty).toByteArray();
    const bool withAuth = reply->property(WithAuthProperty).toBool();
    const int authRetryCount = reply->property(AuthRetryCountProperty).toInt();
    const QString requestToken = reply->property(AuthTokenProperty).toString();

    if (result.statusCode != 401
        || !withAuth
        || authRetryCount > 0
        || method.isEmpty()
        || path == QLatin1String("/auth/refresh")) {
        return result;
    }

    const bool canRetryWithCurrentToken = !s_accessToken.isEmpty() && requestToken != s_accessToken;
    if (!canRetryWithCurrentToken) {
        AuthClient *authClient = AuthClient::instance();
        if (authClient == nullptr || !authClient->refreshAccessTokenBlocking())
            return result;
    }

    if (s_accessToken.isEmpty())
        return result;

    QNetworkReply *retryReply = send(method, path, body, withAuth, authRetryCount + 1);
    if (retryReply == nullptr)
        return result;

    QEventLoop loop;
    QObject::connect(retryReply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    NetworkResponse retryResult = buildResponse(retryReply, fallbackMessage);
    retryReply->deleteLater();
    return retryResult;
}

NetworkResponse NetworkClient::buildResponse(QNetworkReply *reply,
                                             const QString &fallbackMessage) const
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

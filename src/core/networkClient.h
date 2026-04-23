#ifndef NETWORKCLIENT_H
#define NETWORKCLIENT_H

#include <QByteArray>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>

#include <memory>
#include <type_traits>

class QNetworkAccessManager;
class QNetworkRequest;

struct NetworkResponse
{
    bool ok = false;
    int statusCode = -1;
    QNetworkReply::NetworkError networkError = QNetworkReply::NoError;
    QString errorMessage;
    QByteArray body;
};

template <typename T>
concept JsonType = std::is_same_v<T, QJsonObject> || std::is_same_v<T, QJsonArray>;

template <JsonType T>
struct JsonResponse : NetworkResponse
{
    T data;
};

using JsonObjectResponse = JsonResponse<QJsonObject>;
using JsonArrayResponse = JsonResponse<QJsonArray>;

class NetworkClient
{
public:
    static NetworkClient &instance();

    NetworkClient(const NetworkClient &) = delete;
    NetworkClient &operator=(const NetworkClient &) = delete;

    QNetworkReply *get(const QString &path, bool withAuth = false);
    QNetworkReply *post(const QString &path, const QJsonObject &payload, bool withAuth = false);
    QNetworkReply *patch(const QString &path, const QJsonObject &payload, bool withAuth = false);
    QNetworkReply *put(const QString &path, const QJsonObject &payload, bool withAuth = false);
    QNetworkReply *deleteResource(const QString &path, bool withAuth = false);
    NetworkResponse response(QNetworkReply *reply, const QString &fallbackMessage = QString()) const;

    static void setAccessToken(const QString &token);
    static void clearAccessToken();
    static const QString &accessToken() { return s_accessToken; }

    template <JsonType T>
    JsonResponse<T> jsonResponse(QNetworkReply *reply,
                                 const QString &fallbackMessage = QString(),
                                 const QString &invalidMessage = QString()) const
    {
        JsonResponse<T> result;
        static_cast<NetworkResponse &>(result) = response(reply, fallbackMessage);
        if (!result.ok)
            return result;

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(result.body, &parseError);
        if (parseError.error != QJsonParseError::NoError) {
            result.ok = false;
            result.errorMessage = defaultInvalidJsonMessage(invalidMessage);
            return result;
        }

        if constexpr (std::is_same_v<T, QJsonObject>) {
            if (!document.isObject()) {
                result.ok = false;
                result.errorMessage = defaultInvalidJsonMessage(invalidMessage);
                return result;
            }

            result.data = document.object();
        } else {
            if (!document.isArray()) {
                result.ok = false;
                result.errorMessage = defaultInvalidJsonMessage(invalidMessage);
                return result;
            }

            result.data = document.array();
        }

        return result;
    }

private:
    NetworkClient();
    ~NetworkClient();

    QNetworkReply *send(const QString &method,
                        const QString &path,
                        const QByteArray &body = QByteArray(),
                        bool withAuth = false,
                        int authRetryCount = 0) const;
    static QString defaultInvalidJsonMessage(const QString &invalidMessage);
    QString errorMessage(const QByteArray &body, QNetworkReply *reply,
                         const QString &fallbackMessage) const;
    NetworkResponse buildResponse(QNetworkReply *reply,
                                  const QString &fallbackMessage) const;
    QNetworkRequest makeRequest(const QString &path, bool withAuth) const;

    std::unique_ptr<QNetworkAccessManager> m_networkManager;
    static inline QString s_accessToken;
};

#endif // NETWORKCLIENT_H
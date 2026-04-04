#include "authclient.h"

#include <QDateTime>
#include <QJsonDocument>
#include <QNetworkReply>
#include <QSettings>

// Refresh the access token this many seconds before it expires.
static constexpr int REFRESH_MARGIN_SECS = 60;

// Fallback refresh interval if the JWT expiry cannot be decoded (14 minutes).
static constexpr int FALLBACK_REFRESH_MS = 14 * 60 * 1000;

// Maximum retry attempts for transient refresh failures.
static constexpr int MAX_REFRESH_RETRIES = 3;

// Initial backoff delay between refresh retries (doubles each attempt).
static constexpr int INITIAL_RETRY_DELAY_MS = 2000;

// ---------------------------------------------------------------------------
// JWT helpers (stateless, file-local)
// ---------------------------------------------------------------------------

static QJsonObject decodeJwtPayload(const QString& token)
{
    const QStringList parts = token.split('.');
    if (parts.size() != 3)
        return {};

    const QByteArray decoded = QByteArray::fromBase64(
        parts[1].toUtf8(), QByteArray::Base64UrlEncoding);
    const QJsonDocument doc = QJsonDocument::fromJson(decoded);
    return doc.isObject() ? doc.object() : QJsonObject{};
}

static QString extractUserIdFromToken(const QString& token)
{
    return decodeJwtPayload(token).value("sub").toString();
}

static qint64 decodeTokenExpiry(const QString& token)
{
    const QJsonValue exp = decodeJwtPayload(token).value("exp");
    return exp.isDouble() ? static_cast<qint64>(exp.toDouble()) : -1;
}

// ---------------------------------------------------------------------------
// AuthClient
// ---------------------------------------------------------------------------

AuthClient::AuthClient(QObject *parent) : QObject(parent)
{
    m_refreshTimer.setSingleShot(true);
    connect(&m_refreshTimer, &QTimer::timeout, this, &AuthClient::refreshAccessToken);

    QSettings settings("ChatAppProj", "ChatApp");
    m_refreshToken = settings.value("refreshToken").toString();

    if (!m_refreshToken.isEmpty()) {
        m_restoringSession = true;
        refreshAccessToken();
    }
}

void AuthClient::login(const QString& email, const QString& password)
{
    QJsonObject json;
    json["email"] = email;
    json["password"] = password;

    QNetworkReply *reply = m_networkClient.post("/login", json);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        const JsonObjectResponse response = m_networkClient.jsonResponse<QJsonObject>(
            reply, "Wrong e-mail address or password.");
        if (!response.ok) {
            emit loginFailed(response.errorMessage);
            return;
        }

        const QString accessToken  = response.data.value("access_token").toString();
        const QString refreshToken = response.data.value("refresh_token").toString();
        if (accessToken.isEmpty() || refreshToken.isEmpty()) {
            emit loginFailed("Invalid response from server");
            return;
        }

        storeTokens(accessToken, refreshToken);

        const QString userId = extractUserIdFromToken(accessToken);
        if (userId.isEmpty()) {
            emit loginFailed("Could not extract user ID from token");
            return;
        }

        fetchUserInfo(userId);
        emit loginSucceeded();
    });
}

void AuthClient::signup(const QString& email, const QString& username, const QString& password)
{
    QJsonObject json;
    json["email"] = email;
    json["username"] = username;
    json["password"] = password;

    QNetworkReply *reply = m_networkClient.post("/signup", json);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        const NetworkResponse response = m_networkClient.response(reply);
        if (!response.ok) {
            emit signupFailed(response.errorMessage);
            return;
        }

        emit signupSucceeded();
    });
}

void AuthClient::logout()
{
    if (!m_refreshToken.isEmpty()) {
        QJsonObject json;
        json["refresh_token"] = m_refreshToken;
        // Fire-and-forget: revoke the refresh token on the server.
        QNetworkReply *reply = m_networkClient.post("/auth/logout", json, true);
        connect(reply, &QNetworkReply::finished, reply, &QNetworkReply::deleteLater);
    }

    clearTokens();
    emit authenticationChanged();
}

void AuthClient::fetchUserInfo(const QString& userId)
{
    QNetworkReply *reply = m_networkClient.get("/users/" + userId, true);

    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();

        const JsonObjectResponse response = m_networkClient.jsonResponse<QJsonObject>(
            reply, QString(), "Invalid user data from server.");
        if (!response.ok) {
            if (response.networkError == QNetworkReply::ContentNotFoundError) {
                clearTokens();
                emit authenticationChanged();
                emit userLoadFailed("Please sign in again.");
            } else if (response.networkError != QNetworkReply::NoError) {
                emit userLoadFailed("Couldn't reach the server.");
            } else {
                emit userLoadFailed(response.errorMessage);
            }
            return;
        }

        setEmail(response.data.value("email").toString());
        setUsername(response.data.value("username").toString());
        m_userLoaded = true;

        emit userLoaded();
        emit authenticationChanged();
    });
}

void AuthClient::refreshAccessToken()
{
    if (m_refreshToken.isEmpty() || m_refreshInProgress)
        return;

    m_refreshInProgress = true;

    QJsonObject json;
    json["refresh_token"] = m_refreshToken;

    QNetworkReply *reply = m_networkClient.post("/auth/refresh", json);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_refreshInProgress = false;

        const JsonObjectResponse response = m_networkClient.jsonResponse<QJsonObject>(reply);
        if (!response.ok) {
            const bool wasRestoring = m_restoringSession;
            m_restoringSession = false;

            // Definitive auth rejection — token revoked or expired on server.
            if (response.statusCode == 401 || response.statusCode == 403) {
                m_refreshRetryCount = 0;
                clearTokens();
                if (wasRestoring) emit restoringSessionChanged();
                emit authenticationChanged();
                return;
            }

            // Transient failure (network error, 5xx) — retry with exponential backoff.
            if (m_refreshRetryCount < MAX_REFRESH_RETRIES) {
                const int delay = INITIAL_RETRY_DELAY_MS * (1 << m_refreshRetryCount);
                ++m_refreshRetryCount;
                QTimer::singleShot(delay, this, &AuthClient::refreshAccessToken);
                return;
            }

            // Retries exhausted.
            m_refreshRetryCount = 0;
            clearTokens();
            if (wasRestoring) emit restoringSessionChanged();
            emit authenticationChanged();
            return;
        }

        m_refreshRetryCount = 0;

        const QString accessToken  = response.data.value("access_token").toString();
        const QString refreshToken = response.data.value("refresh_token").toString();
        if (accessToken.isEmpty() || refreshToken.isEmpty()) {
            clearTokens();
            emit authenticationChanged();
            return;
        }

        const bool firstLoad = !m_userLoaded;
        storeTokens(accessToken, refreshToken);

        // Tokens are stored — clear restoring flag and notify QML atomically
        // so it never sees both isRestoringSession=false AND isAuthenticated=false.
        if (m_restoringSession) {
            m_restoringSession = false;
            emit restoringSessionChanged();
        }
        emit authenticationChanged();

        if (firstLoad) {
            const QString userId = extractUserIdFromToken(accessToken);
            if (userId.isEmpty()) {
                clearTokens();
                emit authenticationChanged();
                return;
            }
            fetchUserInfo(userId);
        }
    });
}

void AuthClient::storeTokens(const QString& accessToken, const QString& refreshToken)
{
    m_accessToken  = accessToken;
    m_refreshToken = refreshToken;

    NetworkClient::setAccessToken(accessToken);

    QSettings settings("ChatAppProj", "ChatApp");
    settings.setValue("refreshToken", refreshToken);

    scheduleTokenRefresh(accessToken);
}

void AuthClient::clearTokens()
{
    m_accessToken.clear();
    m_refreshToken.clear();
    m_userLoaded = false;
    m_refreshInProgress = false;
    m_refreshRetryCount = 0;
    m_refreshTimer.stop();

    NetworkClient::clearAccessToken();

    QSettings settings("ChatAppProj", "ChatApp");
    settings.remove("accessToken");
    settings.remove("refreshToken");
}

void AuthClient::scheduleTokenRefresh(const QString& accessToken)
{
    const qint64 expiry = decodeTokenExpiry(accessToken);
    if (expiry <= 0) {
        m_refreshTimer.start(FALLBACK_REFRESH_MS);
        return;
    }

    const qint64 now = QDateTime::currentSecsSinceEpoch();
    const qint64 delayMs = qMax(0LL, (expiry - REFRESH_MARGIN_SECS - now) * 1000);

    m_refreshTimer.start(static_cast<int>(qMin(delayMs, static_cast<qint64>(INT_MAX))));
}
#ifndef AUTHCLIENT_H
#define AUTHCLIENT_H

#include <QObject>
#include <QTimer>
#include <QJsonObject>
#include <QtQml/qqml.h>
#include <QNetworkReply>
#include <qqmlintegration.h>

class AuthClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY authenticationChanged)
    Q_PROPERTY(bool isUserLoaded READ isUserLoaded NOTIFY userLoaded)
    Q_PROPERTY(bool isRestoringSession READ isRestoringSession NOTIFY restoringSessionChanged)

    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY userLoaded FINAL)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY userLoaded FINAL)
public:
    explicit AuthClient(QObject *parent = nullptr);

    QString email() const { return m_email; }
    QString username() const { return m_username; }
    QString userId() const { return m_userId; }

    void setEmail(const QString& email) { m_email = email; }
    void setUsername(const QString& username) { m_username = username; }

    static AuthClient *create(QQmlEngine *, QJSEngine *) { return new AuthClient(); }
    static AuthClient *instance() { return s_instance; }

    Q_INVOKABLE void login(const QString& email, const QString& password);
    Q_INVOKABLE void signup(const QString& email, const QString& username, const QString& password);
    Q_INVOKABLE void logout();

    bool refreshAccessTokenBlocking();

    bool isAuthenticated() const { return !m_accessToken.isEmpty(); }
    bool isUserLoaded() const { return m_userLoaded; }
    bool isRestoringSession() const { return m_restoringSession; }

signals:
    void loginSucceeded();
    void loginFailed(QString message);

    void signupSucceeded();
    void signupFailed(QString message);

    void authenticationChanged();
    void userLoaded();
    void userLoadFailed(QString message);
    void restoringSessionChanged();
    void accessTokenRefreshFinished(bool success, bool authenticationRejected);

private:
    void storeTokens(const QString& accessToken, const QString& refreshToken);
    void clearTokens();
    void fetchUserInfo(const QString& userId);
    void refreshAccessToken();
    void scheduleTokenRefresh(const QString& accessToken);
    void startTokenRefresh(bool allowTransientRetries);
    void finalizeTokenRefresh(QNetworkReply *reply, bool allowTransientRetries);
    void scheduleDeferredRefreshRetry();

    QTimer m_refreshTimer;

    QString m_accessToken;
    QString m_refreshToken;

    bool m_userLoaded = false;
    bool m_restoringSession = false;
    bool m_refreshInProgress = false;
    int m_refreshRetryCount = 0;

    QString m_email, m_username, m_userId;

    static inline AuthClient *s_instance = nullptr;
};

#endif // AUTHCLIENT_H

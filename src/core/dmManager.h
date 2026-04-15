#ifndef DMMANAGER_H
#define DMMANAGER_H

#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>
#include <qqmlintegration.h>

#include "dmConversationListModel.h"
#include "dmMessageListModel.h"
#include "networkClient.h"

class DmManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(DmConversationListModel *conversations READ conversations CONSTANT)
    Q_PROPERTY(DmMessageListModel *messages READ messages CONSTANT)
    Q_PROPERTY(QString currentConversationId READ currentConversationId NOTIFY currentConversationChanged)
    Q_PROPERTY(QString currentConversationTitle READ currentConversationTitle NOTIFY currentConversationChanged)
    Q_PROPERTY(QString currentDirectPartnerId READ currentDirectPartnerId NOTIFY currentConversationChanged)
    Q_PROPERTY(bool currentConversationReadActive READ currentConversationReadActive WRITE setCurrentConversationReadActive NOTIFY currentConversationReadActiveChanged)
    Q_PROPERTY(bool conversationsLoading READ conversationsLoading NOTIFY conversationsLoadingChanged)
    Q_PROPERTY(bool messagesLoading READ messagesLoading NOTIFY messagesLoadingChanged)
    Q_PROPERTY(bool openingConversation READ openingConversation NOTIFY openingConversationChanged)

public:
    explicit DmManager(QObject *parent = nullptr);

    static DmManager *create(QQmlEngine *, QJSEngine *) { return new DmManager(); }

    DmConversationListModel *conversations() { return &m_conversations; }
    DmMessageListModel *messages() { return &m_messages; }

    QString currentConversationId() const { return m_currentConversationId; }
    QString currentConversationTitle() const { return m_currentConversationTitle; }
    QString currentDirectPartnerId() const { return m_currentDirectPartnerId; }
    bool currentConversationReadActive() const { return m_currentConversationReadActive; }

    bool conversationsLoading() const { return m_conversationsLoading; }
    bool messagesLoading() const { return m_messagesLoading; }
    bool openingConversation() const { return m_openingConversation; }

    Q_INVOKABLE void fetchConversations();
    Q_INVOKABLE void openDirectConversation(const QString &userId, const QString &username);
    Q_INVOKABLE void selectConversation(const QString &conversationId,
                                        const QString &title,
                                        const QString &directPartnerId);
    Q_INVOKABLE void acknowledgeCurrentConversationMessages();
    Q_INVOKABLE void sendMessage(const QString &text);
    Q_INVOKABLE void handleIncomingMessage(const QString &conversationId,
                                           const QVariantMap &message);
    Q_INVOKABLE void resetState();

signals:
    void currentConversationChanged();
    void currentConversationReadActiveChanged();
    void conversationsLoadingChanged();
    void messagesLoadingChanged();
    void openingConversationChanged();

    void conversationsLoadFailed(QString message);
    void conversationOpenFailed(QString message);
    void messagesLoadFailed(QString message);
    void messageSendFailed(QString message);
    void messageSent();

private:
    void loadMessages(const QString &conversationId);
    void markConversationRead(const QString &conversationId, const QString &messageId);
    void setCurrentConversationReadActive(bool active);

    void setConversationsLoading(bool loading);
    void setMessagesLoading(bool loading);
    void setOpeningConversation(bool loading);
    void setCurrentConversation(const QString &conversationId,
                                const QString &title,
                                const QString &directPartnerId);
    void syncCurrentConversationFromModel();

    QString currentUserId() const;

    NetworkClient m_networkClient;
    DmConversationListModel m_conversations;
    DmMessageListModel m_messages;

    QString m_currentConversationId;
    QString m_currentConversationTitle;
    QString m_currentDirectPartnerId;
    bool m_currentConversationReadActive = false;
    bool m_conversationsLoading = false;
    bool m_messagesLoading = false;
    bool m_openingConversation = false;
};

#endif // DMMANAGER_H
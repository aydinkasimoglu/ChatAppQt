#ifndef CLIPBOARDHELPER_H
#define CLIPBOARDHELPER_H

#include <QClipboard>
#include <QGuiApplication>
#include <QObject>
#include <QString>
#include <qqmlintegration.h>
#include <QQmlEngine>
#include <QJSEngine>

class ClipboardHelper : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit ClipboardHelper(QObject *parent = nullptr) : QObject(parent) { }

    static ClipboardHelper *create(QQmlEngine *, QJSEngine *) { return new ClipboardHelper(); }

    Q_INVOKABLE void copyText(const QString &text) {
        QGuiApplication::clipboard()->setText(text);
    }
};

#endif // CLIPBOARDHELPER_H
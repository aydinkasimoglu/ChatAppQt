pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic
import "../components"

Rectangle {
    id: root

    // ── Public API ────────────────────────────────────────
    signal addServerRequested
    signal serverSelected(int index, string name, string serverId)
    signal settingsRequested
    signal logoutRequested

    function accentColorForName(name) {
        const palette = ["#5865F2", "#41b883", "#f2c94c", "#ed4245", "#57F287", "#FEE75C", "#EB459E", "#5DADE2"];
        let hash = 0;
        for (let i = 0; i < name.length; i++)
            hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
        return palette[hash % palette.length];
    }

    // ── Appearance ────────────────────────────────────────
    width: Theme.sidePanelWidth
    color: Theme.surfaceDeep

    Component.onCompleted: ServerManager.fetchMyServers()

    // ── Layout ────────────────────────────────────────────
    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: userBlob.top
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 8

        AddServerButton {
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.addServerRequested()
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 32
            height: 2
            radius: 1
            color: Theme.surfaceBorder
        }

        ListView {
            id: serverList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: ServerManager.myServers

            delegate: Item {
                id: delegateItem

                required property string name
                required property string serverId
                required property int index

                width: ListView.view.width
                height: Theme.serverIconSize

                ServerIcon {
                    anchors.centerIn: parent
                    serverName: delegateItem.name
                    accentColor: root.accentColorForName(delegateItem.name)
                    onClicked: root.serverSelected(delegateItem.index, delegateItem.name, delegateItem.serverId)
                }
            }
        }
    }

    // ── User blob (bottom-left) ───────────────────────────
    Rectangle {
        id: userBlob
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        width: Theme.serverIconSize
        height: Theme.serverIconSize
        radius: 12
        color: Theme.accentPink

        // Subtle ring when popup is open
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 6
            radius: parent.radius + 3
            color: "transparent"
            border.color: Theme.accentPink
            border.width: 2
            opacity: userPopup.opened ? 0.55 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: AuthClient.username.charAt(0).toUpperCase()
            color: "#ffffff"
            font.pixelSize: 20
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: userPopup.opened ? userPopup.close() : userPopup.open()
        }
    }

    // ── User popup panel ──────────────────────────────────
    Popup {
        id: userPopup

        x: root.width + 8
        y: userBlob.y - height + userBlob.height

        width: 220
        padding: 5   // single source of truth for all inner spacing

        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        // ── Enter / exit animations ──────────────────────
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: userPopup.contentItem
                    property: "x"
                    from: -10
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 140
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: userPopup.contentItem
                    property: "x"
                    from: 0
                    to: -10
                    duration: 140
                    easing.type: Easing.InCubic
                }
            }
        }

        background: Rectangle {
            color: Theme.surfaceMid
            radius: 12
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#88000000"
                shadowBlur: 0.6
                shadowVerticalOffset: 3
                shadowHorizontalOffset: 0
            }
        }

        contentItem: Column {
            id: contentColumn
            // width/topPadding/bottomPadding removed — Popup.padding handles all of it
            spacing: 0

            // ── User info header ─────────────────────────
            Item {
                width: parent.width
                height: 52

                Rectangle {
                    id: miniBlob
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: 36
                    height: 36
                    radius: 9
                    color: Theme.accentPink

                    Text {
                        anchors.centerIn: parent
                        text: AuthClient.username.charAt(0).toUpperCase()
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: miniBlob.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    spacing: 2

                    Text {
                        text: AuthClient.username
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: qsTr("Online")
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }

            // ── Divider ──────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ── Settings ─────────────────────────────────
            PopupMenuItem {
                width: parent.width
                iconSource: "/assets/icons/settings.svg"
                label: qsTr("Settings")
                onClicked: {
                    userPopup.close();
                    root.settingsRequested();
                }
            }

            // ── Divider ──────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ── Log out ──────────────────────────────────
            PopupMenuItem {
                width: parent.width
                iconSource: "/assets/icons/logout.svg"
                label: qsTr("Log Out")
                labelColor: "#ed4245"
                hoverColor: Qt.rgba(0.93, 0.26, 0.27, 0.15)
                onClicked: {
                    userPopup.close();
                    root.logoutRequested();
                }
            }
        }
    }
}

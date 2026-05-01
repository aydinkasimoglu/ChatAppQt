pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: midPanelRoot

    signal friendsSelected()
    signal dmSelected(string conversationId, string conversationTitle, string directPartnerId)

    property string activeItemId: "friends"

    width: Theme.midPanelWidth
    color: Theme.surfaceDeep

    readonly property var avatarPalette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]

    function avatarColorForName(displayName) {
        if (!displayName || displayName.length === 0)
            return avatarPalette[0]

        return avatarPalette[displayName.charCodeAt(0) % avatarPalette.length]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 0

        Item {
            Layout.fillWidth:       true
            Layout.preferredHeight: 44
            Layout.leftMargin:      8
            Layout.rightMargin:     8
            Layout.bottomMargin:    2

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: midPanelRoot.activeItemId === "friends"
                       ? Theme.surfaceRaised
                       : (friendsHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            RowLayout {
                anchors.fill:        parent
                anchors.leftMargin:  10
                anchors.rightMargin: 10
                spacing: 10

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Theme.accentBlue

                    Image {
                        anchors.centerIn: parent
                        source: "/assets/icons/group.svg"
                        width:     14
                        height:    14

                        sourceSize.width: width * Screen.devicePixelRatio
                        sourceSize.height: height * Screen.devicePixelRatio
                        
                        smooth: true
                        mipmap: true 
                        Layout.preferredWidth:  14
                        Layout.preferredHeight: 14
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text:  "Friends"
                    color: midPanelRoot.activeItemId === "friends" ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: 15
                    font.weight:    Font.Medium
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            HoverHandler { id: friendsHover }
            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked: {
                    midPanelRoot.friendsSelected()
                }
            }
        }

        RowLayout {
            Layout.fillWidth:    true
            Layout.leftMargin:   18
            Layout.rightMargin:  10
            Layout.topMargin:    16
            Layout.bottomMargin: 4
            spacing: 0

            Text {
                Layout.fillWidth:   true
                text:               "DIRECT MESSAGES"
                color:              Theme.textSubtle
                font.pixelSize:     11
                font.weight:        Font.DemiBold
                font.letterSpacing: 0.5
            }

            Text {
                text: DmManager.conversationsLoading
                      ? "SYNCING"
                    : qsTr("%1").arg(DmManager.conversations.count)
                color: Theme.textSubtle
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
            }
        }

        Item {
            Layout.fillWidth:    true
            Layout.fillHeight:   true
            Layout.leftMargin:   8
            Layout.rightMargin:  8
            Layout.bottomMargin: 8
            clip: true

            ListView {
                id: dmListView

                anchors.fill: parent
                clip: true
                spacing: 8
                visible: DmManager.conversations.count > 0
                model: DmManager.conversations

                delegate: Item {
                    id: dmDelegate

                    required property string conversationId
                    required property string displayTitle
                    required property string directPartnerId
                    required property string lastMessagePreview
                    required property int unreadCount
                    required property bool hasUnread

                    width: dmListView.width
                    height: 56

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: midPanelRoot.activeItemId === dmDelegate.conversationId
                               ? Theme.surfaceRaised
                               : (dmHover.hovered ? Theme.surfaceRaised : Theme.surfaceMid)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Item {
                            width: 32
                            height: 32

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: midPanelRoot.avatarColorForName(dmDelegate.displayTitle)

                                Text {
                                    anchors.centerIn: parent
                                    text: dmDelegate.displayTitle.charAt(0).toUpperCase()
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                            }

                            Rectangle {
                                visible: dmDelegate.directPartnerId.length > 0
                                         && PresenceManager.isUserOnline(dmDelegate.directPartnerId)
                                width: 10
                                height: 10
                                radius: 5
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                color: "#23a559"
                                border.width: 2
                                border.color: Theme.surfaceMid
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: dmDelegate.displayTitle
                                color: midPanelRoot.activeItemId === dmDelegate.conversationId
                                       ? Theme.textPrimary : Theme.textSecondary
                                font.pixelSize: 14
                                font.weight: dmDelegate.hasUnread ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: dmDelegate.lastMessagePreview
                                color: dmDelegate.hasUnread ? Theme.textMuted : Theme.textSubtle
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        Rectangle {
                            visible: dmDelegate.unreadCount > 0
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: Math.max(18, unreadLabel.implicitWidth + 8)
                            implicitHeight: 18
                            radius: 9
                            color: Theme.accentBlue

                            Text {
                                id: unreadLabel
                                anchors.centerIn: parent
                                text: dmDelegate.unreadCount > 99 ? "99+" : qsTr("%1").arg(dmDelegate.unreadCount)
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    HoverHandler { id: dmHover }
                    MouseArea {
                        id: dmMouseArea
                        anchors.fill: parent
                        enabled: midPanelRoot.activeItemId !== dmDelegate.conversationId
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            midPanelRoot.dmSelected(
                                dmDelegate.conversationId,
                                dmDelegate.displayTitle,
                                dmDelegate.directPartnerId)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: DmManager.conversationsLoading && DmManager.conversations.count === 0
                text: "Loading recent direct messages..."
                color: Theme.textMuted
                font.pixelSize: 13
            }

            Text {
                anchors.centerIn: parent
                visible: !DmManager.conversationsLoading && DmManager.conversations.count === 0
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "Your recent direct messages will appear here once you start chatting."
                color: Theme.textMuted
                font.pixelSize: 13
            }
        }
    }
}

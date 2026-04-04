pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// MidPanel: navigation panel showing the Friends shortcut and DM list.
// Fixed-width; lives between the server rail and the main content area.
// Emits signals upward; owns no view state beyond tracking the active item.
Rectangle {
    id: root

    // ── Public API ────────────────────────────────────────
    signal friendsSelected()
    signal dmSelected(string dmId, string username)

    property string activeItemId: "friends"

    // ── Appearance ────────────────────────────────────────
    width: Theme.midPanelWidth
    color: Theme.surfaceMid

    // ── Placeholder DM list (swap for a real C++ model later) ─
    ListModel {
        id: dmModel
        ListElement { dmId: "dm1"; username: "Alice";   lastMessage: "Hey, how are you?";   avatarColor: "#5865F2" }
        ListElement { dmId: "dm2"; username: "Bob";     lastMessage: "Did you see that?";    avatarColor: "#23a559" }
        ListElement { dmId: "dm3"; username: "Charlie"; lastMessage: "Let's catch up!";      avatarColor: "#eb459e" }
        ListElement { dmId: "dm4"; username: "Diana";   lastMessage: "Thanks!";              avatarColor: "#f2c94c" }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 0

        // ── Friends nav item ──────────────────────────────
        Item {
            Layout.fillWidth:       true
            Layout.preferredHeight: 44
            Layout.leftMargin:      8
            Layout.rightMargin:     8
            Layout.bottomMargin:    2

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: root.activeItemId === "friends"
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
                    color: root.activeItemId === "friends" ? Theme.textPrimary : Theme.textMuted
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
                    root.activeItemId = "friends"
                    root.friendsSelected()
                }
            }
        }

        // ── "DIRECT MESSAGES" section header ─────────────
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

            Item {
                width: 16; height: 16

                Text {
                    anchors.centerIn: parent
                    text:             "+"
                    color:            plusHover.hovered ? Theme.textPrimary : Theme.textSubtle
                    font.pixelSize:   16
                    font.weight:      Font.Light
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                HoverHandler { id: plusHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                }
            }
        }

        // ── DM conversation list ──────────────────────────
        ListView {
            Layout.fillWidth:    true
            Layout.fillHeight:   true
            Layout.leftMargin:   8
            Layout.rightMargin:  8
            Layout.bottomMargin: 8
            clip:    true
            spacing: 2

            model: dmModel

            delegate: Item {
                id: dmDelegate

                required property int    index
                required property string dmId
                required property string username
                required property string lastMessage
                required property string avatarColor

                width:  ListView.view.width
                height: 50

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: root.activeItemId === dmDelegate.dmId
                           ? Theme.surfaceRaised
                           : (dmHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    anchors.fill:        parent
                    anchors.leftMargin:  10
                    anchors.rightMargin: 10
                    spacing: 10

                    // Avatar with initial
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: dmDelegate.avatarColor

                        Text {
                            anchors.centerIn: parent
                            text:        dmDelegate.username.charAt(0).toUpperCase()
                            color:       "#ffffff"
                            font.pixelSize: 14
                            font.weight:    Font.DemiBold
                        }
                    }

                    // Username + last message preview
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text:  dmDelegate.username
                            color: root.activeItemId === dmDelegate.dmId
                                   ? Theme.textPrimary : Theme.textSecondary
                            font.pixelSize: 14
                            font.weight:    Font.Medium
                            elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text:           dmDelegate.lastMessage
                            color:          Theme.textSubtle
                            font.pixelSize: 12
                            elide:          Text.ElideRight
                        }
                    }
                }

                HoverHandler { id: dmHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root.activeItemId = dmDelegate.dmId
                        root.dmSelected(dmDelegate.dmId, dmDelegate.username)
                    }
                }
            }
        }
    }
}

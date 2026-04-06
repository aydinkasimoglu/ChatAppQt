pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// FriendsView: shown in the main content area when the Friends nav item is active.
// Provides sub-tabs (Online / All / Pending / Blocked) and a friends list,
// plus an "Add Friend" form backed by FriendshipManager.
Rectangle {
    id: root

    color: Theme.surfaceRaised

    signal dmRequested(string recipientId, string recipientName)

    // ── Active sub-tab ────────────────────────────────────
    property string activeTab: "online"

    Component.onCompleted: {
        FriendshipManager.fetchFriends()
        FriendshipManager.fetchPendingRequests()
    }

    onActiveTabChanged: {
        if (activeTab === "blocked")
            FriendshipManager.fetchBlockedUsers()
    }

    Connections {
        target: FriendshipManager

        function onFriendRequestSent() {
            addFriendInput.text = ""
            root.activeTab = "pending"
            FriendshipManager.fetchPendingRequests()
        }

        function onRequestAccepted() {
            FriendshipManager.fetchFriends()
        }
    }

    Connections {
        target: PresenceManager

        function onOnlineUsersChanged() {
            FriendshipManager.friends.setOnlineUsersList(PresenceManager.onlineUserIds())
        }

        function onUserWentOnline(userId) {
            FriendshipManager.friends.setUserOnline(userId, true)
        }

        function onUserWentOffline(userId) {
            FriendshipManager.friends.setUserOnline(userId, false)
        }
    }

    // ── Avatar colour helper ──────────────────────────────
    readonly property var avatarPalette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]

    function avatarColorFor(name) {
        return avatarPalette[name.charCodeAt(0) % avatarPalette.length]
    }

    // ── Inline tab-button component ───────────────────────
    component TabButton: Item {
        id: tabBtn

        required property string tabId
        required property string label

        readonly property bool isActive: root.activeTab === tabId

        signal tabClicked(string id)

        implicitWidth: tabLabel.implicitWidth + 16
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: tabBtn.isActive
                   ? Qt.rgba(1, 1, 1, 0.1)
                   : (tabHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text:  tabBtn.label
            color: tabBtn.isActive ? Theme.textPrimary : Theme.textMuted
            font.pixelSize: 14
            font.weight:    tabBtn.isActive ? Font.DemiBold : Font.Normal
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        // Active underline
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height:  2
            radius:  1
            color:   Theme.textPrimary
            visible: tabBtn.isActive
        }

        HoverHandler { id: tabHover }
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    tabBtn.tabClicked(tabBtn.tabId)
        }
    }

    // ── Layout ────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top bar ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredHeight: 48
            color: "transparent"

            // Bottom separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: 1
                color:  Theme.surfaceBorder
            }

            RowLayout {
                anchors.fill:        parent
                anchors.leftMargin:  16
                anchors.rightMargin: 16
                spacing: 4

                Image {
                    source: "/assets/icons/group.svg"
                    width:     18
                    height:    18

                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                    
                    smooth: true
                    mipmap: true
                    Layout.preferredWidth:  18
                    Layout.preferredHeight: 18
                }

                Text {
                    text:           "Friends"
                    color:          Theme.textPrimary
                    font.pixelSize: 15
                    font.weight:    Font.DemiBold
                    leftPadding:    4
                    rightPadding:   4
                }

                // Vertical divider
                Rectangle { width: 1; height: 24; color: Theme.surfaceBorder }

                Item { width: 4 }

                // Sub-tabs
                TabButton { tabId: "online";  label: "Online";  onTabClicked: (id) => root.activeTab = id }
                TabButton { tabId: "all";     label: "All";     onTabClicked: (id) => root.activeTab = id }
                TabButton { tabId: "pending"; label: "Pending"; onTabClicked: (id) => root.activeTab = id }
                TabButton { tabId: "blocked"; label: "Blocked"; onTabClicked: (id) => root.activeTab = id }

                Item { width: 4 }

                // "Add Friend" — styled differently (accent button when inactive)
                Rectangle {
                    Layout.alignment:   Qt.AlignVCenter
                    implicitWidth:      addFriendLabel.implicitWidth + 24
                    height:             32
                    radius:             4
                    color: root.activeTab === "add"
                           ? Qt.rgba(0x23/255.0, 0xa5/255.0, 0x59/255.0, 0.25)
                           : Theme.accentGreen
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: addFriendLabel
                        anchors.centerIn: parent
                        text:           "Add Friend"
                        color:          root.activeTab === "add" ? Theme.accentGreen : "#ffffff"
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.activeTab = "add"
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ── Section count label (list tabs only) ──────────
        Text {
            visible: root.activeTab !== "add"
            Layout.leftMargin:   32
            Layout.topMargin:    20
            Layout.bottomMargin: 8
            text: {
                const counts = {
                    "online":  FriendshipManager.friends.onlineCount,
                    "all":     FriendshipManager.friends.count,
                    "pending": FriendshipManager.pendingRequests.count,
                    "blocked": FriendshipManager.blockedUsers.count
                }
                const labels = {
                    "online":  "ONLINE",
                    "all":     "ALL FRIENDS",
                    "pending": "PENDING",
                    "blocked": "BLOCKED"
                }
                return (labels[root.activeTab] ?? "") + " — " + (counts[root.activeTab] ?? 0)
            }
            color:              Theme.textSubtle
            font.pixelSize:     11
            font.weight:        Font.DemiBold
            font.letterSpacing: 0.5
        }

        // ── Add Friend form ───────────────────────────────
        ColumnLayout {
            visible: root.activeTab === "add"
            Layout.fillWidth:   true
            Layout.leftMargin:  32
            Layout.rightMargin: 32
            Layout.topMargin:   24
            spacing: 8

            Text {
                text:           "ADD FRIEND"
                color:          Theme.textPrimary
                font.pixelSize: 20
                font.weight:    Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text:           "You can add a friend with their username."
                color:          Theme.textMuted
                font.pixelSize: 14
                wrapMode:       Text.Wrap
            }

            // Input row
            Rectangle {
                Layout.fillWidth:  true
                Layout.topMargin:  8
                height: 52
                radius: 8
                color:  Theme.surfaceMid

                RowLayout {
                    anchors.fill:        parent
                    anchors.leftMargin:  16
                    anchors.rightMargin: 8
                    spacing: 8

                    // Placeholder text sits behind the input
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible:        addFriendInput.text.length === 0 && !addFriendInput.activeFocus
                            text:           "Enter a username\u2026"
                            color:          Theme.textSubtle
                            font.pixelSize: 15
                        }

                        TextInput {
                            id: addFriendInput
                            anchors.fill:         parent
                            anchors.topMargin:    1
                            color:                Theme.textPrimary
                            font.pixelSize:       15
                            selectionColor:       "#8a93f7"
                            selectedTextColor:    Theme.textPrimary
                            clip:                 true
                            verticalAlignment:    TextInput.AlignVCenter
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth:    sendLabel.implicitWidth + 24
                        height:           36
                        radius:           4
                        color: addFriendInput.text.length > 0 ? Theme.accentBlue
                                                              : Qt.rgba(0.345, 0.396, 0.949, 0.35)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: sendLabel
                            anchors.centerIn: parent
                            text:           "Send Friend Request"
                            color:          "#ffffff"
                            font.pixelSize: 13
                            font.weight:    Font.Medium
                            opacity:        addFriendInput.text.length > 0 ? 1.0 : 0.5
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled:      addFriendInput.text.length > 0
                            cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked:    FriendshipManager.sendFriendRequest(addFriendInput.text)
                        }
                    }
                }
            }
        }

        // ── List area (friends + pending share the same slot) ─────────────────
        Item {
            visible:          root.activeTab !== "add"
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Friends list (online / all tabs) ────────────────────────────────────
            ListView {
                anchors.fill: parent
                visible:      root.activeTab === "online" || root.activeTab === "all"
                clip:         true
                model:        FriendshipManager.friends

                delegate: Item {
                    id: friendDelegate

                    required property int    index
                    required property string friendshipId
                    required property string userId
                    required property string username
                    required property string email
                    required property bool   isOnline

                    readonly property string avatarColor: root.avatarColorFor(friendDelegate.username)

                    width:  ListView.view.width
                    height: (root.activeTab === "online" && !friendDelegate.isOnline) ? 0 : 62
                    visible: height > 0
                    clip:    true

                    Behavior on height { NumberAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.fill:        parent
                        anchors.leftMargin:  8
                        anchors.rightMargin: 8
                        radius: 8
                        color:  friendHover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        // Divider between rows (hidden on hover)
                        Rectangle {
                            visible: !friendHover.hovered && friendDelegate.index > 0
                            anchors.top:         parent.top
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            height: 1
                            color:  Theme.surfaceBorder
                        }

                        RowLayout {
                            anchors.fill:        parent
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Avatar + status dot
                            Item {
                                width: 40; height: 40

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color:  friendDelegate.avatarColor

                                    Text {
                                        anchors.centerIn: parent
                                        text:           friendDelegate.username.charAt(0).toUpperCase()
                                        color:          "#ffffff"
                                        font.pixelSize: 16
                                        font.weight:    Font.DemiBold
                                    }
                                }

                                // Presence status dot
                                Rectangle {
                                    anchors.right:  parent.right
                                    anchors.bottom: parent.bottom
                                    width: 14; height: 14; radius: 7
                                    color: Theme.surfaceRaised

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10; height: 10; radius: 5
                                        color: friendDelegate.isOnline ? "#23a559" : "#80848e"
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    }
                                }
                            }

                            // Name + email
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text:           friendDelegate.username
                                    color:          Theme.textPrimary
                                    font.pixelSize: 15
                                    font.weight:    Font.DemiBold
                                    elide:          Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text:           friendDelegate.email
                                    color:          Theme.textMuted
                                    font.pixelSize: 13
                                    elide:          Text.ElideRight
                                }
                            }

                            // Action buttons — visible on hover
                            Row {
                                visible: friendHover.hovered
                                spacing: 8

                                // Message button
                                Item {
                                    width: 36; height: 36

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 18
                                        color:  msgHover.hovered ? Theme.surfaceMid : Theme.surfaceBorder
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        Image {
                                            anchors.centerIn: parent
                                            source: "/assets/icons/chat_bubble.svg"
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

                                    HoverHandler { id: msgHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked:    root.dmRequested(friendDelegate.userId, friendDelegate.username)
                                    }
                                }

                                // Remove friend button
                                Item {
                                    id: removeItem
                                    width: 36; height: 36

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 18
                                        color:  removeHover.hovered ? Theme.surfaceMid : Theme.surfaceBorder
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        Image {
                                            anchors.centerIn: parent
                                            source: "/assets/icons/delete.svg"
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

                                    HoverHandler { id: removeHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked:    FriendshipManager.removeFriend(friendDelegate.friendshipId)
                                    }
                                }
                            }
                        }
                    }

                    HoverHandler { id: friendHover }
                }
            }

            // ── Pending list ──────────────────────────────────────────────────
            ListView {
                anchors.fill: parent
                visible:      root.activeTab === "pending"
                clip:         true
                model:        FriendshipManager.pendingRequests

                delegate: Item {
                    id: pendingDelegate

                    required property int    index
                    required property string friendshipId
                    required property string username
                    required property string direction   // "incoming" | "outgoing"

                    readonly property string avatarColor:  root.avatarColorFor(pendingDelegate.username)
                    readonly property string statusLabel:  pendingDelegate.direction === "incoming"
                                                           ? "Incoming" : "Outgoing"
                    readonly property string statusColor:  pendingDelegate.direction === "incoming"
                                                           ? "#5865F2" : "#80848e"

                    width:  ListView.view.width
                    height: 62

                    Rectangle {
                        anchors.fill:        parent
                        anchors.leftMargin:  8
                        anchors.rightMargin: 8
                        radius: 8
                        color:  pendingHover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        // Divider between rows (hidden on hover)
                        Rectangle {
                            visible: !pendingHover.hovered && pendingDelegate.index > 0
                            anchors.top:         parent.top
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            height: 1
                            color:  Theme.surfaceBorder
                        }

                        RowLayout {
                            anchors.fill:        parent
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Avatar + direction dot
                            Item {
                                width: 40; height: 40

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color:  pendingDelegate.avatarColor

                                    Text {
                                        anchors.centerIn: parent
                                        text:           pendingDelegate.username.charAt(0).toUpperCase()
                                        color:          "#ffffff"
                                        font.pixelSize: 16
                                        font.weight:    Font.DemiBold
                                    }
                                }

                                // Direction dot with border ring
                                Rectangle {
                                    anchors.right:  parent.right
                                    anchors.bottom: parent.bottom
                                    width: 14; height: 14; radius: 7
                                    color: Theme.surfaceRaised

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10; height: 10; radius: 5
                                        color: pendingDelegate.statusColor
                                    }
                                }
                            }

                            // Name + status label
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text:           pendingDelegate.username
                                    color:          Theme.textPrimary
                                    font.pixelSize: 15
                                    font.weight:    Font.DemiBold
                                    elide:          Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text:           pendingDelegate.statusLabel + " Friend Request"
                                    color:          Theme.textMuted
                                    font.pixelSize: 13
                                    elide:          Text.ElideRight
                                }
                            }

                            // Accept / reject / cancel buttons — visible on hover
                            Row {
                                visible: pendingHover.hovered
                                spacing: 8

                                Repeater {
                                    model: pendingDelegate.direction === "incoming" ? ["✓", "✕"] : ["✕"]

                                    delegate: Item {
                                        id: actionItem

                                        required property string modelData
                                        required property int    index

                                        width: 36; height: 36

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 18
                                            color:  actionHover.hovered ? Theme.surfaceMid : Theme.surfaceBorder
                                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                            Text {
                                                anchors.centerIn: parent
                                                text:           actionItem.modelData
                                                font.pixelSize: 14
                                                color:          Theme.textPrimary
                                            }
                                        }

                                        HoverHandler { id: actionHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape:  Qt.PointingHandCursor
                                            onClicked: {
                                                const fid = pendingDelegate.friendshipId
                                                const isIncoming = pendingDelegate.direction === "incoming"
                                                if (actionItem.modelData === "✓") {
                                                    FriendshipManager.acceptRequest(fid)
                                                } else if (isIncoming) {
                                                    FriendshipManager.rejectRequest(fid)
                                                } else {
                                                    FriendshipManager.cancelRequest(fid)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    HoverHandler { id: pendingHover }
                }
            }

            // ── Blocked list ──────────────────────────────────────────────────
            ListView {
                anchors.fill: parent
                visible:      root.activeTab === "blocked"
                clip:         true
                model:        FriendshipManager.blockedUsers

                delegate: Item {
                    id: blockedDelegate

                    required property int    index
                    required property string userId
                    required property string username
                    required property string email

                    readonly property string avatarColor: root.avatarColorFor(blockedDelegate.username)

                    width:  ListView.view.width
                    height: 62

                    Rectangle {
                        anchors.fill:        parent
                        anchors.leftMargin:  8
                        anchors.rightMargin: 8
                        radius: 8
                        color:  blockedHover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        // Divider between rows (hidden on hover)
                        Rectangle {
                            visible: !blockedHover.hovered && blockedDelegate.index > 0
                            anchors.top:         parent.top
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            height: 1
                            color:  Theme.surfaceBorder
                        }

                        RowLayout {
                            anchors.fill:        parent
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Avatar (greyed out to indicate blocked state)
                            Rectangle {
                                width: 40; height: 40
                                radius: 20
                                color:  Qt.rgba(0.5, 0.5, 0.5, 0.4)

                                Text {
                                    anchors.centerIn: parent
                                    text:           blockedDelegate.username.charAt(0).toUpperCase()
                                    color:          "#ffffff"
                                    font.pixelSize: 16
                                    font.weight:    Font.DemiBold
                                }
                            }

                            // Name + email
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text:           blockedDelegate.username
                                    color:          Theme.textMuted
                                    font.pixelSize: 15
                                    font.weight:    Font.DemiBold
                                    elide:          Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text:           blockedDelegate.email
                                    color:          Theme.textSubtle
                                    font.pixelSize: 13
                                    elide:          Text.ElideRight
                                }
                            }

                            // Unblock button — visible on hover
                            Item {
                                visible: blockedHover.hovered
                                width:   unblockLabel.implicitWidth + 24
                                height:  32

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 4
                                    color:  unblockBtnHover.hovered ? "#ed4245" : Theme.surfaceBorder
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        id: unblockLabel
                                        anchors.centerIn: parent
                                        text:           "Unblock"
                                        color:          unblockBtnHover.hovered ? "#ffffff" : Theme.textPrimary
                                        font.pixelSize: 13
                                        font.weight:    Font.Medium
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    }
                                }

                                HoverHandler { id: unblockBtnHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked:    FriendshipManager.unblockUser(blockedDelegate.userId)
                                }
                            }
                        }
                    }

                    HoverHandler { id: blockedHover }
                }
            }
        }
    }
}


pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components/friends"

Rectangle {
    id: root

    color: Theme.surfaceRaised

    signal dmRequested(string recipientId, string recipientName)

    property string currentTab: "online"

    readonly property string addFriendTabId: "add"
    readonly property bool showingAddFriendForm: currentTab === addFriendTabId
    readonly property string visibleSectionTitle: sectionTitleFor(currentTab)
    readonly property int visibleSectionCount: sectionCountFor(currentTab)
    readonly property var tabsModel: [
        { "id": "online", "label": "Online" },
        { "id": "all", "label": "All" },
        { "id": "pending", "label": "Pending" },
        { "id": "blocked", "label": "Blocked" }
    ]
    readonly property var avatarPalette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]

    function loadInitialData() {
        FriendshipManager.fetchFriends()
        FriendshipManager.fetchPendingRequests()
    }

    function syncOnlineUsers() {
        FriendshipManager.friends.setOnlineUsersList(PresenceManager.onlineUserIds())
    }

    function sectionTitleFor(tabId) {
        switch (tabId) {
        case "online":
            return "ONLINE"
        case "all":
            return "ALL FRIENDS"
        case "pending":
            return "PENDING"
        case "blocked":
            return "BLOCKED"
        default:
            return ""
        }
    }

    function sectionCountFor(tabId) {
        switch (tabId) {
        case "online":
            return FriendshipManager.friends.onlineCount
        case "all":
            return FriendshipManager.friends.count
        case "pending":
            return FriendshipManager.pendingRequests.count
        case "blocked":
            return FriendshipManager.blockedUsers.count
        default:
            return 0
        }
    }

    function avatarColorForName(displayName) {
        if (!displayName || displayName.length === 0)
            return avatarPalette[0]

        return avatarPalette[displayName.charCodeAt(0) % avatarPalette.length]
    }

    Component.onCompleted: loadInitialData()

    onCurrentTabChanged: {
        if (currentTab === "blocked")
            FriendshipManager.fetchBlockedUsers()
    }

    Connections {
        target: FriendshipManager

        function onFriendRequestSent() {
            addFriendPanel.clearInput()
            root.currentTab = "pending"
            FriendshipManager.fetchPendingRequests()
        }

        function onRequestAccepted() {
            FriendshipManager.fetchFriends()
        }
    }

    Connections {
        target: PresenceManager

        function onOnlineUsersChanged() {
            root.syncOnlineUsers()
        }

        function onUserWentOnline(userId) {
            FriendshipManager.friends.setUserOnline(userId, true)
        }

        function onUserWentOffline(userId) {
            FriendshipManager.friends.setUserOnline(userId, false)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        FriendsHeaderBar {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: headerBar.implicitHeight
            currentTab: root.currentTab
            tabsModel: root.tabsModel
            onTabSelected: (tabId) => root.currentTab = tabId
            onAddFriendSelected: root.currentTab = root.addFriendTabId
        }

        Text {
            visible: !root.showingAddFriendForm
            Layout.leftMargin: 32
            Layout.topMargin: 20
            Layout.bottomMargin: 8
            text: root.visibleSectionTitle + " - " + root.visibleSectionCount
            color: Theme.textSubtle
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
        }

        AddFriendPanel {
            id: addFriendPanel
            visible: root.showingAddFriendForm
            Layout.fillWidth: true
            Layout.leftMargin: 32
            Layout.rightMargin: 32
            Layout.topMargin: 24
            onSubmitRequested: (username) => FriendshipManager.sendFriendRequest(username)
        }

        Item {
            visible: !root.showingAddFriendForm
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                visible: root.currentTab === "online" || root.currentTab === "all"
                clip: true
                model: FriendshipManager.friends

                delegate: FriendRow {
                    required property int index
                    required property var model

                    listIndex: index
                    onlineOnly: root.currentTab === "online"
                    avatarColor: root.avatarColorForName(model.username)
                    onDmRequested: (recipientId, recipientName) => root.dmRequested(recipientId, recipientName)
                    onRemoveRequested: (friendshipId) => FriendshipManager.removeFriend(friendshipId)
                }
            }

            ListView {
                anchors.fill: parent
                visible: root.currentTab === "pending"
                clip: true
                model: FriendshipManager.pendingRequests

                delegate: PendingRequestRow {
                    required property int index
                    required property var model

                    listIndex: index
                    avatarColor: root.avatarColorForName(model.username)
                    onAcceptRequested: (friendshipId) => FriendshipManager.acceptRequest(friendshipId)
                    onRejectRequested: (friendshipId) => FriendshipManager.rejectRequest(friendshipId)
                    onCancelRequested: (friendshipId) => FriendshipManager.cancelRequest(friendshipId)
                }
            }

            ListView {
                anchors.fill: parent
                visible: root.currentTab === "blocked"
                clip: true
                model: FriendshipManager.blockedUsers

                delegate: BlockedUserRow {
                    required property int index

                    listIndex: index
                    onUnblockRequested: (userId) => FriendshipManager.unblockUser(userId)
                }
            }
        }
    }
}


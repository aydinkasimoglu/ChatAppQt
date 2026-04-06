import QtQuick
import QtQuick.Layouts

// MainView: thin orchestration layer.
// Owns shared state (dialog open/closed, selected view) and wires child signals together.
// Contains NO layout logic of its own beyond the top-level split.
Item {
    id: root

    // ── Shared state ──────────────────────────────────────
    property bool   dialogOpen:     false
    property string selectedView:   "friends"   // "friends" | "dm"
    property string selectedDmId:   ""
    property string selectedDmName: ""

    // ── Main content (blurred when dialog opens) ──────────
    Item {
        id: mainContent
        anchors.fill: parent
        enabled: !root.dialogOpen

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left rail
            SidePanel {
                id: sidePanel
                Layout.fillHeight: true
                onAddServerRequested: {
                    root.dialogOpen = true
                }
                onServerSelected: (index, name, serverId) => {
                    console.log("Selected server:", name, serverId)
                }
                onLogoutRequested: {
                    AuthClient.logout()
                }
            }

            // Mid panel — DM list + Friends nav
            MidPanel {
                id: midPanel
                Layout.fillHeight: true
                activeItemId: root.selectedView === "friends" ? "friends" : root.selectedDmId
                onFriendsSelected: {
                    root.selectedView   = "friends"
                    root.selectedDmId   = ""
                    root.selectedDmName = ""
                }
                onDmSelected: (dmId, username) => {
                    root.selectedDmId   = dmId
                    root.selectedDmName = username
                    root.selectedView   = "dm"
                }
            }

            // ── Main content area ─────────────────────────
            Item {
                Layout.fillWidth:  true
                Layout.fillHeight: true

                // Friends view (default)
                FriendsView {
                    anchors.fill: parent
                    visible:      root.selectedView === "friends"
                    onDmRequested: (recipientId, recipientName) => {
                        root.selectedDmId   = recipientId
                        root.selectedDmName = recipientName
                        root.selectedView   = "dm"
                    }
                }

                // DM conversation view
                DmView {
                    anchors.fill: parent
                    visible:      root.selectedView === "dm"
                    recipientId:   root.selectedDmId
                    recipientName: root.selectedDmName
                }
            }
        }

        // Click-to-unfocus: observe every mouse press before child controls,
        // then pass the event through without changing the cursor shape.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            cursorShape: undefined

            onPressed: (mouse) => {
                mainContent.forceActiveFocus()
                mouse.accepted = false
            }
        }
    }

    // ── Blur overlay + dialog ─────────────────────────────
    Connections {
        target: ServerManager
        function onServerCreated() {
            dialog.busy = false
            root.dialogOpen = false
            dialog.reset()
            ToastManager.showSuccess("Server created!")
        }
        function onServerCreateFailed(message) {
            dialog.busy = false
            ToastManager.showError(message)
        }
    }

    BlurOverlay {
        anchors.fill: parent
        active:       root.dialogOpen
        blurSource:   mainContent

        onBackgroundClicked: root.dialogOpen = false

        dialogContent: CreateServerDialog {
            id: dialog

            onAccepted: (serverName, isPublic, description) => {
                dialog.busy = true
                ServerManager.createServer(serverName, isPublic, description)
            }

            onRejected: {
                root.dialogOpen = false
                dialog.reset()
            }
        }
    }
}

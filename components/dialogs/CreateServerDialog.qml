import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// The "Create Your Server" dialog card.
// This component is ONLY the card — it knows nothing about blur/overlay.
// Drop it inside a BlurOverlay's dialogContent slot.
//
// Signals:
//   accepted(serverName, isPublic, description)  — user clicked Create
//   rejected()                                   — user clicked Back

Rectangle {
    id: root

    // ── Public API ────────────────────────────────────────
    signal accepted(string serverName, bool isPublic, string description)
    signal rejected()

    function reset() {
        serverNameInput.text = AuthClient.username + "'s Server"
        descriptionInput.text = ""
        publicSwitch.checked = false
    }

    // ── State ─────────────────────────────────────────────
    property bool busy: false

    // ── Appearance ────────────────────────────────────────
    width:  440
    height: 460
    color:  Theme.surfaceRaised
    radius: 8

    // Dims all content and blocks interaction while the request is in-flight
    MouseArea {
        anchors.fill: parent
        visible:      root.busy
        z:            10
        hoverEnabled: true
        cursorShape:  Qt.ForbiddenCursor
    }

    // ── Content ───────────────────────────────────────────
    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: 24
        spacing:         16

        opacity: root.busy ? 0.45 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Title
        Text {
            text:             "Create Your Server"
            font.pixelSize:   24
            font.bold:        true
            color:            Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }

        // Subtitle
        Text {
            text: "Your server is where you and your friends hang out. " +
                  "Make yours and start talking."
            font.pixelSize:      14
            color:               Theme.textMuted
            wrapMode:            Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth:    true
        }

        Item { Layout.preferredHeight: 4 }

        // ── Server name input ─────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                spacing: 4

                Text {
                    text:           "SERVER NAME"
                    font.pixelSize: 12
                    font.bold:      true
                    color:          Theme.textMuted
                }

                Text {
                    text:           "*"
                    font.pixelSize: 12
                    font.bold:      true
                    color:          "#ed4245"  // Discord-style danger red
                }
            }

            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: 40
                color:                  Theme.surfaceDeep
                radius:                 4

                // Focus ring — mirrors description field behaviour
                border.color: serverNameInput.activeFocus
                              ? Theme.accentBlue
                              : "transparent"
                border.width: 1

                TextField {
                    id: serverNameInput
                    anchors.fill:         parent
                    anchors.margins:      1
                    text:                 AuthClient.username + "'s Server"
                    color:                Theme.textSecondary
                    placeholderTextColor: Theme.textSubtle
                    font.pixelSize:       15
                    background:           null  // Rectangle above provides bg
                }
            }
        }

        // ── Description input ─────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text:           "DESCRIPTION"
                font.pixelSize: 12
                font.bold:      true
                color:          Theme.textMuted
            }

            // Multiline text area
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: 72
                color:                  Theme.surfaceDeep
                radius:                 4

                // Focus ring
                border.color: descriptionInput.activeFocus
                              ? Theme.accentBlue
                              : "transparent"
                border.width: 1

                ScrollView {
                    anchors.fill:    parent
                    anchors.margins: 1
                    clip:            true

                    // Hide scrollbar unless needed
                    ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    TextArea {
                        id: descriptionInput
                        width:               parent.width
                        wrapMode:            TextArea.Wrap
                        color:               Theme.textSecondary
                        placeholderText:     "Give your server a description…"
                        placeholderTextColor: Theme.textSubtle
                        font.pixelSize:      14
                        topPadding:          8
                        bottomPadding:       8
                        leftPadding:         10
                        rightPadding:        10
                        background:          null  // Rectangle above provides bg
                    }
                }
            }
        }

        // ── Visibility toggle ─────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            ColumnLayout {
                spacing: 2

                Text {
                    text:           "PUBLIC SERVER"
                    font.pixelSize: 12
                    font.bold:      true
                    color:          Theme.textMuted
                }

                Text {
                    text:           "Anyone can join without an invite link"
                    font.pixelSize: 12
                    color:          Theme.textSubtle
                }
            }

            Item { Layout.fillWidth: true }

            ThemedSwitch {
                id: publicSwitch
                checked: false
            }
        }

        Item { Layout.fillHeight: true }

        // ── Buttons ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text:           "Back"
                color:          Theme.textSecondary
                font.pixelSize: 14

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.rejected()
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width:  96
                height: 38
                color:  Theme.accentBlue
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text:           "Create"
                    color:          "#ffffff"
                    font.bold:      true
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.accepted(
                                      serverNameInput.text,
                                      publicSwitch.checked,
                                      descriptionInput.text
                                  )
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../.."

ColumnLayout {
    id: root

    property alias username: usernameInput.text
    readonly property bool canSubmit: usernameInput.text.length > 0

    signal submitRequested(string username)

    function clearInput() {
        usernameInput.text = ""
    }

    spacing: 8

    Text {
        text: "ADD FRIEND"
        color: Theme.textPrimary
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }

    Text {
        Layout.fillWidth: true
        text: "You can add a friend with their username."
        color: Theme.textMuted
        font.pixelSize: 14
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: 52
        radius: 8
        color: Theme.surfaceMid

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: usernameInput.text.length === 0 && !usernameInput.activeFocus
                    text: "Enter a username..."
                    color: Theme.textSubtle
                    font.pixelSize: 15
                }

                TextInput {
                    id: usernameInput
                    anchors.fill: parent
                    anchors.topMargin: 1
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    selectionColor: "#8a93f7"
                    selectedTextColor: Theme.textPrimary
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                }
            }

            FriendsTextButton {
                Layout.alignment: Qt.AlignVCenter
                text: "Send Friend Request"
                enabled: root.canSubmit
                normalColor: Theme.accentBlue
                hoverColor: Theme.accentBlue
                disabledColor: Qt.rgba(0.345, 0.396, 0.949, 0.35)
                normalTextColor: "#ffffff"
                hoverTextColor: "#ffffff"
                disabledTextColor: "#ffffff"
                buttonHeight: 36
                onClicked: root.submitRequested(usernameInput.text)
            }
        }
    }
}
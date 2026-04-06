pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "."
import "../.."

Rectangle {
    id: root

    required property string currentTab
    property var tabsModel: []

    signal tabSelected(string tabId)
    signal addFriendSelected()

    implicitHeight: 48
    color: "transparent"

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.surfaceBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 4

        Image {
            source: "/assets/icons/group.svg"
            width: 18
            height: 18
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            smooth: true
            mipmap: true
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
        }

        Text {
            text: "Friends"
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.DemiBold
            leftPadding: 4
            rightPadding: 4
        }

        Rectangle {
            width: 1
            height: 24
            color: Theme.surfaceBorder
        }

        Item {
            width: 4
        }

        Repeater {
            model: root.tabsModel

            delegate: FriendsTabButton {
                required property var modelData

                tabId: modelData.id
                label: modelData.label
                current: root.currentTab === modelData.id
                onClicked: (selectedTabId) => root.tabSelected(selectedTabId)
            }
        }

        Item {
            width: 4
        }

        FriendsTextButton {
            Layout.alignment: Qt.AlignVCenter
            text: "Add Friend"
            normalColor: root.currentTab === "add"
                         ? Qt.rgba(0x23 / 255.0, 0xa5 / 255.0, 0x59 / 255.0, 0.25)
                         : Theme.accentGreen
            hoverColor: normalColor
            normalTextColor: root.currentTab === "add" ? Theme.accentGreen : "#ffffff"
            hoverTextColor: normalTextColor
            onClicked: root.addFriendSelected()
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
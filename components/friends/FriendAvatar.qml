pragma ComponentBehavior: Bound
import QtQuick
import "../.."

Item {
    id: root

    required property string name
    property color backgroundColor: Theme.accentBlue
    property bool showIndicator: false
    property color indicatorColor: "#23a559"
    property color indicatorRingColor: Theme.surfaceRaised
    property int avatarSize: 40
    property int indicatorSize: 14
    property int indicatorInnerSize: 10

    readonly property string initial: name.length > 0 ? name.charAt(0).toUpperCase() : "?"

    width: avatarSize
    height: avatarSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.backgroundColor

        Text {
            anchors.centerIn: parent
            text: root.initial
            color: "#ffffff"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        visible: root.showIndicator
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.indicatorSize
        height: root.indicatorSize
        radius: width / 2
        color: root.indicatorRingColor

        Rectangle {
            anchors.centerIn: parent
            width: root.indicatorInnerSize
            height: root.indicatorInnerSize
            radius: width / 2
            color: root.indicatorColor

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }
}
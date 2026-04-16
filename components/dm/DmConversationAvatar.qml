pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property string name
    property string fallbackInitial: "?"
    property int avatarSize: 40
    property int fontPixelSize: Math.max(13, Math.round(root.avatarSize * 0.39))
    property color textColor: "#ffffff"
    property var avatarPalette: [
        "#5865F2", "#57F287", "#FEE75C", "#EB459E",
        "#ED4245", "#5DADE2", "#9B59B6", "#23a559"
    ]

    readonly property string initial: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : root.fallbackInitial
    readonly property color backgroundColor: {
        if (!root.name || root.name.length === 0)
            return root.avatarPalette[0]

        return root.avatarPalette[root.name.charCodeAt(0) % root.avatarPalette.length]
    }

    width: root.avatarSize
    height: root.avatarSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.backgroundColor

        Text {
            anchors.centerIn: parent
            text: root.initial
            color: root.textColor
            font.pixelSize: root.fontPixelSize
            font.weight: Font.DemiBold
        }
    }
}
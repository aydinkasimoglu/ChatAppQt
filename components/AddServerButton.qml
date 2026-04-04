import QtQuick

// The "+" pill that lives at the top of the server rail.
// Emits `clicked` when pressed.
Item {
    id: root

    signal clicked()

    width:  Theme.serverIconSize
    height: Theme.serverIconSize

    Rectangle {
        anchors.centerIn: parent
        width:  Theme.serverIconSize
        height: Theme.serverIconSize

        radius: hoverArea.containsMouse ? Theme.serverIconRadiusHover
                                        : Theme.serverIconRadius

        color:  hoverArea.containsMouse ? Theme.accentGreen
                                        : Theme.surfaceRaised

        Behavior on radius { NumberAnimation { duration: Theme.animFast } }
        Behavior on color  { ColorAnimation  { duration: Theme.animFast } }

        Text {
            anchors.centerIn: parent
            text:      "+"
            color:     hoverArea.containsMouse ? "#ffffff" : Theme.accentGreen
            font.pixelSize: 32
            font.weight:    Font.Light

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}

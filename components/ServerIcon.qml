import QtQuick

// A single animated server icon blob.
// Shows the first letter of `serverName` on a colored pill.
// Morphs between circle and rounded-square on hover.
Item {
    id: root

    // ── Public API ────────────────────────────────────────
    property string serverName:  "S"
    property color  accentColor: Theme.accentBlue
    property bool   isSelected:  false

    signal clicked()

    // ── Size ──────────────────────────────────────────────
    width:  Theme.serverIconSize
    height: Theme.serverIconSize

    // ── Pill ──────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.centerIn: parent
        width:  Theme.serverIconSize
        height: Theme.serverIconSize

        radius: (hoverArea.containsMouse || root.isSelected)
                ? Theme.serverIconRadiusHover
                : Theme.serverIconRadius

        color: (hoverArea.containsMouse || root.isSelected)
               ? root.accentColor
               : Theme.surfaceRaised

        Behavior on radius { NumberAnimation { duration: Theme.animFast } }
        Behavior on color  { ColorAnimation  { duration: Theme.animFast } }

        // Selection indicator bar on left edge
        Rectangle {
            anchors.left:            parent.left
            anchors.verticalCenter:  parent.verticalCenter
            anchors.leftMargin:      -4
            width:  4
            height: root.isSelected ? 40 : (hoverArea.containsMouse ? 20 : 0)
            radius: 2
            color:  Theme.textPrimary

            Behavior on height { NumberAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.centerIn: parent
            text:             root.serverName.charAt(0).toUpperCase()
            color:            Theme.textSecondary
            font.pixelSize:   20
            font.bold:        true
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill:  parent
        hoverEnabled:  true
        cursorShape:   Qt.PointingHandCursor
        onClicked:     root.clicked()
    }
}

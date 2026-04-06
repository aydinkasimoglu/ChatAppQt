pragma ComponentBehavior: Bound
import QtQuick
import "../.."

Item {
    id: root

    property string text: ""
    property color normalColor: Theme.surfaceBorder
    property color hoverColor: normalColor
    property color disabledColor: normalColor
    property color normalTextColor: Theme.textPrimary
    property color hoverTextColor: normalTextColor
    property color disabledTextColor: normalTextColor
    property int horizontalPadding: 12
    property int buttonHeight: 32
    property int radius: 4
    property real disabledTextOpacity: 0.5

    signal clicked()

    implicitWidth: buttonLabel.implicitWidth + (horizontalPadding * 2)
    implicitHeight: buttonHeight

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: !root.enabled
               ? root.disabledColor
               : (hoverHandler.hovered ? root.hoverColor : root.normalColor)

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Text {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.text
        color: !root.enabled
               ? root.disabledTextColor
               : (hoverHandler.hovered ? root.hoverTextColor : root.normalTextColor)
        font.pixelSize: 13
        font.weight: Font.Medium
        opacity: root.enabled ? 1.0 : root.disabledTextOpacity

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
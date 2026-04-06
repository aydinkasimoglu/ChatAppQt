pragma ComponentBehavior: Bound
import QtQuick
import "../.."

Item {
    id: root

    property url iconSource: ""
    property string symbol: ""
    property int iconSize: 14
    property int symbolSize: 14
    property color normalColor: Theme.surfaceBorder
    property color hoverColor: Theme.surfaceMid
    property color disabledColor: normalColor
    property color symbolColor: Theme.textPrimary
    property color disabledSymbolColor: symbolColor

    signal clicked()

    implicitWidth: 36
    implicitHeight: 36

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: !root.enabled
               ? root.disabledColor
               : (hoverHandler.hovered ? root.hoverColor : root.normalColor)

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Image {
        anchors.centerIn: parent
        visible: root.iconSource !== ""
        source: root.iconSource
        width: root.iconSize
        height: root.iconSize
        sourceSize.width: root.iconSize * Screen.devicePixelRatio
        sourceSize.height: root.iconSize * Screen.devicePixelRatio
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
    }

    Text {
        anchors.centerIn: parent
        visible: root.iconSource === "" && root.symbol !== ""
        text: root.symbol
        color: root.enabled ? root.symbolColor : root.disabledSymbolColor
        font.pixelSize: root.symbolSize
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
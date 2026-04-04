// components/PopupMenuItem.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    // ── Public API ────────────────────────────────────────
    property string iconSource: ""
    property string label:      ""
    property color  labelColor: Theme.textPrimary
    property color  hoverColor: Qt.rgba(1, 1, 1, 0.06)

    signal clicked()

    // ── Appearance ────────────────────────────────────────
    height: 38
    radius: 6
    color:  hovered ? hoverColor : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    readonly property bool hovered: itemMouseArea.containsMouse

    // Left + right padding via internal row
    RowLayout {
        anchors {
            fill:          parent
            leftMargin:    10
            rightMargin:   10
        }
        spacing: 10

        Image {
            source:               root.iconSource
            width:     16
            height:    16

            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            
            smooth: true
            mipmap: true
            Layout.preferredWidth:  16
            Layout.preferredHeight: 16
            visible:              root.iconSource !== ""
        }

        Text {
            Layout.fillWidth: true
            text:           root.label
            color:          root.labelColor
            font.pixelSize: 14
            elide:          Text.ElideRight
        }
    }

    MouseArea {
        id:          itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
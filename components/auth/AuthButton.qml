import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Button {
    id: btn

    property bool loading: false
    property bool isLogin: true

    Layout.fillWidth: true
    Layout.preferredHeight: 40

    // Fade out the entire button when loading
    opacity: btn.loading ? 0.6 : 1.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    contentItem: Text {
        text: btn.isLogin ? "Sign In" : "Sign Up"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 16
        font.weight: Font.Bold
        color: "#FFFFFF"
    }

    background: Rectangle {
        radius: 10
        color: btn.down ? "#4F46E5" : (mouseTracker.containsMouse ? "#5A5CE6" : "#6366F1")

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true

        cursorShape: btn.loading ? Qt.ForbiddenCursor : Qt.PointingHandCursor

        onPressed: (mouse) => {
            mouse.accepted = btn.loading
        }
    }
}

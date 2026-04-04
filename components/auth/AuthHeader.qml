import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool isLogin: true

    spacing: 5
    Layout.alignment: Qt.AlignHCenter
    Layout.bottomMargin: 10

    Text {
        text: root.isLogin ? "Welcome Back" : "Create Account"
        font.pixelSize: 28
        font.weight: Font.Bold
        color: "#1E293B"
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        text: root.isLogin
              ? "Please enter your details to sign in"
              : "Register to get started"

        font.pixelSize: 14
        color: "#64748B"
        Layout.alignment: Qt.AlignHCenter
    }
}

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

TextField {
    id: field

    property bool loading: false

    Layout.fillWidth: true

    font.pixelSize: 15
    leftPadding: 15
    rightPadding: 15
    topPadding: 14
    bottomPadding: 14

    color: "#212121"
    placeholderTextColor: "#bab8b8"

    activeFocusOnTab: !field.loading
    readOnly: field.loading

    opacity: field.loading ? 0.6 : 1.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    onLoadingChanged: {
        if (loading) {
            field.focus = false
        }
    }

    background: Rectangle {
        radius: 10
        color: field.activeFocus ? "#FFFFFF" : "#F8FAFC"

        border.width: 1.5
        border.color: field.activeFocus ? "#6366F1" : "#E2E8F0"

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    MouseArea {
        anchors.fill: parent

        visible: field.loading

        hoverEnabled: true
        cursorShape: Qt.ForbiddenCursor

        // Block clicks from reaching the text field while loading
        onPressed: (mouse) => {
            mouse.accepted = true
        }
    }
}

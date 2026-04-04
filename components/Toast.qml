import QtQuick
import QtQuick.Controls

Popup {
    id: root

    property string message: ""
    property bool isError: false

    width: 250
    height: 50

    // Position vertically at the top, start horizontally outside the window
    y: 20
    x: Overlay.overlay ? Overlay.overlay.width : parent.width

    padding: 15
    closePolicy: Popup.NoAutoClose // Prevent closing by clicking outside

    background: Rectangle {
        color: root.isError ? "#F44336" : "#4CAF50"
        radius: 8
    }

    contentItem: Text {
        text: root.message
        color: "white"
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    // Slide in from the right
    enter: Transition {
        NumberAnimation {
            property: "x"
            to: (Overlay.overlay ? Overlay.overlay.width : root.parent.width) - root.width - 20
            duration: 400
            easing.type: Easing.OutBack
        }
    }

    // Fade out
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0.0
            duration: 500
        }
    }

    // Auto-close timer
    Timer {
        id: hideTimer
        interval: 3000 // 3 seconds
        running: root.opened
        onTriggered: root.close()
    }

    // Call this to trigger the toast
    function show(msg, error = false) {
        root.message = msg
        root.isError = error
        root.opacity = 1.0 // Reset opacity in case it's reused

        // Reset X position to start outside the screen
        root.x = Overlay.overlay ? Overlay.overlay.width : root.parent.width
        root.open()
    }
}

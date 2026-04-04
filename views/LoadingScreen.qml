import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        // Animated spinner
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 80
            height: 80
            color: "transparent"

            RotationAnimator {
                target: spinnerContainer
                from: 0
                to: 360
                duration: 1500
                running: true
                loops: Animation.Infinite
            }

            Rectangle {
                id: spinnerContainer
                anchors.fill: parent
                color: "transparent"
                transformOrigin: Item.Center

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        // Draw spinner circle
                        const centerX = width / 2
                        const centerY = height / 2
                        const radius = 30

                        // Background circle
                        ctx.strokeStyle = "#E0E0E0"
                        ctx.lineWidth = 4
                        ctx.beginPath()
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
                        ctx.stroke()

                        // Animated arc
                        ctx.strokeStyle = "#1E88E5"
                        ctx.lineWidth = 4
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 1.5)
                        ctx.stroke()
                    }
                }
            }
        }

        // Loading text
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Loading your data..."
            font.pixelSize: 18
            font.bold: true
            color: "#333333"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Please wait while we fetch your information"
            font.pixelSize: 14
            color: "#666666"
        }
    }
}

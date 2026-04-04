import QtQuick

// A fully custom switch that fits the dark theme.
// Drop-in replacement for QtQuick.Controls Switch.
//
// Properties:
//   checked  — bool, bindable
//   text     — label shown to the right
//   enabled  — dims and blocks interaction when false
//
// Signals:
//   toggled(bool checked)

Item {
    id: root

    property bool   checked: false
    property string text:    ""

    signal toggled(bool checked)

    implicitWidth:  label.visible ? track.width + 8 + label.implicitWidth
                                  : track.width
    implicitHeight: track.height

    opacity: root.enabled ? 1.0 : 0.4

    // ── Track ─────────────────────────────────────────────
    Rectangle {
        id: track
        width:  44
        height: 24
        radius: 12

        color: root.checked ? Theme.accentGreen : Theme.surfaceDeep

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        // Subtle inner border so it reads on dark backgrounds
        Rectangle {
            anchors.fill: parent
            radius:       parent.radius
            color:        "transparent"
            border.color: Qt.rgba(1, 1, 1, root.checked ? 0.0 : 0.08)
            border.width: 1
        }

        // ── Thumb ─────────────────────────────────────────
        Rectangle {
            id: thumb
            width:  18
            height: 18
            radius: 9
            color:  "#ffffff"

            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutCubic
                }
            }

            // Subtle drop shadow on the thumb
            layer.enabled: true
            layer.effect: null  // replace with MultiEffect if shadow is needed

            // Scale down slightly on press for tactile feel
            scale: tapHandler.pressed ? 0.85 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 80 }
            }
        }
    }

    // ── Label ─────────────────────────────────────────────
    Text {
        id: label
        anchors.left:           track.right
        anchors.leftMargin:     8
        anchors.verticalCenter: track.verticalCenter
        text:                   root.text
        visible:                root.text.length > 0
        color:                  Theme.textSecondary
        font.pixelSize:         14
    }

    // ── Interaction ───────────────────────────────────────
    TapHandler {
        id: tapHandler
        enabled:   root.enabled
        onTapped: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.enabled
    }

    // Pointer cursor over the whole item
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}

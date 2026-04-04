import QtQuick
import QtQuick.Effects

// A reusable fullscreen blur + dark-tint overlay.
// Wrap any popup with this; put your dialog content inside `dialogContent`.
//
// Usage:
//   BlurOverlay {
//       anchors.fill: parent
//       active: myBoolProperty
//       blurSource: mainContent        // the Item to blur behind
//       onBackgroundClicked: active = false
//
//       dialogContent: MyDialog { ... }
//   }

Item {
    id: root

    // ── Public API ────────────────────────────────────────
    property bool   active:     false
    property Item   blurSource: null       // Item that gets blurred
    property alias  dialogContent: contentSlot.data

    signal backgroundClicked()

    // ── Blur layer ────────────────────────────────────────
    // Must be sized/positioned in root's coordinate space,
    // not with anchors.fill on a foreign Item.
    MultiEffect {
        x:      root.blurSource ? root.blurSource.x      : 0
        y:      root.blurSource ? root.blurSource.y      : 0
        width:  root.blurSource ? root.blurSource.width  : 0
        height: root.blurSource ? root.blurSource.height : 0
        source:      root.blurSource
        blurEnabled: true
        blurMax:     32
        blur:        overlay.opacity
        visible:     overlay.visible
    }

    // ── Tint + interaction blocker ────────────────────────
    Rectangle {
        id: overlay
        anchors.fill: parent
        color:   Qt.rgba(0, 0, 0, 0.6)
        opacity: root.active ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked:    root.backgroundClicked()
            onWheel: (wheel) => wheel.accepted = true
        }

        // ── Dialog content slot ───────────────────────────
        // childrenRect gives us the actual size of whatever
        // is placed inside, so centering works correctly.
        Item {
            id: contentSlot
            anchors.centerIn: parent
            width:  childrenRect.width
            height: childrenRect.height

            scale: root.active ? 1.0 : 0.9
            Behavior on scale {
                NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutBack }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
}

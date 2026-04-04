pragma Singleton
import QtQuick

QtObject {
    // ── Surfaces ──────────────────────────────────────────
    readonly property color surfaceDeep:    "#1e1f22"
    readonly property color surfaceMid:     "#2b2d31"
    readonly property color surfaceRaised:  "#313338"
    readonly property color surfaceBorder:  "#35363c"
    readonly property color surfaceHover:   "#35373c"

    // ── Text ──────────────────────────────────────────────
    readonly property color textPrimary:    "#f2f3f5"
    readonly property color textSecondary:  "#dbdee1"
    readonly property color textMuted:      "#b5bac1"
    readonly property color textSubtle:     "#87898f"

    // ── Accents ───────────────────────────────────────────
    readonly property color accentBlue:     "#5865F2"
    readonly property color accentGreen:    "#23a559"
    readonly property color accentPink:     "#eb459e"

    // ── Animation durations (ms) ──────────────────────────
    readonly property int animFast:         150
    readonly property int animMid:          200
    readonly property int animSlow:         250

    // ── Sizing ────────────────────────────────────────────
    readonly property int sidePanelWidth:   72
    readonly property int midPanelWidth:    240
    readonly property int serverIconSize:   48
    readonly property int serverIconRadius: 24
    readonly property int serverIconRadiusHover: 16
}

import QtQuick

// Four hanging cords, each from a point in `from` to the matching point in `to`. Every cord is a
// chain of points that gravity pulls down and a few distance constraints hold together, so it
// droops and swings when the far end moves. Drawing runs only while `active`.
Canvas {
    id: root
    property bool active: false
    property color color: "white"
    property real lineWidth: 6
    property var from: []
    property var to: []
    readonly property int links: 12
    // How much longer than the straight distance a cord is, so it sags.
    readonly property real slack: 1.12
    readonly property real gravity: 0.9
    property var chains: []

    function reset() {
        const chains = []
        for (let c = 0; c < from.length; c++) {
            const points = []
            for (let i = 0; i <= links; i++) {
                const t = i / links
                const x = from[c].x + (to[c].x - from[c].x) * t, y = from[c].y + (to[c].y - from[c].y) * t
                points.push({ x: x, y: y, px: x, py: y })
            }
            chains.push(points)
        }
        root.chains = chains
    }
    function step() {
        for (let c = 0; c < chains.length; c++) {
            const points = chains[c]
            const dx = to[c].x - from[c].x, dy = to[c].y - from[c].y
            const rest = Math.sqrt(dx * dx + dy * dy) * slack / links
            for (let i = 1; i < links; i++) {
                const p = points[i]
                const vx = (p.x - p.px) * 0.96, vy = (p.y - p.py) * 0.96
                p.px = p.x; p.py = p.y
                p.x += vx; p.y += vy + gravity
            }
            points[0].x = from[c].x; points[0].y = from[c].y
            points[links].x = to[c].x; points[links].y = to[c].y
            for (let pass = 0; pass < 6; pass++) {
                for (let i = 0; i < links; i++) {
                    const a = points[i], b = points[i + 1]
                    const ex = b.x - a.x, ey = b.y - a.y
                    const length = Math.sqrt(ex * ex + ey * ey) || 0.0001
                    const push = (length - rest) / length / 2
                    if (i > 0) { a.x += ex * push; a.y += ey * push }
                    if (i + 1 < links) { b.x -= ex * push; b.y -= ey * push }
                }
            }
        }
    }
    onActiveChanged: if (active) reset()
    Timer {
        interval: 16; repeat: true; running: root.active
        onTriggered: { root.step(); root.requestPaint() }
    }
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (!active) return
        ctx.strokeStyle = color
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        for (const points of chains) {
            ctx.beginPath()
            ctx.moveTo(points[0].x, points[0].y)
            for (let i = 1; i < points.length - 1; i++) {
                const mx = (points[i].x + points[i + 1].x) / 2, my = (points[i].y + points[i + 1].y) / 2
                ctx.quadraticCurveTo(points[i].x, points[i].y, mx, my)
            }
            ctx.lineTo(points[points.length - 1].x, points[points.length - 1].y)
            ctx.stroke()
        }
    }
}

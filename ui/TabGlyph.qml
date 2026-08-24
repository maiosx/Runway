import QtQuick

Item {
  id: glyph
  property string kind: "forecast"
  property color ink: "#f5f5f7"

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    onPaint: {
      var ctx = getContext("2d")
      var s = Math.min(width, height)
      ctx.reset()
      ctx.strokeStyle = glyph.ink
      ctx.fillStyle = glyph.ink
      ctx.lineWidth = Math.max(1.6, s * 0.07)
      ctx.lineCap = "round"
      ctx.lineJoin = "round"
      ctx.translate((width - s) / 2, (height - s) / 2)
      ctx.scale(s / 24, s / 24)

      if (glyph.kind === "accounts") {
        ctx.beginPath()
        ctx.moveTo(3, 21)
        ctx.lineTo(21, 21)
        ctx.moveTo(5, 21)
        ctx.lineTo(5, 9)
        ctx.lineTo(12, 4)
        ctx.lineTo(19, 9)
        ctx.lineTo(19, 21)
        ctx.moveTo(9, 21)
        ctx.lineTo(9, 15)
        ctx.lineTo(15, 15)
        ctx.lineTo(15, 21)
        ctx.stroke()
      } else if (glyph.kind === "plan") {
        ctx.beginPath()
        ctx.moveTo(8, 6); ctx.lineTo(21, 6)
        ctx.moveTo(8, 12); ctx.lineTo(21, 12)
        ctx.moveTo(8, 18); ctx.lineTo(21, 18)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(4, 6, 1.1, 0, Math.PI * 2)
        ctx.arc(4, 12, 1.1, 0, Math.PI * 2)
        ctx.arc(4, 18, 1.1, 0, Math.PI * 2)
        ctx.fill()
      } else {
        ctx.beginPath()
        ctx.moveTo(3, 17)
        ctx.lineTo(9, 11)
        ctx.lineTo(13, 15)
        ctx.lineTo(21, 7)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(15, 7)
        ctx.lineTo(21, 7)
        ctx.lineTo(21, 13)
        ctx.stroke()
      }
    }
  }

  onKindChanged: canvas.requestPaint()
  onInkChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
}

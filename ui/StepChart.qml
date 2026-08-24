import QtQuick
import "../js/dates.js" as Dates

Item {
  id: chart
  property var points: []
  property string fromDate: ""
  property string toDate: ""
  property color fillTop: "#30d158"
  property color strokeColor: "#86f9a9"
  property color zeroColor: "#ff9f0a"
  property color dotColor: "#ffffff"

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height
      ctx.reset()
      if (w < 8 || h < 8 || !chart.points || chart.points.length === 0) return

      var padL = 0
      var padR = 12
      var padT = 10
      var padB = 8
      var innerW = Math.max(1, w - padL - padR)
      var innerH = Math.max(1, h - padT - padB)

      function t(iso) { return Dates.parseISO(iso).getTime() }
      var from = t(chart.fromDate)
      var to = t(chart.toDate)
      var span = Math.max(1, to - from)

      var minB = 0
      var maxB = 0
      var i
      var nPts = Math.min(chart.points.length, 512)
      for (i = 0; i < nPts; i++) {
        var b = chart.points[i].balance
        if (b < minB) minB = b
        if (b > maxB) maxB = b
      }
      var pad = Math.max((maxB - minB) * 0.08, 100)
      var domainMin = Math.min(0, minB)
      var domainMax = Math.max(0, maxB) + pad
      var range = domainMax - domainMin || 1

      function xOf(iso) {
        return padL + ((t(iso) - from) / span) * innerW
      }
      function yOf(v) {
        return padT + (1 - (v - domainMin) / range) * innerH
      }

      var pts = []
      for (i = 0; i < nPts; i++) {
        pts.push({ x: xOf(chart.points[i].date), y: yOf(chart.points[i].balance) })
      }
      var last = pts[pts.length - 1]
      var first = pts[0]
      var endX = xOf(chart.toDate)
      if (last.x < endX) {
        pts.push({ x: endX, y: last.y })
        last = pts[pts.length - 1]
      }

      var zeroY = yOf(0)
      ctx.beginPath()
      ctx.moveTo(pts[0].x, pts[0].y)
      for (i = 1; i < pts.length; i++) {
        ctx.lineTo(pts[i].x, pts[i - 1].y)
        ctx.lineTo(pts[i].x, pts[i].y)
      }
      var floorY = Math.min(h, Math.max(zeroY, padT + innerH))
      ctx.lineTo(last.x, floorY)
      ctx.lineTo(first.x, floorY)
      ctx.closePath()
      var grad = ctx.createLinearGradient(0, padT, 0, floorY)
      grad.addColorStop(0, "#30d158")
      grad.addColorStop(0.55, "rgba(48, 209, 88, 0.45)")
      grad.addColorStop(1, "rgba(48, 209, 88, 0)")
      ctx.fillStyle = grad
      ctx.fill()

      ctx.beginPath()
      ctx.moveTo(pts[0].x, pts[0].y)
      for (i = 1; i < pts.length; i++) {
        ctx.lineTo(pts[i].x, pts[i - 1].y)
        ctx.lineTo(pts[i].x, pts[i].y)
      }
      ctx.strokeStyle = chart.strokeColor
      ctx.lineWidth = 2
      ctx.lineJoin = "miter"
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(0, zeroY)
      ctx.lineTo(w, zeroY)
      ctx.strokeStyle = chart.zeroColor
      ctx.lineWidth = 1.5
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(last.x, last.y, 5, 0, Math.PI * 2)
      ctx.fillStyle = chart.dotColor
      ctx.fill()
    }
  }

  onPointsChanged: canvas.requestPaint()
  onFromDateChanged: canvas.requestPaint()
  onToDateChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
}

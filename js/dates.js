.pragma library

function pad(n) {
  return n < 10 ? "0" + n : "" + n
}

function iso(d) {
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function validISO(s) {
  if (typeof s !== "string" || !/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(s)) return false
  var y = Number(s.substring(0, 4))
  var m = Number(s.substring(5, 7))
  var d = Number(s.substring(8, 10))
  if (!isFinite(y) || !isFinite(m) || !isFinite(d)) return false
  if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return false
  var dt = new Date(y, m - 1, d)
  return dt.getFullYear() === y && dt.getMonth() === m - 1 && dt.getDate() === d
}

function parseISO(s) {
  if (!validISO(s)) return new Date(NaN)
  var p = s.split("-")
  return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
}

function todayISO() {
  return iso(new Date())
}

function addMonths(isoStr, months) {
  months = Number(months)
  if (!isFinite(months)) months = 0
  if (months > 120) months = 120
  if (months < -120) months = -120
  var d = parseISO(isoStr)
  if (isNaN(d.getTime())) return isoStr
  var day = d.getDate()
  var r = new Date(d.getFullYear(), d.getMonth() + months, 1)
  var last = new Date(r.getFullYear(), r.getMonth() + 1, 0).getDate()
  r.setDate(Math.min(day, last))
  return iso(r)
}

function addWeeks(isoStr, weeks) {
  var d = parseISO(isoStr)
  d.setDate(d.getDate() + weeks * 7)
  return iso(d)
}

function addYears(isoStr, years) {
  return addMonths(isoStr, years * 12)
}

function nextOccurrence(isoStr, frequency) {
  if (frequency === "weekly") return addWeeks(isoStr, 1)
  if (frequency === "biweekly") return addWeeks(isoStr, 2)
  if (frequency === "monthly") return addMonths(isoStr, 1)
  if (frequency === "quarterly") return addMonths(isoStr, 3)
  if (frequency === "yearly") return addYears(isoStr, 1)
  return isoStr
}

function occurrences(nextDate, frequency, rangeStart, rangeEnd, maxOcc) {
  var cap = typeof maxOcc === "number" && isFinite(maxOcc) ? Math.min(Math.max(0, Math.floor(maxOcc)), 200) : 200
  var out = []
  if (!validISO(nextDate) || !validISO(rangeStart) || !validISO(rangeEnd)) return out
  if (rangeEnd < rangeStart) return out
  var cursor = nextDate
  if (frequency !== "once") {
    var guard = 0
    while (cursor < rangeStart && guard < cap) {
      var nxt = nextOccurrence(cursor, frequency)
      if (!validISO(nxt) || nxt <= cursor) break
      cursor = nxt
      guard++
    }
  }
  if (frequency === "once") {
    if (cursor >= rangeStart && cursor <= rangeEnd) out.push(cursor)
    return out
  }
  var g = 0
  while (cursor <= rangeEnd && g < cap) {
    if (cursor >= rangeStart) out.push(cursor)
    var n2 = nextOccurrence(cursor, frequency)
    if (!validISO(n2) || n2 <= cursor) break
    cursor = n2
    g++
  }
  return out
}

function formatLongDate(isoStr) {
  var d = parseISO(isoStr)
  if (isNaN(d.getTime())) return ""
  var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
  return months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
}

function firstOfNextMonthISO() {
  var d = new Date()
  return iso(new Date(d.getFullYear(), d.getMonth() + 1, 1))
}

function nextWeekdayISO(weekday) {
  var d = new Date()
  var diff = (weekday - d.getDay() + 7) % 7
  d.setDate(d.getDate() + diff)
  return iso(d)
}

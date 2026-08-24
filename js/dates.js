.pragma library

function pad(n) {
  return n < 10 ? "0" + n : "" + n
}

function iso(d) {
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function parseISO(s) {
  var p = (s || "").split("-")
  return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
}

function todayISO() {
  return iso(new Date())
}

function addMonths(isoStr, months) {
  var d = parseISO(isoStr)
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

function occurrences(nextDate, frequency, rangeStart, rangeEnd) {
  var out = []
  var cursor = nextDate
  if (frequency !== "once") {
    var guard = 0
    while (cursor < rangeStart && guard < 800) {
      cursor = nextOccurrence(cursor, frequency)
      guard++
    }
  }
  if (frequency === "once") {
    if (cursor >= rangeStart && cursor <= rangeEnd) out.push(cursor)
    return out
  }
  var g = 0
  while (cursor <= rangeEnd && g < 800) {
    if (cursor >= rangeStart) out.push(cursor)
    cursor = nextOccurrence(cursor, frequency)
    g++
  }
  return out
}

function formatLongDate(isoStr) {
  var d = parseISO(isoStr)
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

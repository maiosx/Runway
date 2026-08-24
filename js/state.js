.pragma library

var MAX_BYTES = 65536
var MAX_ACCOUNTS = 64
var MAX_INCOMES = 128
var MAX_EXPENSES = 128
var MAX_TRANSFERS = 64
var MAX_NAME = 80
var MAX_ID = 64
var MAX_CENTS = 100000000000
var MAX_HORIZON_MONTHS = 36
var MAX_EVENTS = 2048
var MAX_POINTS = 512
var MAX_OCCURRENCES = 200

function emptyBook() {
  return {
    currency: "USD",
    forecastAccountId: "all",
    accounts: [],
    incomes: [],
    expenses: [],
    transfers: []
  }
}

function clipStr(s, max) {
  if (s === null || s === undefined) return ""
  s = String(s)
  if (s.length > max) return s.substring(0, max)
  return s
}

function validId(s) {
  s = clipStr(s, MAX_ID)
  if (!/^[A-Za-z0-9._:-]+$/.test(s)) return ""
  return s
}

function validDate(s) {
  s = String(s || "")
  if (!/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(s)) return ""
  var y = Number(s.substring(0, 4))
  var m = Number(s.substring(5, 7))
  var d = Number(s.substring(8, 10))
  if (!isFinite(y) || !isFinite(m) || !isFinite(d)) return ""
  if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return ""
  var dt = new Date(y, m - 1, d)
  if (dt.getFullYear() !== y || dt.getMonth() !== m - 1 || dt.getDate() !== d) return ""
  return s
}

function validCents(n) {
  n = Number(n)
  if (!isFinite(n) || n < 0) return 0
  n = Math.round(n)
  if (n > MAX_CENTS) return MAX_CENTS
  return n
}

function validFreq(f) {
  if (f === "once" || f === "weekly" || f === "biweekly" || f === "monthly" || f === "quarterly" || f === "yearly")
    return f
  return "monthly"
}

function validCurrency(c) {
  if (c === "EUR" || c === "GBP" || c === "USD") return c
  return "USD"
}

function sanitizeAccount(x) {
  if (!x || typeof x !== "object") return null
  var id = validId(x.id)
  if (!id) return null
  var kind = x.kind === "liability" ? "liability" : "asset"
  var name = clipStr(x.name, MAX_NAME).replace(/[\x00-\x1f\x7f]/g, "").trim()
  if (!name) name = kind === "liability" ? "Card" : "Account"
  return { id: id, name: name, kind: kind, balance: validCents(x.balance) }
}

function sanitizePlanItem(x, accounts) {
  if (!x || typeof x !== "object") return null
  var id = validId(x.id)
  if (!id) return null
  var name = clipStr(x.name, MAX_NAME).replace(/[\x00-\x1f\x7f]/g, "").trim() || "Item"
  var nextDate = validDate(x.nextDate)
  if (!nextDate) return null
  var accountId = validId(x.accountId)
  if (!accountId || !accounts[accountId]) accountId = ""
  return {
    id: id,
    name: name,
    amount: validCents(x.amount),
    frequency: validFreq(x.frequency),
    nextDate: nextDate,
    accountId: accountId,
    enabled: !!x.enabled
  }
}

function sanitizeTransfer(x, accounts) {
  if (!x || typeof x !== "object") return null
  var id = validId(x.id)
  if (!id) return null
  var name = clipStr(x.name, MAX_NAME).replace(/[\x00-\x1f\x7f]/g, "").trim() || "Transfer"
  var nextDate = validDate(x.nextDate)
  if (!nextDate) return null
  var fromId = validId(x.fromAccountId)
  var toId = validId(x.toAccountId)
  if (!accounts[fromId]) fromId = ""
  if (!accounts[toId]) toId = ""
  return {
    id: id,
    name: name,
    amount: validCents(x.amount),
    frequency: validFreq(x.frequency),
    nextDate: nextDate,
    fromAccountId: fromId,
    toAccountId: toId,
    enabled: !!x.enabled
  }
}

function takeList(raw, max, mapFn) {
  if (!raw || typeof raw !== "object" || typeof raw.length !== "number") return []
  var n = Math.min(raw.length, max)
  var out = []
  var seen = ({})
  for (var i = 0; i < n; i++) {
    var item = mapFn(raw[i])
    if (!item) continue
    if (seen[item.id]) continue
    seen[item.id] = true
    out.push(item)
  }
  return out
}

function parseBook(raw) {
  if (raw === null || raw === undefined) return null
  if (typeof raw !== "string") return null
  if (raw.length > MAX_BYTES) return null
  var parsed
  try {
    parsed = JSON.parse(raw)
  } catch (e) {
    return null
  }
  if (!parsed || typeof parsed !== "object" || parsed.length !== undefined) return null

  var accounts = takeList(parsed.accounts, MAX_ACCOUNTS, sanitizeAccount)
  var byId = ({})
  for (var i = 0; i < accounts.length; i++) byId[accounts[i].id] = true

  var incomes = takeList(parsed.incomes, MAX_INCOMES, function (x) { return sanitizePlanItem(x, byId) })
  var expenses = takeList(parsed.expenses, MAX_EXPENSES, function (x) { return sanitizePlanItem(x, byId) })
  var transfers = takeList(parsed.transfers, MAX_TRANSFERS, function (x) { return sanitizeTransfer(x, byId) })

  var forecastAccountId = "all"
  if (parsed.forecastAccountId === "all") forecastAccountId = "all"
  else {
    var fid = validId(parsed.forecastAccountId)
    forecastAccountId = (fid && byId[fid]) ? fid : "all"
  }

  return {
    currency: validCurrency(parsed.currency),
    forecastAccountId: forecastAccountId,
    accounts: accounts,
    incomes: incomes,
    expenses: expenses,
    transfers: transfers
  }
}

function serializeBook(book) {
  var clean = parseBook(JSON.stringify({
    currency: book ? book.currency : "USD",
    forecastAccountId: book ? book.forecastAccountId : "all",
    accounts: book ? book.accounts : [],
    incomes: book ? book.incomes : [],
    expenses: book ? book.expenses : [],
    transfers: book ? book.transfers : []
  }))
  if (!clean) clean = emptyBook()
  var payload = JSON.stringify(clean)
  if (payload.length > MAX_BYTES) return ""
  return payload
}

function clampHorizon(today, selected) {
  selected = validDate(selected)
  today = validDate(today)
  if (!today) return ""
  if (!selected || selected < today) return today
  var max = today
  // 36 calendar months from today — computed by the caller via dates.js.
  return selected
}

function atCap(list, max) {
  return !!(list && list.length >= max)
}

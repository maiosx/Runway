.pragma library

function monthlyEquivalent(amount, frequency) {
  if (frequency === "weekly") return Math.round((amount * 52) / 12)
  if (frequency === "biweekly") return Math.round((amount * 26) / 12)
  if (frequency === "monthly") return amount
  if (frequency === "quarterly") return Math.round(amount / 3)
  if (frequency === "yearly") return Math.round(amount / 12)
  return 0
}

function signedBalance(account) {
  return account.kind === "liability" ? -account.balance : account.balance
}

function cloneBalances(accounts) {
  var map = ({})
  for (var i = 0; i < accounts.length; i++) {
    map[accounts[i].id] = signedBalance(accounts[i])
  }
  return map
}

function netOf(balances, accountId, accounts) {
  if (accountId !== "all") return balances[accountId] || 0
  var sum = 0
  for (var i = 0; i < accounts.length; i++) {
    var v = balances[accounts[i].id]
    if (typeof v === "number") sum += v
  }
  return sum
}

function collectEvents(incomes, expenses, transfers, startDate, endDate, occ, maxEvents, maxOcc) {
  var events = []
  var cap = typeof maxEvents === "number" && isFinite(maxEvents) ? Math.min(Math.max(0, Math.floor(maxEvents)), 4096) : 2048
  var per = typeof maxOcc === "number" && isFinite(maxOcc) ? maxOcc : 200
  var i, dates, d
  function pushAll(kind, list, accountKey, fromKey, toKey) {
    if (events.length >= cap) return
    for (i = 0; i < list.length; i++) {
      if (events.length >= cap) return
      var item = list[i]
      if (!item || !item.enabled || item.amount <= 0) continue
      dates = occ(item.nextDate, item.frequency, startDate, endDate, per)
      for (d = 0; d < dates.length; d++) {
        if (events.length >= cap) return
        events.push({
          date: dates[d],
          kind: kind,
          name: item.name,
          accountId: accountKey ? item[accountKey] : "",
          amount: item.amount,
          fromId: fromKey ? item[fromKey] : "",
          toId: toKey ? item[toKey] : ""
        })
      }
    }
  }
  pushAll("income", incomes, "accountId", "", "")
  pushAll("expense", expenses, "accountId", "", "")
  pushAll("transfer", transfers, "", "fromAccountId", "toAccountId")
  events.sort(function (a, b) {
    if (a.date !== b.date) return a.date < b.date ? -1 : 1
    var order = { income: 0, transfer: 1, expense: 2 }
    return (order[a.kind] || 0) - (order[b.kind] || 0)
  })
  return events
}

function applyEvent(balances, ev) {
  if (ev.kind === "income") {
    balances[ev.accountId] = (balances[ev.accountId] || 0) + ev.amount
  } else if (ev.kind === "expense") {
    balances[ev.accountId] = (balances[ev.accountId] || 0) - ev.amount
  } else {
    balances[ev.fromId] = (balances[ev.fromId] || 0) - ev.amount
    balances[ev.toId] = (balances[ev.toId] || 0) + ev.amount
  }
}

function monthlyNetFor(incomes, expenses, transfers, accountId) {
  var net = 0
  var i
  for (i = 0; i < incomes.length; i++) {
    if (!incomes[i].enabled) continue
    if (accountId !== "all" && incomes[i].accountId !== accountId) continue
    net += monthlyEquivalent(incomes[i].amount, incomes[i].frequency)
  }
  for (i = 0; i < expenses.length; i++) {
    if (!expenses[i].enabled) continue
    if (accountId !== "all" && expenses[i].accountId !== accountId) continue
    net -= monthlyEquivalent(expenses[i].amount, expenses[i].frequency)
  }
  for (i = 0; i < transfers.length; i++) {
    if (!transfers[i].enabled) continue
    if (accountId === "all") continue
    var m = monthlyEquivalent(transfers[i].amount, transfers[i].frequency)
    if (transfers[i].fromAccountId === accountId) net -= m
    if (transfers[i].toAccountId === accountId) net += m
  }
  return net
}

function buildForecast(data, startDate, endDate, accountId, occ) {
  if (!data) data = ({ accounts: [], incomes: [], expenses: [], transfers: [] })
  if (endDate < startDate) endDate = startDate
  var accounts = data.accounts || []
  if (accounts.length > 64) accounts = accounts.slice(0, 64)
  var incomes = (data.incomes || []).slice(0, 128)
  var expenses = (data.expenses || []).slice(0, 128)
  var transfers = (data.transfers || []).slice(0, 64)
  var balances = cloneBalances(accounts)
  var startBalance = netOf(balances, accountId, accounts)
  var events = collectEvents(incomes, expenses, transfers, startDate, endDate, occ, 2048, 200)

  var maxPoints = 512
  var points = [{ date: startDate, balance: startBalance, delta: 0 }]
  var i = 0
  while (i < events.length && points.length < maxPoints) {
    var day = events[i].date
    var before = netOf(balances, accountId, accounts)
    while (i < events.length && events[i].date === day) {
      applyEvent(balances, events[i])
      i++
    }
    var after = netOf(balances, accountId, accounts)
    points.push({ date: day, balance: after, delta: after - before })
  }
  var last = points[points.length - 1]
  if (last && last.date < endDate && points.length < maxPoints) {
    points.push({ date: endDate, balance: last.balance, delta: 0 })
  }

  var minB = startBalance
  var maxB = startBalance
  var crosses = ""
  for (var p = 0; p < points.length; p++) {
    if (points[p].balance < minB) minB = points[p].balance
    if (points[p].balance > maxB) maxB = points[p].balance
    if (!crosses && points[p].balance <= 0 && points[p].date > startDate && startBalance > 0) crosses = points[p].date
  }

  var monthlyNet = monthlyNetFor(data.incomes || [], data.expenses || [], data.transfers || [], accountId)
  var runwayMonths = Number.POSITIVE_INFINITY
  if (monthlyNet < 0 && startBalance > 0) runwayMonths = startBalance / -monthlyNet
  else if (startBalance <= 0 && monthlyNet <= 0) runwayMonths = 0

  return {
    points: points,
    startBalance: startBalance,
    endBalance: last ? last.balance : startBalance,
    monthlyNet: monthlyNet,
    runwayMonths: runwayMonths,
    crossesZeroOn: crosses,
    minBalance: minB,
    maxBalance: maxB
  }
}

function formatMoney(cents, symbol) {
  symbol = symbol || "$"
  var neg = cents < 0
  var abs = Math.abs(cents)
  var showCents = abs % 100 !== 0
  var n = abs / 100
  var s = showCents ? n.toFixed(2) : String(Math.round(n))
  var parts = s.split(".")
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  return (neg ? "−" : "") + symbol + parts.join(".")
}

function formatMoneySigned(cents, symbol) {
  var body = formatMoney(Math.abs(cents), symbol)
  if (cents > 0) return "+" + body
  if (cents < 0) return "−" + formatMoney(Math.abs(cents), symbol).replace("−", "")
  return body
}

function uid() {
  return "id-" + Date.now().toString(36) + "-" + Math.floor(Math.random() * 1e6).toString(36)
}

function frequencyLabel(f) {
  if (f === "once") return "Once"
  if (f === "weekly") return "Every week"
  if (f === "biweekly") return "Every 2 weeks"
  if (f === "monthly") return "Every month"
  if (f === "quarterly") return "Every 3 months"
  if (f === "yearly") return "Every year"
  return "Every month"
}

function createEmpty() {
  return {
    currency: "USD",
    forecastAccountId: "all",
    accounts: [],
    incomes: [],
    expenses: [],
    transfers: []
  }
}

function createSample(today, friday, first, tomorrow) {
  return {
    currency: "USD",
    forecastAccountId: "acc-checking",
    accounts: [
      { id: "acc-checking", name: "Checking", kind: "asset", balance: 418000 },
      { id: "acc-savings", name: "Savings", kind: "asset", balance: 824000 },
      { id: "acc-visa", name: "Visa", kind: "liability", balance: 64000 }
    ],
    incomes: [
      { id: "inc-paycheck", name: "Paycheck", amount: 218500, frequency: "biweekly", nextDate: friday, accountId: "acc-checking", enabled: true },
      { id: "inc-rose", name: "Rose", amount: 30000, frequency: "monthly", nextDate: first, accountId: "acc-checking", enabled: true }
    ],
    expenses: [
      { id: "exp-rent", name: "Rent", amount: 145000, frequency: "monthly", nextDate: first, accountId: "acc-checking", enabled: true },
      { id: "exp-groceries", name: "Groceries", amount: 9500, frequency: "weekly", nextDate: tomorrow, accountId: "acc-checking", enabled: true },
      { id: "exp-auto", name: "Insurance", amount: 21000, frequency: "monthly", nextDate: first, accountId: "acc-checking", enabled: true },
      { id: "exp-utilities", name: "Utilities", amount: 16500, frequency: "monthly", nextDate: first, accountId: "acc-checking", enabled: true },
      { id: "exp-subs", name: "Subscriptions", amount: 4700, frequency: "monthly", nextDate: friday, accountId: "acc-checking", enabled: true }
    ],
    transfers: [
      { id: "tr-savings", name: "To savings", amount: 25000, frequency: "monthly", nextDate: first, fromAccountId: "acc-checking", toAccountId: "acc-savings", enabled: true },
      { id: "tr-card", name: "Card payment", amount: 20000, frequency: "monthly", nextDate: first, fromAccountId: "acc-checking", toAccountId: "acc-visa", enabled: true }
    ]
  }
}

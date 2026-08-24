pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "js/dates.js" as Dates
import "js/forecast.js" as F
import "ui"

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  property var book: ({
    currency: "USD",
    forecastAccountId: "acc-checking",
    accounts: [],
    incomes: [],
    expenses: [],
    transfers: []
  })

  property string tab: "forecast"
  property string planTab: "incomes"
  property string accountKind: "asset"
  property string today: Dates.todayISO()
  property string selectedDate: Dates.addMonths(Dates.todayISO(), 12)
  property string mode: "balance"
  property string editor: ""
  property string editorId: ""
  property var forecast: ({ points: [], endBalance: 0, monthlyNet: 0, runwayMonths: Infinity, crossesZeroOn: "" })

  readonly property color bg: "#000000"
  readonly property color fg: "#f5f5f7"
  readonly property color muted: "#8e8e93"
  readonly property color subtle: "#636366"
  readonly property color surface: "#1c1c1e"
  readonly property color surface2: "#2c2c2e"
  readonly property color accent: "#30d158"
  readonly property color zero: "#ff9f0a"
  readonly property color danger: "#ff453a"
  readonly property color pill: "#ffffff"
  readonly property color pillFg: "#111111"
  readonly property string symbol: root.book.currency === "EUR" ? "€" : (root.book.currency === "GBP" ? "£" : "$")

  function open(payloadJson) {
    root.today = Dates.todayISO()
    if (!root.selectedDate || root.selectedDate < root.today)
      root.selectedDate = Dates.addMonths(root.today, 12)
    root.opened = true
    root.refreshForecast()
    Qt.callLater(function () { keyCatcher.forceActiveFocus() })
  }

  function close() { root.opened = false; root.editor = "" }

  function dismiss() {
    root.opened = false
    root.editor = ""
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "runway.forecast")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function refreshForecast() {
    root.forecast = F.buildForecast(root.book, root.today, root.selectedDate, root.book.forecastAccountId, Dates.occurrences)
  }

  function cloneList(list) {
    var out = []
    if (!list) return out
    for (var i = 0; i < list.length; i++) out.push(list[i])
    return out
  }

  function persist() {
    dataFile.setText(JSON.stringify(root.book, null, 2))
    refreshForecast()
    rebuildLists()
  }

  function loadData(raw) {
    try {
      var parsed = JSON.parse(raw)
      if (parsed && parsed.accounts && parsed.accounts.length) {
        root.book = parsed
        refreshForecast()
        rebuildLists()
        return
      }
    } catch (e) {}
    seedEmpty()
  }

  function seedEmpty() {
    root.book = F.createEmpty()
    persist()
  }

  function seedSample() {
    var t = Dates.todayISO()
    var d = Dates.parseISO(t)
    d.setDate(d.getDate() + 1)
    root.book = F.createSample(t, Dates.nextWeekdayISO(5), Dates.firstOfNextMonthISO(), Dates.iso(d))
    persist()
  }

  function accountName(id) {
    var list = root.book.accounts || []
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i].name
    return "Account"
  }

  function filterLabel() {
    if (root.book.forecastAccountId === "all") return "All Accounts"
    return accountName(root.book.forecastAccountId)
  }

  function rebuildLists() {
    accountModel.clear()
    var acc = root.book.accounts || []
    for (var i = 0; i < acc.length; i++) {
      if (acc[i].kind === root.accountKind)
        accountModel.append({ uid: acc[i].id, title: acc[i].name, balance: acc[i].balance })
    }
    planModel.clear()
    var rows = []
    if (root.planTab === "incomes") rows = root.book.incomes || []
    else if (root.planTab === "expenses") rows = root.book.expenses || []
    else rows = root.book.transfers || []
    for (var j = 0; j < rows.length; j++) {
      var it = rows[j]
      var sub = root.planTab === "transfers"
        ? accountName(it.fromAccountId) + " → " + accountName(it.toAccountId)
        : accountName(it.accountId)
      planModel.append({
        uid: it.id,
        title: it.name,
        subtitle: sub,
        amount: it.amount,
        cadence: F.frequencyLabel(it.frequency),
        isOn: !!it.enabled
      })
    }
  }

  function togglePlanItem(uid) {
    var key = root.planTab
    var list = root.book[key].slice()
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === uid) {
        list[i] = Object.assign({}, list[i], { enabled: !list[i].enabled })
      }
    }
    var next = Object.assign({}, root.book)
    next[key] = list
    root.book = next
    persist()
  }

  function deleteById(collection, uid) {
    var list = (root.book[collection] || []).filter(function (x) { return x.id !== uid })
    var next = Object.assign({}, root.book)
    next[collection] = list
    root.book = next
    persist()
  }

  IpcHandler {
    target: "runway"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("{}") }
    function close(): void { root.dismiss() }
    function status(): string { return root.opened ? "open" : "closed" }
  }

  FileView {
    id: dataFile
    path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/runway-v2.json"
    watchChanges: true
    onLoaded: root.loadData(text())
    onLoadFailed: root.seedEmpty()
  }

  ListModel { id: accountModel }
  ListModel { id: planModel }

  onAccountKindChanged: rebuildLists()
  onPlanTabChanged: rebuildLists()
  onSelectedDateChanged: refreshForecast()
  onOpenedChanged: if (opened) { root.today = Dates.todayISO(); refreshForecast(); rebuildLists() }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "runway-forecast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          if (root.editor !== "") root.editor = ""
          else root.dismiss()
          event.accepted = true
        }
      }

      Rectangle {
        anchors.fill: parent
        color: root.bg
      }

      Item {
        id: stage
        width: Math.min(parent.width, 520)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        Column {
          id: header
          width: parent.width
          topPadding: 18
          leftPadding: 20
          rightPadding: 12

          Row {
            width: parent.width - 32
            spacing: 8
            Text {
              text: root.tab === "accounts" ? "Accounts" : (root.tab === "plan" ? "Plan" : "Forecast")
              color: root.fg
              font.pixelSize: 34
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: parent.width - 180; height: 1 }
            Text {
              text: "Esc"
              color: root.muted
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // Forecast
        Column {
          visible: root.tab === "forecast" && root.editor === ""
          anchors.top: header.bottom
          anchors.bottom: tabs.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 10

          Row {
            width: parent.width
            leftPadding: 20
            rightPadding: 20
            spacing: 8
            Rectangle {
              width: 44; height: 44; radius: 22; color: root.surface
              Text { anchors.centerIn: parent; text: "‹"; color: root.fg; font.pixelSize: 22 }
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  var prev = Dates.addMonths(root.selectedDate, -1)
                  root.selectedDate = prev < root.today ? root.today : prev
                }
              }
            }
            Rectangle {
              width: parent.width - 116; height: 44; radius: 22; color: root.surface
              Text {
                anchors.centerIn: parent
                text: Dates.formatLongDate(root.selectedDate)
                color: root.fg
                font.pixelSize: 15
                font.weight: Font.Medium
              }
              MouseArea {
                anchors.fill: parent
                onClicked: root.selectedDate = Dates.addMonths(root.today, 12)
              }
            }
            Rectangle {
              width: 44; height: 44; radius: 22; color: root.surface
              Text { anchors.centerIn: parent; text: "›"; color: root.fg; font.pixelSize: 22 }
              MouseArea {
                anchors.fill: parent
                onClicked: root.selectedDate = Dates.addMonths(root.selectedDate, 1)
              }
            }
          }

          Item { width: 1; height: 8 }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
              if (root.mode === "runway") {
                var m = root.forecast.runwayMonths
                if (!isFinite(m) || root.forecast.monthlyNet >= 0) return "Growing"
                if (m < 1) return Math.round(m * 30) + " days"
                return (m < 10 ? m.toFixed(1) : Math.round(m)) + " mo"
              }
              return F.formatMoney(root.forecast.endBalance || 0, root.symbol)
            }
            color: root.fg
            font.pixelSize: 42
            font.weight: Font.Normal
            MouseArea {
              anchors.fill: parent
              onClicked: root.mode = root.mode === "balance" ? "runway" : "balance"
            }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: filterLabel() + "  ▾"
            color: root.muted
            font.pixelSize: 15
            MouseArea {
              anchors.fill: parent
              onClicked: {
                var cur = root.book.forecastAccountId
                if (cur === "all") {
                  var acc = root.book.accounts || []
                  if (acc.length) {
                    var next = Object.assign({}, root.book)
                    next.forecastAccountId = acc[0].id
                    root.book = next
                    persist()
                  }
                } else {
                  var n = Object.assign({}, root.book)
                  n.forecastAccountId = "all"
                  root.book = n
                  persist()
                }
              }
            }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: root.forecast.crossesZeroOn ? root.danger : (root.forecast.monthlyNet >= 0 ? root.accent : root.zero)
            font.pixelSize: 13
            text: {
              if (root.forecast.crossesZeroOn)
                return "Goes negative on " + Dates.formatLongDate(root.forecast.crossesZeroOn)
              if ((root.forecast.monthlyNet || 0) === 0)
                return (root.forecast.startBalance || 0) === 0
                  ? "Add income on the Plan tab to project this."
                  : "No monthly net — balance holds"
              if (root.forecast.monthlyNet > 0)
                return "Growing " + F.formatMoneySigned(Math.round(root.forecast.monthlyNet / 100) * 100, root.symbol) + " / month"
              var m = root.forecast.runwayMonths
              return isFinite(m) ? m.toFixed(1) + " months of runway" : "Income covers spending"
            }
          }

          StepChart {
            width: parent.width
            height: Math.max(180, parent.height - 220)
            points: root.forecast.points || []
            fromDate: root.today
            toDate: root.selectedDate
          }
        }

        // Plan
        Item {
          visible: root.tab === "plan" && root.editor === ""
          anchors.top: header.bottom
          anchors.bottom: tabs.top
          anchors.left: parent.left
          anchors.right: parent.right

          Row {
            id: planPills
            width: parent.width
            y: 8
            leftPadding: 20
            rightPadding: 20
            spacing: 8
            Repeater {
              model: [
                { id: "incomes", label: "Incomes" },
                { id: "transfers", label: "Transfers" },
                { id: "expenses", label: "Expenses" }
              ]
              Rectangle {
                required property var modelData
                width: (stage.width - 56) / 3
                height: 36
                radius: 18
                color: root.planTab === modelData.id ? root.pill : root.surface
                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: root.planTab === parent.modelData.id ? root.pillFg : root.fg
                  font.pixelSize: 15
                  font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: root.planTab = parent.modelData.id }
              }
            }
          }

          Text {
            visible: planModel.count === 0
            anchors.top: planPills.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: root.muted
            font.pixelSize: 15
            text: root.planTab === "incomes"
              ? "No income yet. Tap + to add a paycheck or deposit."
              : (root.planTab === "expenses"
                ? "No expenses yet. Tap + to add rent, bills, or spending."
                : "No transfers yet. Tap + to move money between accounts.")
          }

          ListView {
            id: planList
            anchors.top: planPills.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            model: planModel
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
              id: planRow
              required property string uid
              required property string title
              required property string subtitle
              required property real amount
              required property string cadence
              required property bool isOn
              width: planList.width
              height: 64
              Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                spacing: 12
                Rectangle {
                  width: 28; height: 28; radius: 14
                  color: planRow.isOn ? "#2c2c2e" : "transparent"
                  border.width: 1
                  border.color: "#8e8e93"
                  anchors.verticalCenter: parent.verticalCenter
                  Text {
                    anchors.centerIn: parent
                    text: planRow.isOn ? "✓" : ""
                    color: "#f5f5f7"
                    font.pixelSize: 12
                  }
                  MouseArea {
                    anchors.fill: parent
                    onClicked: root.togglePlanItem(planRow.uid)
                  }
                }
                Column {
                  width: parent.width - 160
                  anchors.verticalCenter: parent.verticalCenter
                  Text {
                    width: parent.width
                    text: planRow.title
                    color: planRow.isOn ? "#f5f5f7" : "#8e8e93"
                    font.pixelSize: 17
                    elide: Text.ElideRight
                  }
                  Text {
                    width: parent.width
                    text: planRow.subtitle
                    color: "#8e8e93"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                  }
                }
                Column {
                  width: 90
                  anchors.verticalCenter: parent.verticalCenter
                  Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: F.formatMoney(planRow.amount, "$")
                    color: planRow.isOn ? "#f5f5f7" : "#8e8e93"
                    font.pixelSize: 17
                  }
                  Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: planRow.cadence
                    color: "#8e8e93"
                    font.pixelSize: 13
                  }
                }
              }
            }
          }
        }

        // Accounts
        Item {
          visible: root.tab === "accounts" && root.editor === ""
          anchors.top: header.bottom
          anchors.bottom: tabs.top
          anchors.left: parent.left
          anchors.right: parent.right

          Row {
            id: accountPills
            width: parent.width
            y: 8
            leftPadding: 20
            rightPadding: 20
            spacing: 8
            Repeater {
              model: [
                { id: "asset", label: "Assets" },
                { id: "liability", label: "Liabilities" }
              ]
              Rectangle {
                required property var modelData
                width: (stage.width - 48) / 2
                height: 36
                radius: 18
                color: root.accountKind === modelData.id ? root.pill : root.surface
                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: root.accountKind === parent.modelData.id ? root.pillFg : root.fg
                  font.pixelSize: 15
                  font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: root.accountKind = parent.modelData.id }
              }
            }
          }

          Text {
            visible: accountModel.count === 0
            anchors.top: accountPills.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: root.muted
            font.pixelSize: 15
            text: root.accountKind === "asset"
              ? "No assets yet. Tap + to add checking or savings."
              : "No liabilities yet. Tap + to add a card or loan."
          }

          ListView {
            id: accountList
            anchors.top: accountPills.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            model: accountModel
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
              id: accRow
              required property string uid
              required property string title
              required property real balance
              width: accountList.width
              height: 56
              Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 140
                text: accRow.title
                color: "#f5f5f7"
                font.pixelSize: 17
                elide: Text.ElideRight
              }
              Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: F.formatMoney(accRow.balance, "$")
                color: "#f5f5f7"
                font.pixelSize: 17
              }
            }
          }
        }

        // FAB
        Rectangle {
          visible: root.tab !== "forecast" && root.editor === ""
          width: 56; height: 56; radius: 28
          color: root.pill
          anchors.right: parent.right
          anchors.bottom: tabs.top
          anchors.margins: 20
          Text { anchors.centerIn: parent; text: "+"; color: root.pillFg; font.pixelSize: 28 }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (root.tab === "accounts") root.editor = "account"
              else if (root.planTab === "incomes") root.editor = "income"
              else if (root.planTab === "expenses") root.editor = "expense"
              else root.editor = "transfer"
              root.editorId = ""
            }
          }
        }

        // Editor
        Rectangle {
          visible: root.editor !== ""
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 420
          color: root.surface
          radius: 24

          Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12
            Text {
              text: root.editor === "account" ? "New account" : (root.editor === "income" ? "New income" : (root.editor === "expense" ? "New expense" : (root.editor === "transfer" ? "New transfer" : "Edit")))
              color: root.fg
              font.pixelSize: 17
              font.bold: true
            }
            TextField {
              id: nameField
              width: parent.width
              placeholderText: "Name"
              color: "#f5f5f7"
              background: Rectangle { color: "#2c2c2e"; radius: 12 }
              leftPadding: 14
              height: 48
            }
            TextField {
              id: amountField
              width: parent.width
              placeholderText: "Amount"
              inputMethodHints: Qt.ImhFormattedNumbersOnly
              color: "#f5f5f7"
              background: Rectangle { color: "#2c2c2e"; radius: 12 }
              leftPadding: 14
              height: 48
            }
            Rectangle {
              width: parent.width
              height: 48
              radius: 24
              color: root.pill
              Text { anchors.centerIn: parent; text: "Save"; color: root.pillFg; font.pixelSize: 15; font.bold: true }
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  var cents = Math.round(parseFloat(amountField.text.replace(/[^0-9.]/g, "") || "0") * 100)
                  if (!isFinite(cents) || cents < 0) cents = 0
                  var name = nameField.text.trim()
                  var next = Object.assign({}, root.book)
                  if (root.editor === "account") {
                    if (!name) name = root.accountKind === "liability" ? "Card" : "Checking"
                    var accs = root.cloneList(root.book.accounts)
                    accs.push({ id: F.uid(), name: name, kind: root.accountKind, balance: cents })
                    next.accounts = accs
                  } else if (root.editor === "income") {
                    if (!name) name = "Income"
                    var incomes = root.cloneList(root.book.incomes)
                    var firstAcc = (root.book.accounts && root.book.accounts.length) ? root.book.accounts[0].id : "acc-checking"
                    incomes.push({ id: F.uid(), name: name, amount: cents, frequency: "monthly", nextDate: Dates.firstOfNextMonthISO(), accountId: firstAcc, enabled: true })
                    next.incomes = incomes
                  } else if (root.editor === "expense") {
                    if (!name) name = "Expense"
                    var expenses = root.cloneList(root.book.expenses)
                    var expAcc = (root.book.accounts && root.book.accounts.length) ? root.book.accounts[0].id : "acc-checking"
                    expenses.push({ id: F.uid(), name: name, amount: cents, frequency: "monthly", nextDate: Dates.firstOfNextMonthISO(), accountId: expAcc, enabled: true })
                    next.expenses = expenses
                  } else if (root.editor === "transfer") {
                    if (!name) name = "Transfer"
                    var transfers = root.cloneList(root.book.transfers)
                    var fromId = (root.book.accounts && root.book.accounts.length) ? root.book.accounts[0].id : "acc-checking"
                    var toId = (root.book.accounts && root.book.accounts.length > 1) ? root.book.accounts[1].id : fromId
                    transfers.push({ id: F.uid(), name: name, amount: cents, frequency: "monthly", nextDate: Dates.firstOfNextMonthISO(), fromAccountId: fromId, toAccountId: toId, enabled: true })
                    next.transfers = transfers
                  }
                  root.book = next
                  root.editor = ""
                  nameField.text = ""
                  amountField.text = ""
                  persist()
                }
              }
            }
            Text {
              text: "Cancel"
              color: root.muted
              font.pixelSize: 15
              MouseArea { anchors.fill: parent; onClicked: root.editor = "" }
            }
          }
        }

        Rectangle {
          id: tabs
          width: parent.width
          height: 64
          anchors.bottom: parent.bottom
          color: root.bg
          Row {
            anchors.centerIn: parent
            spacing: 64
            Repeater {
              model: [
                { id: "accounts", kind: "accounts" },
                { id: "plan", kind: "plan" },
                { id: "forecast", kind: "forecast" }
              ]
              Item {
                required property var modelData
                width: 28
                height: 28
                TabGlyph {
                  anchors.fill: parent
                  kind: parent.modelData.kind
                  ink: root.tab === parent.modelData.id ? root.fg : root.subtle
                }
                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -14
                  onClicked: root.tab = parent.modelData.id
                }
              }
            }
          }
        }
      }
    }
  }
}

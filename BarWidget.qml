import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "runway.forecast"

  implicitWidth: glyph.implicitWidth
  implicitHeight: glyph.implicitHeight

  function toggleRunway() {
    if (!root.bar) return
    if (typeof root.bar.run === "function") {
      root.bar.run("omarchy-shell shell toggle runway.forecast")
      return
    }
    if (root.bar.shell && typeof root.bar.shell.toggle === "function")
      root.bar.shell.toggle("runway.forecast", "{}")
  }

  BarIconButton {
    id: glyph
    anchors.fill: parent
    bar: root.bar
    text: "$"
    tooltipText: "Runway - Money Forecast"
    onPressed: function (mouseButton) {
      root.toggleRunway()
    }
  }
}

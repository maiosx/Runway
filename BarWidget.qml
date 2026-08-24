import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "runway.forecast"

  implicitWidth: barSize
  implicitHeight: barSize

  function toggleRunway() {
    if (!root.bar) return
    if (typeof root.bar.run === "function") {
      root.bar.run("omarchy-shell shell toggle runway.forecast")
      return
    }
    if (root.bar.shell && typeof root.bar.shell.toggle === "function")
      root.bar.shell.toggle("runway.forecast", "{}")
  }

  Item {
    anchors.centerIn: parent
    width: Math.min(root.width - Style.space(8), Style.space(22))
    height: width

    Image {
      id: barIcon
      anchors.fill: parent
      source: Qt.resolvedUrl("assets/runway.svg")
      sourceSize: Qt.size(width * 2, height * 2)
      fillMode: Image.PreserveAspectFit
      smooth: true
      visible: false
      layer.enabled: true
    }

    MultiEffect {
      anchors.fill: parent
      source: barIcon
      colorization: 1.0
      colorizationColor: root.bar ? root.bar.foreground : "white"
    }
  }

  MouseArea {
    anchors.fill: parent
    z: 20
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: root.toggleRunway()
    onEntered: if (root.bar) root.bar.showTooltip(root, "Runway")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}

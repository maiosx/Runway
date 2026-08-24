import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "runway.forecast"

  property bool popupOpen: false
  property var runwayService: null

  function close() { popupOpen = false }

  function findOverlay() {
    if (!bar || !bar.shell) return null
    if (typeof bar.shell.serviceFor === "function") {
      var svc = bar.shell.serviceFor(moduleName)
      if (svc) return svc
    }
    return null
  }

  function toggleRunway() {
    var overlay = runwayService || findOverlay()
    if (overlay && typeof overlay.toggle === "function") {
      runwayService = overlay
      overlay.toggle()
      return
    }
    if (bar && bar.shell && typeof bar.shell.toggle === "function") {
      bar.shell.toggle(moduleName, "{}")
      return
    }
    Quickshell.execDetached(["omarchy-shell", "shell", "toggle", moduleName])
  }

  implicitWidth: barSize
  implicitHeight: barSize

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

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(280))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(9)

      Row {
        width: parent.width
        spacing: Style.space(8)
        Item {
          width: Style.space(24); height: width
          anchors.verticalCenter: parent.verticalCenter
          Image {
            id: panelIcon
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/runway.svg")
            visible: false
            layer.enabled: true
          }
          MultiEffect {
            anchors.fill: parent
            source: panelIcon
            colorization: 1.0
            colorizationColor: root.bar ? root.bar.foreground : "white"
          }
        }
        Text {
          text: "Runway"
          color: root.bar ? root.bar.foreground : "white"
          font.pixelSize: Style.font.subtitle
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Checking forecast. Super + R opens it fullscreen."
        color: Qt.darker(root.bar ? root.bar.foreground : "white", 1.3)
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        width: parent.width
        height: Style.space(30)
        radius: Style.space(7)
        color: Qt.rgba(1, 1, 1, 0.08)
        Text {
          anchors.centerIn: parent
          text: "Open Runway"
          color: root.bar ? root.bar.foreground : "white"
          font.pixelSize: Style.font.bodySmall
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.popupOpen = false
            root.toggleRunway()
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) root.popupOpen = !root.popupOpen
      else root.toggleRunway()
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, "Runway • Super + R")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}

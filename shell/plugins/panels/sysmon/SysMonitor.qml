import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: (manifest && manifest.id) || "blob.sysmon"

  function open(payloadJson) {
    root.opened = true
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  SystemStats {
    id: stats
    polling: root.opened
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-sysmon"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Card {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.spaceReal(10)
      anchors.rightMargin: Style.spaceReal(10)
      implicitWidth: Style.spaceReal(400)
      fillColor: Util.alpha(Color.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(12)

      Text {
        text: "System Monitor"
        textFormat: Text.PlainText
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      MetricBar {
        width: parent.width
        icon: "󰍛"
        name: "CPU"
        percent: stats.cpuPercent
        detail: stats.cpuPercent + "%"
      }

      MetricBar {
        width: parent.width
        icon: "󰘚"
        name: "Memory"
        percent: stats.memoryPercent
        detail: stats.memoryDetail
      }

      MetricBar {
        width: parent.width
        icon: "󰋊"
        name: "Disk"
        percent: stats.diskPercent
        detail: stats.diskDetail
      }

      MetricBar {
        width: parent.width
        icon: ""
        name: "Temperature"
        percent: stats.temperature
        detail: stats.temperature + "°C"
      }
    }
  }
}

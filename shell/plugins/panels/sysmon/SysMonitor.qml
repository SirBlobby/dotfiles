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

  property int cpuPercent: 0
  property int memoryPercent: 0
  property string memoryDetail: ""
  property int diskPercent: 0
  property string diskDetail: ""
  property int temperature: 0

  property real previousIdle: 0
  property real previousTotal: 0

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

  function readCpu(raw) {
    var values = String(raw).trim().split(/\s+/).slice(1).map(Number)
    var idle = (values[3] || 0) + (values[4] || 0)
    var total = 0
    for (var i = 0; i < values.length; i++) total += values[i] || 0
    var idleDelta = idle - root.previousIdle
    var totalDelta = total - root.previousTotal
    root.previousIdle = idle
    root.previousTotal = total
    if (totalDelta <= 0) return
    root.cpuPercent = Math.round((1 - idleDelta / totalDelta) * 100)
  }

  function readMemory(raw) {
    var parts = String(raw).trim().split(/\s+/).map(Number)
    var used = parts[0] || 0
    var total = parts[1] || 0
    if (!total) {
      root.memoryPercent = 0
      root.memoryDetail = ""
      return
    }
    root.memoryPercent = Math.round(used / total * 100)
    root.memoryDetail = (used / 1024).toFixed(1) + "G / " + (total / 1024).toFixed(1) + "G"
  }

  function readDisk(raw) {
    var parts = String(raw).trim().split(/\s+/)
    root.diskPercent = Number(String(parts[0] || "").replace("%", "")) || 0
    root.diskDetail = (parts[1] || "0") + " / " + (parts[2] || "0")
  }

  Process {
    id: cpuProbe
    command: ["bash", "-c", "grep '^cpu ' /proc/stat"]
    stdout: StdioCollector { onStreamFinished: root.readCpu(text) }
  }

  Process {
    id: memoryProbe
    command: ["bash", "-c", "free -m | awk '/^Mem:/ {print $3\" \"$2}'"]
    stdout: StdioCollector { onStreamFinished: root.readMemory(text) }
  }

  Process {
    id: diskProbe
    command: ["bash", "-c", "df -h --output=pcent,used,size / | tail -1"]
    stdout: StdioCollector { onStreamFinished: root.readDisk(text) }
  }

  Process {
    id: temperatureProbe
    command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"]
    stdout: StdioCollector {
      onStreamFinished: root.temperature = Math.round(Number(String(text).trim()) / 1000) || 0
    }
  }

  function refreshFast() {
    if (!cpuProbe.running) cpuProbe.running = true
    if (!memoryProbe.running) memoryProbe.running = true
    if (!temperatureProbe.running) temperatureProbe.running = true
  }

  function refreshSlow() {
    if (!diskProbe.running) diskProbe.running = true
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: root.refreshFast()
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.refreshSlow()
  }

  onOpenedChanged: {
    if (!root.opened) return
    root.refreshFast()
    root.refreshSlow()
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

      Metric {
        width: parent.width
        icon: "󰍛"
        name: "CPU"
        percent: root.cpuPercent
        detail: root.cpuPercent + "%"
      }

      Metric {
        width: parent.width
        icon: "󰘚"
        name: "Memory"
        percent: root.memoryPercent
        detail: root.memoryDetail
      }

      Metric {
        width: parent.width
        icon: "󰋊"
        name: "Disk"
        percent: root.diskPercent
        detail: root.diskDetail
      }

      Metric {
        width: parent.width
        icon: ""
        name: "Temperature"
        percent: root.temperature
        detail: root.temperature + "°C"
      }
    }
  }
}

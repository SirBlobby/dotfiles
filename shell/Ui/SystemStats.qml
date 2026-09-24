import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool polling: false

  property int cpuPercent: 0
  property int memoryPercent: 0
  property string memoryDetail: ""
  property int diskPercent: 0
  property string diskDetail: ""
  property int temperature: 0
  property string loadAverage: ""

  property real previousIdle: 0
  property real previousTotal: 0

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

  function readLoad(raw) {
    var parts = String(raw).trim().split(/\s+/)
    root.loadAverage = parts.length >= 3 ? parts.slice(0, 3).join("  ") : ""
  }

  function refreshFast() {
    if (!cpuProbe.running) cpuProbe.running = true
    if (!memoryProbe.running) memoryProbe.running = true
    if (!temperatureProbe.running) temperatureProbe.running = true
    if (!loadProbe.running) loadProbe.running = true
  }

  function refreshSlow() {
    if (!diskProbe.running) diskProbe.running = true
  }

  function refresh() {
    refreshFast()
    refreshSlow()
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

  Process {
    id: loadProbe
    command: ["bash", "-c", "cat /proc/loadavg"]
    stdout: StdioCollector { onStreamFinished: root.readLoad(text) }
  }

  Timer {
    interval: 2000
    running: root.polling
    repeat: true
    onTriggered: root.refreshFast()
  }

  Timer {
    interval: 30000
    running: root.polling
    repeat: true
    onTriggered: root.refreshSlow()
  }

  onPollingChanged: if (root.polling) root.refresh()
}

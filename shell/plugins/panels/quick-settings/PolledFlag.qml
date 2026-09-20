import QtQuick
import Quickshell.Io

Item {
  id: root

  property string command: ""
  property int intervalMs: 2000
  property bool value: false
  property bool polling: false

  function refresh() {
    if (root.command.length > 0 && !probe.running) probe.running = true
  }

  Process {
    id: probe
    command: ["bash", "-c", root.command]
    stdout: StdioCollector {
      onStreamFinished: root.value = text.trim() === "on"
    }
  }

  Timer {
    interval: root.intervalMs
    running: root.polling
    repeat: true
    onTriggered: root.refresh()
  }

  onPollingChanged: if (root.polling) root.refresh()
}

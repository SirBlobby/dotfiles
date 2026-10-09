import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

Column {
  id: root

  property bool polling: false

  signal commandRequested(string command)
  signal tuiRequested(string command)

  readonly property var profileLabels: ({
    "power-saver": "Power saver",
    "balanced": "Balanced",
    "performance": "Performance"
  })
  property var profiles: []
  property string activeProfile: ""

  spacing: Style.spaceReal(12)

  function readProfiles(raw) {
    var available = []
    var active = ""
    var lines = String(raw).trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split("\t")
      if (!fields[0]) continue
      available.push({ value: fields[0], label: root.profileLabels[fields[0]] || fields[0] })
      if (fields[1] === "1") active = fields[0]
    }
    root.profiles = available
    root.activeProfile = active
  }

  function refreshProfiles() {
    if (!profileProbe.running) profileProbe.running = true
  }

  function setProfile(profile) {
    root.activeProfile = profile
    root.commandRequested("blob-power-set autodetect " + profile)
    profileSettleTimer.restart()
  }

  onPollingChanged: if (root.polling) root.refreshProfiles()

  SystemStats {
    id: stats
    polling: root.polling
  }

  Process {
    id: profileProbe
    command: ["blob-power-list", "--active-state"]
    stdout: StdioCollector { onStreamFinished: root.readProfiles(text) }
  }

  Timer {
    id: profileSettleTimer
    interval: 500
    onTriggered: root.refreshProfiles()
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
    icon: ""
    name: "Temperature"
    percent: stats.temperature
    detail: stats.temperature + "°C"
  }

  Text {
    width: parent.width
    visible: stats.loadAverage !== ""
    text: "Load average  " + stats.loadAverage
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.7)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Row {
    width: parent.width
    visible: root.profiles.length > 0
    spacing: Style.spaceReal(6)

    Repeater {
      model: root.profiles

      Button {
        required property var modelData
        width: (parent.width - parent.spacing * (root.profiles.length - 1)) / root.profiles.length
        text: modelData.label
        selected: modelData.value === root.activeProfile
        bordered: true
        fontSize: Style.font.bodySmall
        onClicked: root.setProfile(modelData.value)
      }
    }
  }

  Button {
    width: parent.width
    text: "Open btop"
    iconText: "󰍛"
    bordered: true
    fontSize: Style.font.bodySmall
    onClicked: root.tuiRequested("btop")
  }
}

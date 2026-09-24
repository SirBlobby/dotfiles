import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property string blobPath: Quickshell.env("BLOB_PATH")
  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: (manifest && manifest.id) || "blob.quick-settings"

  readonly property int barInset: {
    var bar = root.shell ? root.shell.bar : null
    if (!bar || bar.barHidden === true) return 0
    if (String(bar.position || "top") !== "top") return 0
    return Math.max(0, bar.barSize || 0)
  }

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

  function run(command) {
    Quickshell.execDetached(["bash", "-c", command])
  }

  function runAndDismiss(command) {
    root.run(command)
    root.dismiss()
  }

  function openPanel(pluginId) {
    root.dismiss()
    if (root.shell && typeof root.shell.summon === "function") root.shell.summon(pluginId, "")
    else root.run("blob-shell shell summon " + pluginId)
  }

  function refreshState() {
    bluetoothFlag.refresh()
    dndFlag.refresh()
    nightLightFlag.refresh()
    stayAwakeFlag.refresh()
    tabletFlag.refresh()
    recordingFlag.refresh()
    volumeValue.refresh()
    mutedFlag.refresh()
    brightnessValue.refresh()
    mediaValue.refresh()
  }

  function toggleAndRefresh(command) {
    root.run(command)
    stateSettleTimer.restart()
  }

  Timer {
    id: stateSettleTimer
    interval: 250
    onTriggered: root.refreshState()
  }

  PolledFlag {
    id: bluetoothFlag
    polling: root.opened
    command: "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"
  }

  PolledFlag {
    id: dndFlag
    polling: root.opened
    command: "blob-shell notifications dndState 2>/dev/null"
  }

  PolledFlag {
    id: nightLightFlag
    polling: root.opened
    command: "blob-toggle-nightlight --status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: stayAwakeFlag
    polling: root.opened
    command: "blob-toggle-idle status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: tabletFlag
    polling: root.opened
    command: "blob-toggle-tablet status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: recordingFlag
    polling: root.opened
    command: "pgrep -f '^gpu-screen-recorder' >/dev/null && echo on || echo off"
  }

  PolledFlag {
    id: mutedFlag
    polling: root.opened
    intervalMs: 1000
    command: "pamixer --get-mute 2>/dev/null | grep -qx true && echo on || echo off"
  }

  PolledText {
    id: volumeValue
    polling: root.opened
    intervalMs: 1000
    command: "pamixer --get-volume 2>/dev/null || echo 0"
  }

  PolledText {
    id: brightnessValue
    polling: root.opened
    intervalMs: 2000
    command: "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 0"
  }

  PolledText {
    id: clockValue
    polling: root.opened
    intervalMs: 1000
    command: "date '+%H:%M'"
  }

  PolledText {
    id: dateValue
    polling: root.opened
    intervalMs: 10000
    command: "date '+%A, %B %-d'"
  }

  PolledText {
    id: mediaValue
    polling: root.opened
    intervalMs: 1000
    command: "playerctl metadata -f '{{title}}|||{{artist}}|||{{status}}' 2>/dev/null || echo 'No Media||||||Stopped'"
  }

  PolledText {
    id: weatherValue
    polling: root.opened
    intervalMs: 600000
    command: "blob-weather-card 2>/dev/null"
  }

  readonly property var mediaParts: String(mediaValue.value).split("|||")

  // blob-weather-card prints "<glyph>    <place>  .  Temp <t>  .  Wind <w>",
  // with the separator spelled with a middle dot. Anything shorter than three
  // fields is the failure line, which the card shows as unavailable.
  readonly property var weatherFields: String(weatherValue.value).split("  \u00b7  ")
  readonly property bool weatherAvailable: weatherFields.length >= 3
  readonly property var weatherHead: weatherAvailable
    ? String(weatherFields[0]).match(/^(\S+)\s*(.*)$/) : null
  readonly property string weatherGlyph: weatherHead ? weatherHead[1] : ""
  readonly property string weatherPlace: weatherHead
    ? String(weatherHead[2]).trim() : (weatherValue.value.length > 0 ? weatherValue.value : "Loading...")
  readonly property string weatherTemperature: weatherAvailable
    ? String(weatherFields[1]).replace(/^Temp\s*/, "") : ""
  readonly property string weatherWind: weatherAvailable
    ? String(weatherFields[2]).replace(/^Wind\s*/, "") : ""

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-quick-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    WeatherCard {
      anchors.top: controlCentre.top
      anchors.right: controlCentre.left
      anchors.rightMargin: Style.spaceReal(12)
      available: root.weatherAvailable
      glyph: root.weatherGlyph
      place: root.weatherPlace
      temperature: root.weatherTemperature
      wind: root.weatherWind
    }

    Card {
      id: controlCentre
      anchors.top: parent.top
      anchors.topMargin: Style.spaceReal(10) + root.barInset
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: Style.spaceReal(400)
      fillColor: Util.alpha(Color.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(12)

      Header {
        width: parent.width
        clock: clockValue.value
        today: dateValue.value
        onLockRequested: root.runAndDismiss("blob-system-lock")
        onLogoutRequested: root.runAndDismiss("blob-system-logout")
        onCloseRequested: root.dismiss()
      }

      Calendar {
        width: parent.width
        polling: root.opened
      }

      Tiles {
        width: parent.width
        bluetoothOn: bluetoothFlag.value
        doNotDisturb: dndFlag.value
        nightLight: nightLightFlag.value
        recording: recordingFlag.value
        stayAwake: stayAwakeFlag.value
        tabletFollow: tabletFlag.value
        onRunRequested: function(command) { root.runAndDismiss(command) }
        onPanelRequested: function(pluginId) { root.openPanel(pluginId) }
        onToggleRequested: function(command) { root.toggleAndRefresh(command) }
      }

      SliderRow {
        width: parent.width
        icon: mutedFlag.value ? "\uf026" : "\uf028"
        dimmed: mutedFlag.value
        value: Number(volumeValue.value) || 0
        onIconActivated: root.toggleAndRefresh("pamixer --toggle-mute")
        onValueRequested: function(next) {
          root.run("pamixer --set-volume " + next)
          volumeValue.value = String(next)
        }
      }

      SliderRow {
        width: parent.width
        icon: "\uf185"
        value: Number(brightnessValue.value) || 0
        onValueRequested: function(next) {
          root.run("brightnessctl set " + next + "%")
          brightnessValue.value = String(next)
        }
      }

      MediaRow {
        width: parent.width
        title: root.mediaParts.length > 0 ? root.mediaParts[0] : ""
        artist: root.mediaParts.length > 1 ? root.mediaParts[1] : ""
        status: root.mediaParts.length > 2 ? root.mediaParts[2] : "Stopped"
        onControlRequested: function(action) {
          root.run("playerctl " + action)
          stateSettleTimer.restart()
        }
      }
    }
  }

  onOpenedChanged: if (root.opened) root.refreshState()
}

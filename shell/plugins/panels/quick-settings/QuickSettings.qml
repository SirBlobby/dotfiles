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

  readonly property var tabs: [
    { id: "general", label: "General", icon: "" },
    { id: "sound", label: "Sound & Music", icon: "" },
    { id: "performance", label: "Performance", icon: "" },
    { id: "quick", label: "Quick Settings", icon: "" }
  ]
  property string currentTab: "general"
  readonly property bool generalVisible: opened && currentTab === "general"
  readonly property bool soundVisible: opened && currentTab === "sound"
  readonly property bool performanceVisible: opened && currentTab === "performance"
  readonly property bool quickVisible: opened && currentTab === "quick"

  readonly property var idleConfig: root.shell && root.shell.shellConfig && root.shell.shellConfig.idle
    ? root.shell.shellConfig.idle : ({})
  readonly property int screensaverSeconds: root.timeoutSeconds(idleConfig.screensaver, 150)
  readonly property int lockSeconds: root.timeoutSeconds(idleConfig.lock, 300)

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
    micVolumeValue.refresh()
    micMutedFlag.refresh()
    brightnessValue.refresh()
    mediaValue.refresh()
  }

  function timeoutSeconds(value, fallback) {
    var seconds = Number(value)
    return isFinite(seconds) && seconds >= 0 ? Math.floor(seconds) : fallback
  }

  function setIdleTimeout(key, seconds) {
    if (!root.shell || typeof root.shell.mutateShellConfig !== "function") return
    root.shell.mutateShellConfig(function(config) {
      if (!config.idle || typeof config.idle !== "object") config.idle = {}
      config.idle[key] = seconds
    })
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
    polling: root.quickVisible
    command: "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"
  }

  PolledFlag {
    id: dndFlag
    polling: root.quickVisible
    command: "blob-shell notifications dndState 2>/dev/null"
  }

  PolledFlag {
    id: nightLightFlag
    polling: root.quickVisible
    command: "blob-toggle-nightlight --status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: stayAwakeFlag
    polling: root.quickVisible || root.generalVisible
    command: "blob-toggle-idle status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: tabletFlag
    polling: root.quickVisible
    command: "blob-toggle-tablet status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off"
  }

  PolledFlag {
    id: recordingFlag
    polling: root.quickVisible
    command: "pgrep -f '^gpu-screen-recorder' >/dev/null && echo on || echo off"
  }

  PolledFlag {
    id: mutedFlag
    polling: root.soundVisible
    intervalMs: 1000
    command: "pamixer --get-mute 2>/dev/null | grep -qx true && echo on || echo off"
  }

  PolledText {
    id: volumeValue
    polling: root.soundVisible
    intervalMs: 1000
    command: "pamixer --get-volume 2>/dev/null || echo 0"
  }

  PolledFlag {
    id: micMutedFlag
    polling: root.soundVisible
    intervalMs: 1000
    command: "pamixer --default-source --get-mute 2>/dev/null | grep -qx true && echo on || echo off"
  }

  PolledText {
    id: micVolumeValue
    polling: root.soundVisible
    intervalMs: 1000
    command: "pamixer --default-source --get-volume 2>/dev/null || echo 0"
  }

  PolledText {
    id: brightnessValue
    polling: root.generalVisible
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
    polling: root.soundVisible
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
      implicitWidth: Math.max(Style.spaceReal(520), tabBar.requiredWidth + padding * 2)
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

      TabBar {
        id: tabBar
        width: parent.width
        tabs: root.tabs
        currentTab: root.currentTab
        onTabRequested: function(tabId) { root.currentTab = tabId }
      }

      GeneralTab {
        width: parent.width
        visible: root.currentTab === "general"
        polling: root.generalVisible
        brightness: Number(brightnessValue.value) || 0
        screensaverSeconds: root.screensaverSeconds
        lockSeconds: root.lockSeconds
        stayAwake: stayAwakeFlag.value
        onBrightnessRequested: function(next) {
          root.run("brightnessctl set " + next + "%")
          brightnessValue.value = String(next)
        }
        onTimeoutRequested: function(key, seconds) { root.setIdleTimeout(key, seconds) }
      }

      SoundTab {
        width: parent.width
        visible: root.currentTab === "sound"
        outputVolume: Number(volumeValue.value) || 0
        outputMuted: mutedFlag.value
        inputVolume: Number(micVolumeValue.value) || 0
        inputMuted: micMutedFlag.value
        mediaParts: root.mediaParts
        onCommandRequested: function(command) { root.toggleAndRefresh(command) }
        onOutputVolumeRequested: function(next) {
          root.run("pamixer --set-volume " + next)
          volumeValue.value = String(next)
        }
        onInputVolumeRequested: function(next) {
          root.run("pamixer --default-source --set-volume " + next)
          micVolumeValue.value = String(next)
        }
        onMediaControlRequested: function(action) {
          root.run("playerctl " + action)
          stateSettleTimer.restart()
        }
        onPanelRequested: function(pluginId) { root.openPanel(pluginId) }
        onAppRequested: function(command) { root.runAndDismiss("uwsm-app -- " + command) }
      }

      PerformanceTab {
        width: parent.width
        visible: root.currentTab === "performance"
        polling: root.performanceVisible
        onCommandRequested: function(command) { root.run(command) }
        onTuiRequested: function(command) { root.runAndDismiss("blob-launch-or-focus-tui " + command) }
      }

      Tiles {
        width: parent.width
        visible: root.currentTab === "quick"
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
    }
  }

  onOpenedChanged: if (root.opened) root.refreshState()
}

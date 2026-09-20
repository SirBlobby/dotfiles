import QtQuick
import qs.Commons

Grid {
  id: root

  property bool bluetoothOn: false
  property bool doNotDisturb: false
  property bool nightLight: false
  property bool recording: false
  property bool stayAwake: false
  property bool tabletFollow: false

  signal runRequested(string command)
  signal panelRequested(string pluginId)
  signal toggleRequested(string command)

  columns: 3
  columnSpacing: Style.spaceReal(8)
  rowSpacing: Style.spaceReal(8)

  Tile {
    icon: ""
    label: "Wi-Fi"
    onActivated: root.panelRequested("blob.network")
  }

  Tile {
    icon: ""
    label: "Bluetooth"
    active: root.bluetoothOn
    onActivated: root.panelRequested("blob.bluetooth")
  }

  Tile {
    icon: ""
    label: "Wallpaper"
    onActivated: root.runRequested("blob-wallpaper-set --menu")
  }

  Tile {
    icon: ""
    label: "Silence"
    active: root.doNotDisturb
    onActivated: root.toggleRequested("blob-shell notifications toggleDnd")
  }

  Tile {
    icon: ""
    label: "Night Light"
    active: root.nightLight
    onActivated: root.toggleRequested("blob-toggle-nightlight")
  }

  Tile {
    icon: ""
    label: "Record"
    active: root.recording
    tooltip: root.recording ? "Stop screen recording" : "Start a screen recording"
    onActivated: root.runRequested(root.recording
      ? "blob-capture-record --stop-recording"
      : "blob-menu toggle trigger.capture.screenrecord")
  }

  Tile {
    icon: "󰅶"
    label: "Stay Awake"
    active: root.stayAwake
    tooltip: root.stayAwake ? "Allow idle lock and screensaver" : "Keep the screen awake"
    onActivated: root.toggleRequested("blob-toggle-idle toggle")
  }

  Tile {
    icon: ""
    label: "Pick Color"
    onActivated: root.runRequested("hyprpicker -a")
  }

  Tile {
    icon: ""
    label: "Theme"
    onActivated: root.runRequested("blob-theme-menu")
  }

  Tile {
    icon: ""
    label: "Tablet Lock"
    active: root.tabletFollow
    tooltip: root.tabletFollow ? "Tablet follows focused monitor" : "Tablet spans all monitors"
    onActivated: root.toggleRequested("blob-toggle-tablet toggle")
  }
}

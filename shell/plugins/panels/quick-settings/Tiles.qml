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
  readonly property real tileWidth: (width - columnSpacing * (columns - 1)) / columns
  columnSpacing: Style.spaceReal(8)
  rowSpacing: Style.spaceReal(8)

  Tile {
    width: root.tileWidth
    icon: "\uf1eb"
    label: "Wi-Fi"
    onActivated: root.panelRequested("blob.network")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf293"
    label: "Bluetooth"
    active: root.bluetoothOn
    onActivated: root.panelRequested("blob.bluetooth")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf03e"
    label: "Wallpaper"
    onActivated: root.panelRequested("blob.displays")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf1f6"
    label: "Silence"
    active: root.doNotDisturb
    onActivated: root.toggleRequested("blob-shell notifications toggleDnd")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf186"
    label: "Night Light"
    active: root.nightLight
    onActivated: root.toggleRequested("blob-toggle-nightlight")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf03d"
    label: "Record"
    active: root.recording
    tooltip: root.recording ? "Stop screen recording" : "Start a screen recording"
    onActivated: root.runRequested(root.recording
      ? "blob-capture-record --stop-recording"
      : "blob-menu toggle trigger.capture.screenrecord")
  }

  Tile {
    width: root.tileWidth
    icon: "󰅶"
    label: "Stay Awake"
    active: root.stayAwake
    tooltip: root.stayAwake ? "Allow idle lock and screensaver" : "Keep the screen awake"
    onActivated: root.toggleRequested("blob-toggle-idle toggle")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf1fb"
    label: "Pick Color"
    onActivated: root.runRequested("hyprpicker -a")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf1fc"
    label: "Theme"
    onActivated: root.runRequested("blob-theme-menu")
  }

  Tile {
    width: root.tileWidth
    icon: "\uf10a"
    label: "Tablet Lock"
    active: root.tabletFollow
    tooltip: root.tabletFollow ? "Tablet follows focused monitor" : "Tablet spans all monitors"
    onActivated: root.toggleRequested("blob-toggle-tablet toggle")
  }
}

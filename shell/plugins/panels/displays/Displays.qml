import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "DisplayModel.js" as DisplayModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: (manifest && manifest.id) || "blob.displays"
  readonly property string home: Quickshell.env("HOME")

  property var monitors: []
  property string selectedName: ""
  property string activeTab: "monitors"
  property var assignments: ({})
  property bool layoutDirty: false

  readonly property var selectedMonitor: {
    for (var i = 0; i < root.monitors.length; i++)
      if (root.monitors[i].name === root.selectedName) return root.monitors[i]
    return null
  }

  function open(payloadJson) {
    root.opened = true
    root.refresh()
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

  function refresh() {
    if (!monitorProc.running) monitorProc.running = true
    if (!assignmentProc.running) assignmentProc.running = true
  }

  function loadMonitors(raw) {
    var parsed = DisplayModel.parseMonitors(raw)
    root.monitors = parsed
    root.layoutDirty = false
    if (root.selectedName.length > 0) {
      for (var i = 0; i < parsed.length; i++)
        if (parsed[i].name === root.selectedName) return
    }
    root.selectedName = parsed.length > 0 ? parsed[0].name : ""
  }

  function loadAssignments(raw) {
    var next = ({})
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue
      var split = line.indexOf("\t")
      if (split <= 0) continue
      next[line.substring(0, split)] = line.substring(split + 1)
    }
    root.assignments = next
  }

  // Mutating the array in place would not retrigger the bindings the canvas
  // reads, so every edit rebuilds it.
  function replaceMonitor(name, changes) {
    var next = []
    for (var i = 0; i < root.monitors.length; i++) {
      var monitor = root.monitors[i]
      if (monitor.name !== name) {
        next.push(monitor)
        continue
      }
      var copy = ({})
      for (var key in monitor) copy[key] = monitor[key]
      for (var change in changes) copy[change] = changes[change]
      next.push(copy)
    }
    root.monitors = next
    root.layoutDirty = true
  }

  function moveMonitor(name, x, y) {
    var snapped = DisplayModel.snapPosition(root.monitors, name, x, y, 60)
    root.replaceMonitor(name, { x: snapped.x, y: snapped.y })
  }

  function applyMonitor(name) {
    for (var i = 0; i < root.monitors.length; i++) {
      if (root.monitors[i].name !== name) continue
      root.run("blob-display-arrange apply " + Util.shellQuote(DisplayModel.monitorKeyword(root.monitors[i])))
      return
    }
  }

  function applyLayout() {
    var keywords = DisplayModel.keywordsFor(root.monitors)
    var quoted = []
    for (var i = 0; i < keywords.length; i++) quoted.push(Util.shellQuote(keywords[i]))
    root.run("blob-display-arrange apply " + quoted.join(" "))
    root.layoutDirty = false
    reloadTimer.restart()
  }

  function resetLayout() {
    root.run("blob-display-arrange reset")
    reloadTimer.restart()
  }

  function assignWallpaper(path) {
    if (root.selectedName.length === 0) return
    root.run("blob-bg-monitor " + Util.shellQuote(root.selectedName) + " " + Util.shellQuote(path))
    var next = ({})
    for (var key in root.assignments) next[key] = root.assignments[key]
    next[root.selectedName] = path
    root.assignments = next
  }

  function clearAssignment() {
    if (root.selectedName.length === 0) return
    root.run("blob-bg-monitor " + Util.shellQuote(root.selectedName) + " --clear")
    var next = ({})
    for (var key in root.assignments)
      if (key !== root.selectedName) next[key] = root.assignments[key]
    root.assignments = next
  }

  function setGlobalWallpaper(path) {
    root.run("blob-bg-set " + Util.shellQuote(path))
  }

  Process {
    id: monitorProc
    command: ["hyprctl", "monitors", "all", "-j"]
    stdout: StdioCollector { onStreamFinished: root.loadMonitors(text) }
  }

  Process {
    id: assignmentProc
    command: ["bash", "-c",
      'dir="$HOME/.local/state/blob/backgrounds"; [[ -d $dir ]] || exit 0; ' +
      'for link in "$dir"/*; do [[ -e $link ]] || continue; ' +
      'printf "%s\\t%s\\n" "${link##*/}" "$(readlink -f "$link")"; done']
    stdout: StdioCollector { onStreamFinished: root.loadAssignments(text) }
  }

  Timer {
    id: reloadTimer
    interval: 400
    onTriggered: root.refresh()
  }

  Timer {
    interval: 4000
    running: root.opened && !root.layoutDirty
    repeat: true
    onTriggered: root.refresh()
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-displays"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Card {
      anchors.centerIn: parent
      implicitWidth: Style.spaceReal(760)
      implicitHeight: Style.spaceReal(560)
      fillColor: Util.alpha(Color.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(10)

      Item {
        width: parent.width
        implicitHeight: Math.max(title.implicitHeight, tabs.implicitHeight)

        Text {
          id: title
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Displays"
          textFormat: Text.PlainText
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Row {
          id: tabs
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spaceReal(6)

          Chip {
            label: "Monitors"
            active: root.activeTab === "monitors"
            onActivated: root.activeTab = "monitors"
          }

          Chip {
            label: "Wallpapers"
            active: root.activeTab === "wallpapers"
            onActivated: root.activeTab = "wallpapers"
          }

          CardIconButton {
            icon: ""
            onActivated: root.dismiss()
          }
        }
      }

      MonitorCanvas {
        width: parent.width
        height: Style.spaceReal(200)
        monitors: root.monitors
        selectedName: root.selectedName
        onSelected: function(name) { root.selectedName = name }
        onMonitorMoved: function(name, x, y) { root.moveMonitor(name, x, y) }
        onLayoutSettled: root.applyMonitor(root.selectedName)
      }

      Item {
        width: parent.width
        height: Style.spaceReal(250)

        MonitorControls {
          anchors.fill: parent
          visible: root.activeTab === "monitors"
          monitor: root.selectedMonitor
          monitors: root.monitors
          onScaleRequested: function(scale) {
            root.replaceMonitor(root.selectedName, { scale: scale })
            root.applyMonitor(root.selectedName)
          }
          onModeRequested: function(mode) {
            root.replaceMonitor(root.selectedName, { mode: mode })
            root.applyMonitor(root.selectedName)
          }
          onEnabledRequested: function(enabled) {
            root.replaceMonitor(root.selectedName, { disabled: !enabled })
            root.applyMonitor(root.selectedName)
          }
          onMirrorRequested: function(target) {
            root.replaceMonitor(root.selectedName, { mirrorOf: target })
            root.applyMonitor(root.selectedName)
          }
        }

        Column {
          anchors.fill: parent
          visible: root.activeTab === "wallpapers"
          spacing: Style.spaceReal(8)

          Item {
            width: parent.width
            implicitHeight: assignedLabel.implicitHeight

            Text {
              id: assignedLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: root.selectedName.length > 0
                ? (root.assignments[root.selectedName]
                    ? root.selectedName + ": " + String(root.assignments[root.selectedName]).replace(/^.*\//, "")
                    : root.selectedName + ": following the global wallpaper")
                : "Select a monitor above"
              textFormat: Text.PlainText
              color: Util.alpha(Color.foreground, 0.8)
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Chip {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              label: "Clear"
              enabled: root.selectedName.length > 0 && !!root.assignments[root.selectedName]
              onActivated: root.clearAssignment()
            }
          }

          WallpaperGrid {
            width: parent.width
            height: parent.height - assignedLabel.implicitHeight - Style.spaceReal(8)
            polling: root.opened && root.activeTab === "wallpapers"
            assignedPath: root.selectedName.length > 0
              ? String(root.assignments[root.selectedName] || "") : ""
            onChosen: function(path) { root.assignWallpaper(path) }
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.spaceReal(6)

        Chip {
          label: root.layoutDirty ? "Apply all" : "Re-apply all"
          active: root.layoutDirty
          onActivated: root.applyLayout()
        }

        Chip {
          label: "Reset to monitors.lua"
          onActivated: root.resetLayout()
        }

        Chip {
          label: "Set globally"
          enabled: root.activeTab === "wallpapers" && root.selectedName.length > 0
            && !!root.assignments[root.selectedName]
          onActivated: root.setGlobalWallpaper(String(root.assignments[root.selectedName]))
        }
      }
    }
  }

  onOpenedChanged: if (root.opened) root.refresh()
}

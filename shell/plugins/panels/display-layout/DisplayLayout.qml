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

  readonly property string pluginId: (manifest && manifest.id) || "blob.display-layout"
  readonly property int snapThreshold: 60

  property var monitors: []
  property string selectedName: ""
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
    var snapped = DisplayModel.snapPosition(root.monitors, name, x, y, root.snapThreshold)
    root.replaceMonitor(name, { x: snapped.x, y: snapped.y })
  }

  function applyMonitor(name) {
    for (var i = 0; i < root.monitors.length; i++) {
      if (root.monitors[i].name !== name) continue
      root.run("blob-display-arrange apply "
        + Util.shellQuote(DisplayModel.monitorKeyword(root.monitors[i])))
      reloadTimer.restart()
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

  Process {
    id: monitorProc
    command: ["hyprctl", "monitors", "all", "-j"]
    stdout: StdioCollector { onStreamFinished: root.loadMonitors(text) }
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

  onOpenedChanged: if (root.opened) root.refresh()

  PanelWindow {
    id: panelWindow
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-display-layout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Card {
      id: layoutCard

      readonly property real screenMargin: Style.spaceReal(20)
      readonly property real maxHeight: panelWindow.height - screenMargin * 2
      readonly property real fixedContentHeight: header.height + hint.height + canvas.height
        + actions.height + spacing * 4 + padding * 2

      anchors.centerIn: parent
      implicitWidth: Math.min(Style.spaceReal(720), panelWindow.width - screenMargin * 2)
      fillColor: Util.alpha(Colors.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(10)

      Item {
        id: header
        width: parent.width
        implicitHeight: Math.max(title.implicitHeight, closeButton.implicitHeight)

        Text {
          id: title
          anchors.left: parent.left
          anchors.right: closeButton.left
          anchors.rightMargin: Style.spaceReal(8)
          anchors.verticalCenter: parent.verticalCenter
          text: "Display layout"
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: Colors.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        CardIconButton {
          id: closeButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          icon: "\uf00d"
          onActivated: root.dismiss()
        }
      }

      Text {
        id: hint
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Drag a monitor to move it. Edges snap to a neighbour. Changes apply as you drop and last until the session ends."
        textFormat: Text.PlainText
        color: Util.alpha(Colors.foreground, 0.6)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      MonitorCanvas {
        id: canvas
        width: parent.width
        height: Style.spaceReal(220)
        monitors: root.monitors
        selectedName: root.selectedName
        onSelected: function(name) { root.selectedName = name }
        onMonitorMoved: function(name, x, y) { root.moveMonitor(name, x, y) }
        onLayoutSettled: root.applyMonitor(root.selectedName)
      }

      Flickable {
        id: controlsScroll
        width: parent.width
        height: Math.max(0, Math.min(controls.implicitHeight, layoutCard.maxHeight - layoutCard.fixedContentHeight))
        contentWidth: width
        contentHeight: controls.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        MonitorControls {
          id: controls
          width: controlsScroll.width
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
      }

      Flow {
        id: actions
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
      }
    }
  }
}

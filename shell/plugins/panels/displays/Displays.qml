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

  readonly property string pluginId: (manifest && manifest.id) || "blob.displays"

  property var outputs: []
  property string selectedName: ""
  property var assignments: ({})

  readonly property bool globalMode: root.selectedName === ""
  readonly property string assignedPath: root.globalMode
    ? "" : String(root.assignments[root.selectedName] || "")

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
    if (!outputProc.running) outputProc.running = true
    if (!assignmentProc.running) assignmentProc.running = true
  }

  function loadOutputs(raw) {
    var names = []
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.length > 0) names.push(line)
    }
    root.outputs = names
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

  function choose(path) {
    if (root.globalMode) {
      root.run("blob-bg-set " + Util.shellQuote(path))
      return
    }
    root.run("blob-bg-monitor " + Util.shellQuote(root.selectedName)
      + " " + Util.shellQuote(path))
    var next = ({})
    for (var key in root.assignments) next[key] = root.assignments[key]
    next[root.selectedName] = path
    root.assignments = next
  }

  function clearAssignment() {
    if (root.globalMode) return
    root.run("blob-bg-monitor " + Util.shellQuote(root.selectedName) + " --clear")
    var next = ({})
    for (var key in root.assignments)
      if (key !== root.selectedName) next[key] = root.assignments[key]
    root.assignments = next
  }

  Process {
    id: outputProc
    command: ["bash", "-c", "hyprctl monitors -j | jq -r '.[].name'"]
    stdout: StdioCollector { onStreamFinished: root.loadOutputs(text) }
  }

  Process {
    id: assignmentProc
    command: ["bash", "-c",
      'dir="$HOME/.local/state/blob/backgrounds"; [[ -d $dir ]] || exit 0; ' +
      'for link in "$dir"/*; do [[ -e $link ]] || continue; ' +
      'printf "%s\\t%s\\n" "${link##*/}" "$(readlink -f "$link")"; done']
    stdout: StdioCollector { onStreamFinished: root.loadAssignments(text) }
  }

  onOpenedChanged: if (root.opened) root.refresh()

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Card {
      anchors.centerIn: parent
      implicitWidth: Style.spaceReal(720)
      implicitHeight: Style.spaceReal(520)
      fillColor: Util.alpha(Colors.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(10)

      Item {
        width: parent.width
        implicitHeight: Math.max(title.implicitHeight, closeButton.implicitHeight)

        Text {
          id: title
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Wallpapers"
          textFormat: Text.PlainText
          color: Colors.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        CardIconButton {
          id: closeButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          icon: ""
          onActivated: root.dismiss()
        }
      }

      Flow {
        width: parent.width
        spacing: Style.spaceReal(4)

        Chip {
          label: "All monitors"
          active: root.globalMode
          onActivated: root.selectedName = ""
        }

        Repeater {
          model: root.outputs

          Chip {
            required property var modelData
            label: root.assignments[modelData]
              ? String(modelData) + " *" : String(modelData)
            active: root.selectedName === modelData
            onActivated: root.selectedName = String(modelData)
          }
        }
      }

      Item {
        width: parent.width
        implicitHeight: status.implicitHeight

        Text {
          id: status
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.globalMode
            ? "Setting the wallpaper for every monitor without its own"
            : (root.assignedPath.length > 0
                ? root.selectedName + ": " + root.assignedPath.replace(/^.*\//, "")
                : root.selectedName + ": following the global wallpaper")
          textFormat: Text.PlainText
          color: Util.alpha(Colors.foreground, 0.7)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Chip {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          label: "Clear"
          enabled: !root.globalMode && root.assignedPath.length > 0
          onActivated: root.clearAssignment()
        }
      }

      WallpaperGrid {
        width: parent.width
        height: Style.spaceReal(340)
        polling: root.opened
        assignedPath: root.globalMode ? "" : root.assignedPath
        onChosen: function(path) { root.choose(path) }
      }
    }
  }
}

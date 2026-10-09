import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "HistoryModel.js" as HistoryModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: (manifest && manifest.id) || "blob.notification-center"
  readonly property string historyDir: Quickshell.env("HOME") + "/.local/state/blob/notifications/history"

  property var entries: []
  property bool doNotDisturb: false
  readonly property bool empty: root.entries.length === 0

  readonly property int barInset: {
    var bar = root.shell ? root.shell.bar : null
    if (!bar || bar.barHidden === true) return 0
    return Math.max(0, bar.barSize || 0)
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

  function refresh() {
    if (!historyProbe.running) historyProbe.running = true
    if (!dndProbe.running) dndProbe.running = true
  }

  function run(command) {
    Quickshell.execDetached(["bash", "-c", command])
  }

  function clearAll() {
    root.run("blob-shell notifications clear")
    root.entries = []
    refreshTimer.restart()
  }

  function toggleSilence() {
    root.run("blob-shell notifications toggleDnd")
    refreshTimer.restart()
  }

  function dismissEntry(index) {
    var entry = root.entries[index]
    if (!entry) return
    root.run("blob-shell notifications remove " + Util.shellQuote(entry.fileName))
    var next = []
    for (var i = 0; i < root.entries.length; i++)
      if (i !== index) next.push(root.entries[i])
    root.entries = next
    refreshTimer.restart()
  }

  Process {
    id: historyProbe
    command: ["bash", "-c",
      "for f in \"$1\"/*.json; do [[ -e $f ]] || continue; printf '%s\\t' \"${f##*/}\"; awk 1 \"$f\"; done",
      "--", root.historyDir]
    stdout: StdioCollector {
      onStreamFinished: root.entries = HistoryModel.parseHistory(text)
    }
  }

  Process {
    id: dndProbe
    command: ["bash", "-c", "blob-shell notifications dndState 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: root.doNotDisturb = String(text).trim() === "on"
    }
  }

  Timer {
    id: refreshTimer
    interval: 250
    onTriggered: root.refresh()
  }

  Timer {
    interval: 5000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Card {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.spaceReal(10) + root.barInset
      anchors.rightMargin: Style.spaceReal(10)
      implicitWidth: Style.spaceReal(440)
      implicitHeight: Style.spaceReal(420)
      fillColor: Util.alpha(Colors.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(10)

      Item {
        width: parent.width
        implicitHeight: titleText.implicitHeight

        Text {
          id: titleText
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Notifications"
          textFormat: Text.PlainText
          color: Colors.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spaceReal(4)

          CardIconButton {
            icon: root.doNotDisturb ? "\uf1f6" : "\uf0f3"
            active: root.doNotDisturb
            onActivated: root.toggleSilence()
          }

          CardIconButton {
            icon: "\uf1f8"
            onActivated: root.clearAll()
          }
        }
      }

      ListView {
        width: parent.width
        height: Style.spaceReal(340)
        clip: true
        spacing: Style.spaceReal(8)
        visible: !root.empty
        model: root.entries

        delegate: NotificationItem {
          required property var modelData
          required property int index
          width: ListView.view.width
          app: modelData.app
          summary: modelData.summary
          body: modelData.body
          onDismissRequested: root.dismissEntry(index)
        }
      }

      Column {
        width: parent.width
        visible: root.empty
        spacing: Style.spaceReal(8)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "\uf0a2"
          textFormat: Text.PlainText
          color: Util.alpha(Colors.blue, 0.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "No notifications"
          textFormat: Text.PlainText
          color: Util.alpha(Colors.foreground, 0.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}

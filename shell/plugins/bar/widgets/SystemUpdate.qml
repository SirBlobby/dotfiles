import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "blob.system-update"

  property bool updateAvailable: false

  function refresh() {
    if (!updateProc.running) updateProc.running = true
  }

  function clear() { updateAvailable = false }

  function runUpdate() {
    if (root.bar) root.bar.run("blob-launch-floating blob-update")
  }

  visible: updateAvailable
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  IpcHandler {
    target: "blob.system-update"

    function refresh(): void {
      root.broadcast("refresh")
    }

    function clear(): void {
      root.broadcast("clear")
    }
  }

  Process {
    id: updateProc
    command: ["blob-update-available"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const pending = parseInt(String(text).trim(), 10)
        root.updateAvailable = !isNaN(pending) && pending > 0
      }
    }
  }

  Timer {
    interval: 21600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  FileView {
    path: "/var/log/pacman.log"
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: packageChangeDelay.restart()
  }

  Timer {
    id: packageChangeDelay
    interval: 5000
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf021"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Pending Blob Updates"
    onPressed: root.runUpdate()
  }
}

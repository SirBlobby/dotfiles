import QtQuick
import Quickshell.Io

Item {
  id: root
  visible: false

  property var settings: ({})
  property var record: null
  property int dataRevision: 0
  property string pendingUpdateKind: ""

  readonly property int refreshIntervalSec: Math.max(30, Number(setting("refreshIntervalSec", 900)) || 900)

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() { runUpdate("force") }
  function refreshLimits() { runUpdate("limits") }

  function updateCommand(kind) {
    var command = ["blob-agent-usage-claude"]
    if (kind === "force") command.push("--force")
    if (kind === "limits") command.push("--limits-only")
    return command
  }

  function runUpdate(kind) {
    if (collectorProcess.running) {
      if (kind === "force" || pendingUpdateKind === "") pendingUpdateKind = kind
      return
    }
    collectorProcess.command = updateCommand(kind)
    collectorProcess.running = true
  }

  function applyRecord(text) {
    try {
      var parsed = JSON.parse(String(text || ""))
      if (!parsed || typeof parsed !== "object") return
      record = parsed
      dataRevision++
      if (parsed.retryAdvised === true) limitsRetry.restart()
      else limitsRetry.stop()
    } catch (error) {
      console.warn("agents", "Ignoring bad usage record", error)
    }
  }

  Process {
    id: collectorProcess
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyRecord(text)
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("agents", text.trim())
    }

    onExited: {
      if (root.pendingUpdateKind === "") return
      var kind = root.pendingUpdateKind
      root.pendingUpdateKind = ""
      root.runUpdate(kind)
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.runUpdate("normal")
  }

  Timer {
    id: limitsRetry
    interval: 30000
    repeat: false
    onTriggered: root.runUpdate("limits")
  }
}

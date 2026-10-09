import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "blob.claude-usage"
  ipcTarget: "blob.claude-usage"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property var usage: ({ session: null, weekly: null, weeklyOpus: null })
  property string errorMessage: ""
  property bool loading: false
  property double nowMs: Date.now()

  readonly property bool hasUsage: usage.session !== null || usage.weekly !== null
  readonly property int refreshMinutes: Math.max(1, parseInt(setting("refreshMinutes", 5), 10) || 5)

  function open() {
    root.controller.show()
    root.refresh()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    root.nowMs = Date.now()
    if (usageProcess.running) return
    root.loading = true
    usageProcess.running = true
  }

  Process {
    id: usageProcess
    command: ["blob-claude-usage"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsedUsage = Model.parseUsage(text)
        if (parsedUsage.session !== null || parsedUsage.weekly !== null) {
          root.usage = parsedUsage
          root.errorMessage = ""
        }
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.errorMessage = message
      }
    }

    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0 && root.errorMessage === "") root.errorMessage = "Could not load usage"
    }
  }

  Timer {
    interval: root.refreshMinutes * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    interval: 60 * 1000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(usageColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(key) { if (key === "r") root.refresh() }

      Column {
        id: usageColumn
        width: parent.width
        spacing: Style.space(14)

        PanelSectionHeader {
          text: "CLAUDE CODE USAGE"
          foreground: root.barForeground
        }

        MetricBar {
          width: parent.width
          visible: root.usage.session !== null
          icon: "󰅐"
          name: "Session"
          percent: root.usage.session ? root.usage.session.percent : 0
          detail: Model.limitDetail(root.usage.session, root.nowMs)
        }

        MetricBar {
          width: parent.width
          visible: root.usage.weekly !== null
          icon: "󰃰"
          name: "Weekly"
          percent: root.usage.weekly ? root.usage.weekly.percent : 0
          detail: Model.limitDetail(root.usage.weekly, root.nowMs)
        }

        MetricBar {
          width: parent.width
          visible: root.usage.weeklyOpus !== null
          icon: "󰃰"
          name: "Weekly Opus"
          percent: root.usage.weeklyOpus ? root.usage.weeklyOpus.percent : 0
          detail: Model.limitDetail(root.usage.weeklyOpus, root.nowMs)
        }

        Text {
          width: parent.width
          visible: root.errorMessage !== "" || (!root.hasUsage && root.loading)
          text: root.errorMessage !== "" ? root.errorMessage : "Loading usage..."
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.errorMessage !== "" ? Colors.urgent : Qt.darker(root.barForeground, 1.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}

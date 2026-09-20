import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property int monthOffset: 0
  property string monthName: ""
  property string monthGrid: ""
  property bool polling: false

  implicitHeight: layout.implicitHeight

  function loadMonth() {
    if (monthProbe.running) return
    monthProbe.running = true
  }

  function shiftMonth(delta) {
    root.monthOffset += delta
    root.loadMonth()
  }

  function resetMonth() {
    root.monthOffset = 0
    root.loadMonth()
  }

  Process {
    id: monthProbe
    command: ["bash", "-c",
      'first="$(date +%Y-%m-01) ' + root.monthOffset + ' months"; ' +
      'date -d "$first" "+%B %Y"; cal $(date -d "$first" "+%m %Y") | sed "1d"']
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = String(text).replace(/\s+$/, "").split("\n")
        root.monthName = (lines[0] || "").trim()
        root.monthGrid = lines.slice(1).join("\n")
      }
    }
  }

  Timer {
    interval: 3600000
    running: root.polling
    repeat: true
    onTriggered: if (root.monthOffset === 0) root.loadMonth()
  }

  Component.onCompleted: root.loadMonth()

  WheelHandler {
    onWheel: function(event) {
      root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
    }
  }

  Column {
    id: layout
    width: parent.width
    spacing: Style.spaceReal(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(monthLabel.implicitHeight, navigation.implicitHeight)

      Text {
        id: monthLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.monthName
        textFormat: Text.PlainText
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Row {
        id: navigation
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spaceReal(4)

        CardIconButton {
          icon: "<"
          onActivated: root.shiftMonth(-1)
        }

        CardIconButton {
          icon: "Today"
          visible: root.monthOffset !== 0
          implicitWidth: Style.spaceReal(44)
          onActivated: root.resetMonth()
        }

        CardIconButton {
          icon: ">"
          onActivated: root.shiftMonth(1)
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.monthGrid
      textFormat: Text.PlainText
      color: Util.alpha(Color.foreground, 0.85)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }
}

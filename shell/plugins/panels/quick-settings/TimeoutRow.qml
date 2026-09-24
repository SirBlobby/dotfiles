import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string icon: ""
  property string label: ""
  property int seconds: 0
  property var presetMinutes: []

  signal secondsRequested(int seconds)

  implicitHeight: Math.max(labelText.implicitHeight, controls.implicitHeight)

  function formatSeconds(value) {
    if (value >= 3600 && value % 3600 === 0) return (value / 3600) + " h"
    if (value % 60 === 0) return (value / 60) + " min"
    return (Math.round(value / 6) / 10) + " min"
  }

  function step(delta) {
    var minutes = root.seconds / 60
    var presets = root.presetMinutes
    var next = -1
    if (delta > 0) {
      for (var i = 0; i < presets.length; i++)
        if (presets[i] > minutes) { next = presets[i]; break }
    } else {
      for (var j = presets.length - 1; j >= 0; j--)
        if (presets[j] < minutes) { next = presets[j]; break }
    }
    if (next > 0) root.secondsRequested(next * 60)
  }

  Text {
    id: iconText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(22)
    text: root.icon
    textFormat: Text.PlainText
    color: Color.magenta
    font.family: Style.font.family
    font.pixelSize: Style.font.body
  }

  Text {
    id: labelText
    anchors.left: iconText.right
    anchors.leftMargin: Style.spaceReal(10)
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    textFormat: Text.PlainText
    color: Color.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Row {
    id: controls
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(8)

    CardIconButton {
      icon: "-"
      onActivated: root.step(-1)
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Style.spaceReal(52)
      horizontalAlignment: Text.AlignHCenter
      text: root.formatSeconds(root.seconds)
      textFormat: Text.PlainText
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }

    CardIconButton {
      icon: "+"
      onActivated: root.step(1)
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Card {
  id: root

  property string place: "Loading..."
  property string glyph: ""
  property string temperature: ""
  property string wind: ""
  property bool available: false

  implicitWidth: Style.spaceReal(190)

  CardHeader {
    icon: root.available ? root.glyph : ""
    title: root.place
  }

  Text {
    visible: !root.available
    text: "Weather unavailable"
    textFormat: Text.PlainText
    color: Util.alpha(Color.foreground, 0.7)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  StatRow {
    width: parent.width
    visible: root.available
    icon: "\uf2c9"
    label: "Temperature"
    value: root.temperature
  }

  StatRow {
    width: parent.width
    visible: root.available
    icon: "\udb81\udd9d"
    label: "Wind"
    value: root.wind
  }
}

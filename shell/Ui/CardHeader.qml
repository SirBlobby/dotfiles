import QtQuick
import qs.Commons

Row {
  id: root

  property string icon: ""
  property string title: ""

  spacing: Style.spaceReal(10)

  Rectangle {
    width: Style.spaceReal(28)
    height: width
    radius: Style.cardRadius
    color: Util.alpha(Colors.blue, 0.2)
    anchors.verticalCenter: parent.verticalCenter

    Text {
      anchors.centerIn: parent
      text: root.icon
      textFormat: Text.PlainText
      color: Colors.blue
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.title
    textFormat: Text.PlainText
    color: Colors.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }
}

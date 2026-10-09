import QtQuick
import qs.Commons

Item {
  id: root

  property string icon: ""
  property string label: ""
  property string value: ""

  implicitHeight: Math.max(iconText.implicitHeight, labelText.implicitHeight)

  Text {
    id: iconText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(22)
    text: root.icon
    textFormat: Text.PlainText
    color: Colors.magenta
    font.family: Style.font.family
    font.pixelSize: Style.font.body
  }

  Text {
    id: labelText
    anchors.left: iconText.right
    anchors.leftMargin: Style.spaceReal(8)
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    textFormat: Text.PlainText
    color: Colors.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Text {
    anchors.left: labelText.right
    anchors.leftMargin: Style.spaceReal(8)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
    text: root.value
    textFormat: Text.PlainText
    color: Colors.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    font.bold: true
  }
}

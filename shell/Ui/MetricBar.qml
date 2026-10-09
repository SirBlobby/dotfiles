import QtQuick
import qs.Commons

Column {
  id: root

  property string icon: ""
  property string name: ""
  property int percent: 0
  property string detail: ""

  spacing: Style.spaceReal(4)

  Item {
    width: parent.width
    implicitHeight: nameText.implicitHeight

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
      id: nameText
      anchors.left: iconText.right
      anchors.leftMargin: Style.spaceReal(8)
      anchors.verticalCenter: parent.verticalCenter
      text: root.name
      textFormat: Text.PlainText
      color: Colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.detail
      textFormat: Text.PlainText
      color: Util.alpha(Colors.foreground, 0.8)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  Rectangle {
    width: parent.width
    height: Style.spaceReal(8)
    radius: Style.cardRadius
    color: Util.alpha(Colors.foreground, 0.2)

    Rectangle {
      width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
      height: parent.height
      radius: Style.cardRadius
      color: Colors.accent

      Behavior on width {
        NumberAnimation { duration: 200 }
      }
    }
  }
}

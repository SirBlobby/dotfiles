import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false
  property string tooltip: ""
  signal activated()

  implicitWidth: Style.spaceReal(96)
  implicitHeight: Style.spaceReal(58)
  radius: Style.cardRadius
  color: root.active
    ? Color.accent
    : (hover.hovered ? Util.alpha(Color.blue, 0.3) : Util.alpha(Color.foreground, 0.1))
  border.width: 1
  border.color: root.active ? Color.accent : Util.alpha(Color.foreground, 0.2)

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  readonly property color contentColor: root.active ? Color.background : Color.foreground

  Column {
    anchors.centerIn: parent
    spacing: Style.spaceReal(4)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.icon
      textFormat: Text.PlainText
      color: root.contentColor
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      textFormat: Text.PlainText
      color: root.contentColor
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  HoverHandler {
    id: hover
  }

  TapHandler {
    onTapped: root.activated()
  }
}

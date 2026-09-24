import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string icon: ""
  property bool active: false
  signal activated()

  implicitWidth: Style.spaceReal(26)
  implicitHeight: Style.spaceReal(24)
  radius: Style.cardRadius
  color: root.active
    ? Color.accent
    : (hover.hovered ? Util.alpha(Color.blue, 0.3) : Util.alpha(Color.foreground, 0.1))

  Text {
    anchors.centerIn: parent
    text: root.icon
    textFormat: Text.PlainText
    color: root.active ? Color.background : (hover.hovered ? Color.blue : Color.magenta)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  HoverHandler {
    id: hover
  }

  TapHandler {
    onTapped: root.activated()
  }
}

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
    ? Colors.accent
    : (hover.hovered ? Util.alpha(Colors.blue, 0.3) : Util.alpha(Colors.foreground, 0.1))

  Text {
    anchors.centerIn: parent
    text: root.icon
    textFormat: Text.PlainText
    color: root.active ? Colors.background : (hover.hovered ? Colors.blue : Colors.magenta)
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

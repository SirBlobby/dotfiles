import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property bool active: false
  signal activated()

  implicitWidth: text.implicitWidth + Style.spaceReal(16)
  implicitHeight: Style.spaceReal(22)
  radius: Style.cardRadius
  opacity: enabled ? 1 : 0.4
  color: root.active
    ? Colors.accent
    : (hover.hovered ? Util.alpha(Colors.blue, 0.25) : Util.alpha(Colors.background, Style.cardFillAlpha))
  border.width: 1
  border.color: root.active ? Colors.accent : Util.alpha(Colors.blue, Style.cardBorderAlpha)

  Text {
    id: text
    anchors.centerIn: parent
    text: root.label
    textFormat: Text.PlainText
    color: root.active ? Colors.background : Colors.foreground
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

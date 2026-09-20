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
    ? Color.accent
    : (hover.hovered ? Util.alpha(Color.blue, 0.25) : Util.alpha(Color.background, Style.cardFillAlpha))
  border.width: 1
  border.color: root.active ? Color.accent : Util.alpha(Color.blue, Style.cardBorderAlpha)

  Text {
    id: text
    anchors.centerIn: parent
    text: root.label
    textFormat: Text.PlainText
    color: root.active ? Color.background : Color.foreground
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

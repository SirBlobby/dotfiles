import QtQuick
import qs.Commons

Rectangle {
  id: root

  property var monitor: null
  property bool selected: false
  property real canvasScale: 1
  property real originX: 0
  property real originY: 0

  signal picked()
  signal moved(int x, int y)
  signal dropped()

  readonly property string name: monitor ? monitor.name : ""
  readonly property bool disabled: monitor ? monitor.disabled === true : false

  visible: !!monitor && !disabled
  width: monitor ? Math.max(Style.spaceReal(24), monitor.width * canvasScale) : 0
  height: monitor ? Math.max(Style.spaceReal(18), monitor.height * canvasScale) : 0
  x: monitor ? (monitor.x - originX) * canvasScale : 0
  y: monitor ? (monitor.y - originY) * canvasScale : 0

  radius: Style.cardRadius
  color: root.selected
    ? Util.alpha(Color.accent, 0.35)
    : Util.alpha(Color.background, Style.cardFillAlpha)
  border.width: Style.cardBorderWidth
  border.color: root.selected ? Color.accent : Util.alpha(Color.blue, Style.cardBorderAlpha)

  Column {
    anchors.centerIn: parent
    spacing: Style.spaceReal(2)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.name
      textFormat: Text.PlainText
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.height > Style.spaceReal(44)
      text: root.monitor ? root.monitor.width + "x" + root.monitor.height : ""
      textFormat: Text.PlainText
      color: Util.alpha(Color.foreground, 0.7)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.monitor && root.monitor.focused && root.height > Style.spaceReal(58)
      text: "focused"
      textFormat: Text.PlainText
      color: Color.blue
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  TapHandler {
    onTapped: root.picked()
  }

  property int dragOriginX: 0
  property int dragOriginY: 0

  DragHandler {
    id: drag
    target: null
    onActiveChanged: {
      if (active) {
        root.picked()
        root.dragOriginX = root.monitor ? root.monitor.x : 0
        root.dragOriginY = root.monitor ? root.monitor.y : 0
        return
      }
      root.dropped()
    }
    onTranslationChanged: {
      if (!active || !root.monitor) return
      root.moved(
        Math.round(root.dragOriginX + translation.x / root.canvasScale),
        Math.round(root.dragOriginY + translation.y / root.canvasScale))
    }
  }
}

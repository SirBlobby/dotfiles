import QtQuick
import qs.Commons
import "DisplayModel.js" as DisplayModel

Rectangle {
  id: root

  property var monitors: []
  property string selectedName: ""
  readonly property int snapThreshold: 60

  signal selected(string name)
  signal monitorMoved(string name, int x, int y)
  signal layoutSettled()

  readonly property var bounds: DisplayModel.layoutBounds(root.monitors)
  readonly property real fitScale: DisplayModel.canvasScale(
    bounds,
    Math.max(1, width - Style.spaceReal(24)),
    Math.max(1, height - Style.spaceReal(24)))

  color: Util.alpha(Color.background, 0.35)
  radius: Style.cardRadius
  border.width: 1
  border.color: Util.alpha(Color.foreground, 0.15)
  clip: true

  Item {
    id: stage
    width: root.bounds.width * root.fitScale
    height: root.bounds.height * root.fitScale
    anchors.centerIn: parent

    Repeater {
      model: root.monitors

      MonitorCard {
        required property var modelData
        monitor: modelData
        canvasScale: root.fitScale
        originX: root.bounds.x
        originY: root.bounds.y
        selected: modelData.name === root.selectedName
        onPicked: root.selected(modelData.name)
        onMoved: function(x, y) { root.monitorMoved(modelData.name, x, y) }
        onDropped: root.layoutSettled()
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.monitors.length === 0
    text: "No monitors reported"
    textFormat: Text.PlainText
    color: Util.alpha(Color.foreground, 0.6)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}

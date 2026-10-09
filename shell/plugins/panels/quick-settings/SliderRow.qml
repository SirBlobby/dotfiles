import QtQuick
import qs.Commons

Item {
  id: root

  property string icon: ""
  property int value: 0
  property bool dimmed: false
  signal iconActivated()
  signal valueRequested(int value)

  implicitHeight: Style.spaceReal(24)

  Text {
    id: iconText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(22)
    text: root.icon
    textFormat: Text.PlainText
    color: root.dimmed ? Util.alpha(Colors.magenta, 0.5) : Colors.magenta
    font.family: Style.font.family
    font.pixelSize: Style.font.body

    TapHandler {
      onTapped: root.iconActivated()
    }
  }

  Rectangle {
    id: trough
    anchors.left: iconText.right
    anchors.leftMargin: Style.spaceReal(10)
    anchors.right: valueText.left
    anchors.rightMargin: Style.spaceReal(10)
    anchors.verticalCenter: parent.verticalCenter
    height: Style.spaceReal(8)
    radius: Style.cardRadius
    color: Util.alpha(Colors.foreground, 0.2)

    Rectangle {
      width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
      height: parent.height
      radius: Style.cardRadius
      color: Colors.accent
    }

    Rectangle {
      x: Math.max(0, Math.min(parent.width - width, parent.width * root.value / 100 - width / 2))
      anchors.verticalCenter: parent.verticalCenter
      width: Style.spaceReal(14)
      height: width
      radius: Style.cardRadius
      color: Colors.foreground
    }

    TapHandler {
      onTapped: function(point) {
        root.valueRequested(Math.round(point.position.x / trough.width * 100))
      }
    }

    DragHandler {
      target: null
      onCentroidChanged: {
        if (!active) return
        root.valueRequested(Math.round(centroid.position.x / trough.width * 100))
      }
    }
  }

  Text {
    id: valueText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(34)
    horizontalAlignment: Text.AlignRight
    text: root.value + "%"
    textFormat: Text.PlainText
    color: Colors.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}

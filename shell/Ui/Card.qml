import QtQuick
import qs.Commons

Rectangle {
  id: root

  property color fillColor: Util.alpha(Color.background, Style.cardFillAlpha)
  property color borderColor: Util.alpha(Color.blue, Style.cardBorderAlpha)
  default property alias content: contentColumn.data
  property alias spacing: contentColumn.spacing
  property int padding: Style.cardPadding

  color: fillColor
  radius: Style.cardRadius
  border.width: Style.cardBorderWidth
  border.color: borderColor
  implicitWidth: contentColumn.implicitWidth + padding * 2
  implicitHeight: contentColumn.implicitHeight + padding * 2

  Column {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: Style.cardSpacing
  }
}

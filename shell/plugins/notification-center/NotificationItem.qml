import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string app: ""
  property string summary: ""
  property string body: ""
  signal dismissRequested()

  radius: Style.cardRadius
  color: Util.alpha(Color.background, Style.cardFillAlpha)
  implicitHeight: layout.implicitHeight + Style.spaceReal(20)

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Style.spaceReal(3)
    color: Color.accent
  }

  Column {
    id: layout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: Style.spaceReal(12)
    anchors.rightMargin: Style.spaceReal(12)
    anchors.topMargin: Style.spaceReal(10)
    spacing: Style.spaceReal(2)

    Item {
      width: parent.width
      implicitHeight: appText.implicitHeight

      Text {
        id: appText
        anchors.left: parent.left
        text: root.app.length > 0 ? root.app : "Notification"
        textFormat: Text.PlainText
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }

      Text {
        anchors.right: parent.right
        text: "\uf00d"
        textFormat: Text.PlainText
        color: closeHover.hovered ? Color.urgent : Color.magenta
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall

        HoverHandler {
          id: closeHover
        }

        TapHandler {
          onTapped: root.dismissRequested()
        }
      }
    }

    Text {
      width: parent.width
      text: root.summary
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Text {
      width: parent.width
      visible: root.body.length > 0
      text: root.body
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      maximumLineCount: 4
      elide: Text.ElideRight
      color: Util.alpha(Color.foreground, 0.8)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }
}

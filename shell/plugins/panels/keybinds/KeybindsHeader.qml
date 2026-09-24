import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  signal addRequested()
  signal closeRequested()

  implicitHeight: Math.max(title.implicitHeight, buttons.implicitHeight)

  Text {
    id: title
    anchors.left: parent.left
    anchors.right: buttons.left
    anchors.rightMargin: Style.spaceReal(8)
    anchors.verticalCenter: parent.verticalCenter
    text: "Keybindings"
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Color.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }

  Row {
    id: buttons
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(4)

    CardIconButton {
      icon: ""
      onActivated: root.addRequested()
    }

    CardIconButton {
      icon: ""
      onActivated: root.closeRequested()
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string clock: ""
  property string today: ""
  signal lockRequested()
  signal logoutRequested()
  signal closeRequested()

  implicitHeight: Math.max(dateTime.implicitHeight, buttons.implicitHeight)

  Column {
    id: dateTime
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(2)

    Text {
      text: root.clock
      textFormat: Text.PlainText
      color: Colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
    }

    Text {
      text: root.today
      textFormat: Text.PlainText
      color: Util.alpha(Colors.foreground, 0.75)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  Row {
    id: buttons
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(4)

    CardIconButton {
      icon: "\uf023"
      onActivated: root.lockRequested()
    }

    CardIconButton {
      icon: "\uf08b"
      onActivated: root.logoutRequested()
    }

    CardIconButton {
      icon: ""
      onActivated: root.closeRequested()
    }
  }
}

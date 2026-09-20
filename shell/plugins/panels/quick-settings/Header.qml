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
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
    }

    Text {
      text: root.today
      textFormat: Text.PlainText
      color: Util.alpha(Color.foreground, 0.75)
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
      icon: ""
      onActivated: root.lockRequested()
    }

    CardIconButton {
      icon: ""
      onActivated: root.logoutRequested()
    }

    CardIconButton {
      icon: ""
      onActivated: root.closeRequested()
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string title: ""
  property string artist: ""
  property string status: "Stopped"
  readonly property bool playing: root.status === "Playing"
  signal controlRequested(string action)

  visible: root.title.length > 0 && root.title !== "No Media"
  implicitHeight: visible ? Math.max(info.implicitHeight, controls.implicitHeight) : 0

  Column {
    id: info
    anchors.left: parent.left
    anchors.right: controls.left
    anchors.rightMargin: Style.spaceReal(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(2)

    Text {
      width: parent.width
      text: root.title
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.artist
      textFormat: Text.PlainText
      elide: Text.ElideRight
      visible: root.artist.length > 0
      color: Util.alpha(Color.foreground, 0.75)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  Row {
    id: controls
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(8)

    CardIconButton {
      icon: "⏮"
      onActivated: root.controlRequested("previous")
    }

    CardIconButton {
      icon: root.playing ? "⏸" : "▶"
      onActivated: root.controlRequested("play-pause")
    }

    CardIconButton {
      icon: "⏭"
      onActivated: root.controlRequested("next")
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string title: ""
  property string artist: ""
  property string status: "Stopped"
  property string artUrl: ""
  readonly property bool playing: root.status === "Playing"
  readonly property bool hasArt: root.artUrl.length > 0 && thumbnailImage.status !== Image.Error
  signal controlRequested(string action)

  visible: root.title.length > 0 && root.title !== "No Media"
  implicitHeight: visible ? Math.max(thumbnail.height, info.implicitHeight, controls.implicitHeight) : 0

  Rectangle {
    id: thumbnail
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(48)
    height: width
    radius: Style.cardRadius
    color: Util.alpha(Color.background, Style.cardFillAlpha)
    border.width: Style.cardBorderWidth
    border.color: Util.alpha(Color.blue, Style.cardBorderAlpha)
    clip: true

    Image {
      id: thumbnailImage
      anchors.fill: parent
      anchors.margins: Style.cardBorderWidth
      source: root.artUrl
      visible: root.hasArt
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      sourceSize.width: Math.round(parent.width * 2)
      sourceSize.height: Math.round(parent.height * 2)
    }

    Text {
      anchors.centerIn: parent
      visible: !root.hasArt || thumbnailImage.status !== Image.Ready
      text: ""
      color: Util.alpha(Color.foreground, 0.6)
      font.family: Style.font.family
      font.pixelSize: Style.font.title
    }
  }

  Column {
    id: info
    anchors.left: thumbnail.right
    anchors.leftMargin: Style.spaceReal(12)
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
      icon: "\uf048"
      onActivated: root.controlRequested("previous")
    }

    CardIconButton {
      icon: root.playing ? "\uf04c" : "\uf04b"
      onActivated: root.controlRequested("play-pause")
    }

    CardIconButton {
      icon: "\uf051"
      onActivated: root.controlRequested("next")
    }
  }
}

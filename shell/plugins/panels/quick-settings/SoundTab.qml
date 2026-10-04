import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property int outputVolume: 0
  property bool outputMuted: false
  property int inputVolume: 0
  property bool inputMuted: false
  property var mediaParts: []

  signal commandRequested(string command)
  signal outputVolumeRequested(int value)
  signal inputVolumeRequested(int value)
  signal mediaControlRequested(string action)
  signal panelRequested(string pluginId)
  signal appRequested(string command)

  spacing: Style.spaceReal(12)

  SliderRow {
    width: parent.width
    icon: root.outputMuted ? "" : ""
    dimmed: root.outputMuted
    value: root.outputVolume
    onIconActivated: root.commandRequested("pamixer --toggle-mute")
    onValueRequested: function(next) { root.outputVolumeRequested(next) }
  }

  SliderRow {
    width: parent.width
    icon: root.inputMuted ? "" : ""
    dimmed: root.inputMuted
    value: root.inputVolume
    onIconActivated: root.commandRequested("pamixer --default-source --toggle-mute")
    onValueRequested: function(next) { root.inputVolumeRequested(next) }
  }

  MediaRow {
    id: mediaRow
    width: parent.width
    title: root.mediaParts.length > 0 ? root.mediaParts[0] : ""
    artist: root.mediaParts.length > 1 ? root.mediaParts[1] : ""
    status: root.mediaParts.length > 2 ? root.mediaParts[2] : "Stopped"
    artUrl: root.mediaParts.length > 3 ? root.mediaParts[3] : ""
    onControlRequested: function(action) { root.mediaControlRequested(action) }
  }

  Text {
    width: parent.width
    visible: !mediaRow.visible
    horizontalAlignment: Text.AlignHCenter
    text: "Nothing playing"
    textFormat: Text.PlainText
    color: Util.alpha(Color.foreground, 0.6)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Row {
    width: parent.width
    spacing: Style.spaceReal(6)

    Button {
      width: (parent.width - parent.spacing) / 2
      text: "Audio devices"
      iconText: ""
      bordered: true
      fontSize: Style.font.bodySmall
      onClicked: root.panelRequested("blob.audio")
    }

    Button {
      width: (parent.width - parent.spacing) / 2
      text: "Mixer"
      iconText: ""
      bordered: true
      fontSize: Style.font.bodySmall
      onClicked: root.appRequested("pavucontrol")
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: root

  property var binding: null

  signal editRequested()
  signal resetRequested()
  signal disableRequested()

  readonly property bool personal: binding ? binding.origin === "personal" : false
  readonly property bool active: binding ? binding.state === "active" : false
  readonly property string stateText: {
    if (!binding) return ""
    if (binding.state === "overridden") return "Replaced by your binding"
    if (binding.state === "disabled") return "Disabled"
    return binding.kind === "exec" ? binding.action : "Hyprland: " + binding.action
  }

  implicitHeight: Style.spaceReal(46)
  radius: Style.cardRadius
  color: hover.hovered ? Util.alpha(Colors.foreground, 0.08) : Util.alpha(Colors.background, Style.cardFillAlpha)

  HoverHandler {
    id: hover
  }

  Rectangle {
    id: keysChip
    anchors.left: parent.left
    anchors.leftMargin: Style.spaceReal(8)
    anchors.verticalCenter: parent.verticalCenter
    width: Style.spaceReal(200)
    height: Style.spaceReal(26)
    radius: Style.cardRadius
    color: root.personal ? Util.alpha(Colors.accent, 0.25) : Util.alpha(Colors.foreground, 0.1)
    border.width: 1
    border.color: root.personal ? Colors.accent : Util.alpha(Colors.foreground, 0.2)
    opacity: root.active ? 1 : 0.5

    Text {
      anchors.fill: parent
      anchors.leftMargin: Style.spaceReal(8)
      anchors.rightMargin: Style.spaceReal(8)
      verticalAlignment: Text.AlignVCenter
      text: root.binding ? root.binding.keys : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }
  }

  Column {
    anchors.left: keysChip.right
    anchors.leftMargin: Style.spaceReal(12)
    anchors.right: buttons.left
    anchors.rightMargin: Style.spaceReal(8)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(2)
    opacity: root.active ? 1 : 0.6

    Text {
      width: parent.width
      text: root.binding ? root.binding.description : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.stateText
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: root.active ? Util.alpha(Colors.foreground, 0.6) : Colors.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  Row {
    id: buttons
    anchors.right: parent.right
    anchors.rightMargin: Style.spaceReal(8)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceReal(4)

    CardIconButton {
      visible: root.active
      icon: ""
      onActivated: root.editRequested()
    }

    CardIconButton {
      visible: root.personal
      icon: ""
      onActivated: root.resetRequested()
    }

    CardIconButton {
      visible: !root.personal && root.active
      icon: ""
      onActivated: root.disableRequested()
    }

    CardIconButton {
      visible: !root.personal && !root.active
      icon: ""
      onActivated: root.resetRequested()
    }
  }
}

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  readonly property string iconPath: Quickshell.env("HOME") + "/.config/omarchy/branding/blob_icon.svg"
  readonly property int iconSize: Math.round(Style.font.body * 1.35)

  property string iconSvg: ""

  readonly property string iconColor: hexColor(button.foreground)
  readonly property string tintedSvg: iconSvg.replace(/fill="#000000"/g, 'fill="' + iconColor + '"')
  readonly property string iconUrl: iconSvg.length > 0 ? "data:image/svg+xml;base64," + Qt.btoa(tintedSvg) : ""
  readonly property bool iconReady: icon.status === Image.Ready

  function hexColor(value) {
    function channel(fraction) {
      return ("0" + Math.round(fraction * 255).toString(16)).slice(-2)
    }
    return "#" + channel(value.r) + channel(value.g) + channel(value.b)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    path: root.iconPath
    watchChanges: true
    printErrors: false
    onLoaded: root.iconSvg = text()
    onLoadFailed: root.iconSvg = ""
    onFileChanged: reload()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omarchy"
    labelVisible: !root.iconReady
    fixedWidth: root.iconReady ? root.iconSize + Style.spaceReal(15) : -1
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }

    Image {
      id: icon
      anchors.centerIn: parent
      width: root.iconSize
      height: root.iconSize
      source: root.iconUrl
      sourceSize.width: root.iconSize * 2
      sourceSize.height: root.iconSize * 2
      smooth: true
      visible: root.iconReady
    }
  }
}

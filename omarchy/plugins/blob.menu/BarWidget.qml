import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  readonly property string iconPath: "file://" + Quickshell.env("HOME") + "/.config/omarchy/branding/blob_icon.svg"
  readonly property int iconSize: Math.round(Style.font.body * 1.35)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.iconSize + Style.spaceReal(15)
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }

    Image {
      id: iconMask
      source: root.iconPath
      visible: false
      smooth: true
      sourceSize.width: root.iconSize * 2
      sourceSize.height: root.iconSize * 2
    }

    Rectangle {
      anchors.centerIn: parent
      width: root.iconSize
      height: root.iconSize
      color: button.foreground
      visible: iconMask.status === Image.Ready
      layer.enabled: true
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: iconMask
      }

      Behavior on color {
        enabled: !root.bar || root.bar.foregroundAnimationEnabled
        ColorAnimation { duration: 160 }
      }
    }
  }
}

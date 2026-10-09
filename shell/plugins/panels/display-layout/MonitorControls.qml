import QtQuick
import qs.Commons
import qs.Ui
import "DisplayModel.js" as DisplayModel

Column {
  id: root

  property var monitor: null
  property var monitors: []

  signal scaleRequested(real scale)
  signal modeRequested(string mode)
  signal enabledRequested(bool enabled)
  signal mirrorRequested(string target)

  readonly property var scaleOptions: monitor ? DisplayModel.nearbyScales(monitor) : []

  spacing: Style.spaceReal(8)
  visible: !!monitor

  Text {
    width: parent.width
    text: root.monitor ? root.monitor.name : ""
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Colors.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }

  Text {
    width: parent.width
    text: root.monitor ? root.monitor.description : ""
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Util.alpha(Colors.foreground, 0.65)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  StatRow {
    width: parent.width
    icon: "\uf047"
    label: "Position"
    value: root.monitor ? root.monitor.x + ", " + root.monitor.y : ""
  }

  StatRow {
    width: parent.width
    icon: "\uf108"
    label: "Logical size"
    value: root.monitor ? root.monitor.width + "x" + root.monitor.height : ""
  }

  Text {
    text: "Mode"
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.75)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Flow {
    width: parent.width
    spacing: Style.spaceReal(4)

    Repeater {
      model: root.monitor ? root.monitor.modes : []

      Chip {
        required property var modelData
        label: String(modelData).replace("Hz", "")
        active: root.monitor && String(modelData).indexOf(root.monitor.mode) === 0
        onActivated: root.modeRequested(String(modelData).replace("Hz", ""))
      }
    }
  }

  Text {
    text: "Scale"
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.75)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Flow {
    width: parent.width
    spacing: Style.spaceReal(4)

    Repeater {
      model: root.scaleOptions

      Chip {
        required property var modelData
        label: String(modelData)
        active: root.monitor && Math.abs(root.monitor.scale - modelData) < 0.001
        onActivated: root.scaleRequested(Number(modelData))
      }
    }
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Only scales that land on whole pixels are offered. Hyprland steps in 1/120 and rejects the rest."
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.55)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Flow {
    width: parent.width
    spacing: Style.spaceReal(6)

    Chip {
      label: root.monitor && root.monitor.disabled ? "Enable" : "Disable"
      onActivated: root.enabledRequested(root.monitor ? root.monitor.disabled === true : true)
    }

    Chip {
      label: root.monitor && root.monitor.mirrorOf !== "none" ? "Unmirror" : "Mirror"
      active: root.monitor && root.monitor.mirrorOf !== "none"
      enabled: root.monitors.length > 1
      onActivated: {
        if (!root.monitor) return
        if (root.monitor.mirrorOf !== "none") {
          root.mirrorRequested("none")
          return
        }
        for (var i = 0; i < root.monitors.length; i++) {
          if (root.monitors[i].name !== root.monitor.name) {
            root.mirrorRequested(root.monitors[i].name)
            return
          }
        }
      }
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var tabs: []
  property string currentTab: ""
  signal tabRequested(string tabId)

  readonly property real widestTabWidth: {
    var widest = 0
    for (var index = 0; index < tabRepeater.count; index++) {
      var tab = tabRepeater.itemAt(index)
      if (tab) widest = Math.max(widest, tab.implicitWidth)
    }
    return widest
  }
  readonly property real requiredWidth: root.widestTabWidth * root.tabs.length
    + root.spacing * Math.max(0, root.tabs.length - 1)

  spacing: Style.spaceReal(6)

  Repeater {
    id: tabRepeater
    model: root.tabs

    Button {
      required property var modelData
      width: (root.width - root.spacing * (root.tabs.length - 1)) / root.tabs.length
      text: modelData.label
      iconText: modelData.icon
      selected: modelData.id === root.currentTab
      bordered: true
      fontSize: Style.font.bodySmall
      onClicked: root.tabRequested(modelData.id)
    }
  }
}

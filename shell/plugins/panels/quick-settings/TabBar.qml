import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var tabs: []
  property string currentTab: ""
  signal tabRequested(string tabId)

  spacing: Style.spaceReal(6)

  Repeater {
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

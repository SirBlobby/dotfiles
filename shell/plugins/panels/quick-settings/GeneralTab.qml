import QtQuick
import qs.Commons

Column {
  id: root

  property bool polling: false
  property int brightness: 0
  property int screensaverSeconds: 0
  property int lockSeconds: 0
  property bool stayAwake: false

  signal brightnessRequested(int value)
  signal timeoutRequested(string key, int seconds)

  spacing: Style.spaceReal(12)

  Calendar {
    width: parent.width
    polling: root.polling
  }

  SliderRow {
    width: parent.width
    icon: ""
    value: root.brightness
    onValueRequested: function(next) { root.brightnessRequested(next) }
  }

  TimeoutRow {
    width: parent.width
    icon: ""
    label: "Screensaver after"
    seconds: root.screensaverSeconds
    presetMinutes: [1, 2, 5, 10, 15, 30, 60]
    onSecondsRequested: function(seconds) { root.timeoutRequested("screensaver", seconds) }
  }

  TimeoutRow {
    width: parent.width
    icon: ""
    label: "Lock after"
    seconds: root.lockSeconds
    presetMinutes: [1, 2, 5, 10, 15, 30, 60, 120]
    onSecondsRequested: function(seconds) { root.timeoutRequested("lock", seconds) }
  }

  Text {
    width: parent.width
    visible: root.stayAwake
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    text: "Stay Awake is on, so neither starts until it is turned off."
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.6)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}

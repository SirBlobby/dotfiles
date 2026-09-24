import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool polling: false

  implicitHeight: calendar.implicitHeight

  function refreshToday() {
    var now = new Date()
    if (CalendarModel.keyForDate(now) === CalendarModel.keyForDate(calendar.today)) return
    var followToday = calendar.selectionIsToday
    calendar.today = now
    if (followToday) calendar.goToToday()
  }

  onPollingChanged: {
    if (!polling) return
    calendar.today = new Date()
    calendar.goToToday()
  }

  Timer {
    interval: 60000
    running: root.polling
    repeat: true
    onTriggered: root.refreshToday()
  }

  CalendarView {
    id: calendar
    width: parent.width
    foreground: Color.foreground
    fontFamily: Style.font.family
    cellSpacing: Style.space(2)
    cellWidth: Math.floor((width - cellSpacing * 6) / 7)
    cellHeight: Style.space(24)
  }
}

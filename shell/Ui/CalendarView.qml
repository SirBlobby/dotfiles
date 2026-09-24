import QtQuick
import qs.Commons
import "CalendarModel.js" as CalendarModel

Column {
  id: root

  property date today: new Date()
  property int weekStart: CalendarModel.normalizedWeekStart(null, Qt.locale().firstDayOfWeek)
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool showWeekNumbers: false
  property bool navigationAtBottom: false
  property string weekHeaderTooltip: ""

  property real cellWidth: Style.space(36)
  property real cellHeight: Style.space(28)
  property real cellSpacing: Style.space(2)
  property real weekColumnWidth: Style.space(32)
  property real gutterWidth: Style.space(14)

  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property int selectedYear: today.getFullYear()
  property int selectedMonth: today.getMonth()
  property int selectedDay: today.getDate()

  property bool pickingMonth: false
  property int pickerYear: viewYear
  property int pickerMonth: viewMonth

  readonly property string todayKey: CalendarModel.keyForDate(today)
  readonly property string selectedKey: CalendarModel.dateKey(selectedYear, selectedMonth, selectedDay)
  readonly property bool selectionIsToday: selectedKey === todayKey
  readonly property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()
  readonly property date viewDate: new Date(viewYear, viewMonth, 1)
  readonly property date selectedDate: new Date(selectedYear, selectedMonth, selectedDay)
  readonly property int selectedOffset: CalendarModel.daysBetween(
    today.getFullYear(), today.getMonth(), today.getDate(), selectedYear, selectedMonth, selectedDay)
  readonly property var labelLocale: Qt.locale("en_US")
  readonly property real gridWidth: body.width
  readonly property color mutedForeground: Qt.darker(foreground, 1.5)

  signal weekHeaderClicked()

  spacing: Style.space(8)

  function weekdayLabel(weekday) {
    return String(labelLocale.dayName(weekday, Locale.ShortFormat)).toUpperCase()
  }

  function monthLabel(month) {
    return String(labelLocale.monthName(month, Locale.ShortFormat)).toUpperCase()
  }

  function selectDay(year, month, day) {
    selectedYear = year
    selectedMonth = month
    selectedDay = day
    viewYear = year
    viewMonth = month
    pickingMonth = false
  }

  function goToToday() {
    selectDay(today.getFullYear(), today.getMonth(), today.getDate())
  }

  function moveMonth(delta) {
    var next = CalendarModel.stepMonth(viewYear, viewMonth, delta)
    selectDay(next.year, next.month, CalendarModel.clampDay(next.year, next.month, selectedDay))
  }

  function moveYear(delta) {
    if (pickingMonth) pickerYear += delta
    else moveMonth(delta * 12)
  }

  function moveSelection(days) {
    var next = CalendarModel.stepDay(selectedYear, selectedMonth, selectedDay, days)
    selectDay(next.year, next.month, next.day)
  }

  function movePickerCursor(months) {
    var next = CalendarModel.stepMonth(pickerYear, pickerMonth, months)
    pickerYear = next.year
    pickerMonth = next.month
  }

  function handleMove(dx, dy) {
    if (pickingMonth) movePickerCursor(dx + dy * 4)
    else moveSelection(dx + dy * 7)
  }

  function openPicker() {
    pickerYear = viewYear
    pickerMonth = viewMonth
    pickingMonth = true
  }

  function togglePicker() {
    if (pickingMonth) pickingMonth = false
    else openPicker()
  }

  function choosePickerMonth(year, month) {
    selectDay(year, month, CalendarModel.clampDay(year, month, selectedDay))
  }

  function activate() {
    if (pickingMonth) choosePickerMonth(pickerYear, pickerMonth)
    else goToToday()
  }

  function dismissPicker() {
    if (!pickingMonth) return false
    pickingMonth = false
    return true
  }

  function selectedSummary() {
    var format = selectedYear === today.getFullYear() ? "dddd, MMMM d" : "dddd, MMMM d, yyyy"
    return Qt.formatDate(selectedDate, format)
      + "  ·  Day " + CalendarModel.dayOfYear(selectedYear, selectedMonth, selectedDay)
      + "  ·  " + CalendarModel.relativeDayLabel(selectedOffset)
  }

  MonthNavigation {
    visible: !root.navigationAtBottom
  }

  Item {
    width: root.width
    height: body.height

    Item {
      id: body
      anchors.horizontalCenter: parent.horizontalCenter
      width: days.width
      height: days.height

      CalendarDays {
        id: days
        calendar: root
        visible: !root.pickingMonth
      }

      CalendarMonthPicker {
        anchors.fill: parent
        calendar: root
        visible: root.pickingMonth
      }

      WheelHandler {
        onWheel: function(event) {
          if (event.angleDelta.y === 0) return
          var step = event.angleDelta.y > 0 ? -1 : 1
          if (root.pickingMonth) root.pickerYear += step
          else root.moveMonth(step)
        }
      }
    }
  }

  Text {
    width: root.width
    horizontalAlignment: Text.AlignHCenter
    textFormat: Text.PlainText
    elide: Text.ElideRight
    text: root.selectedSummary()
    color: root.mutedForeground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  MonthNavigation {
    visible: root.navigationAtBottom
  }

  component MonthNavigation: Item {
    width: root.width
    height: visible ? navigationLabel.implicitHeight + Style.space(10) : 0

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: body.width
      height: parent.height

      Rectangle {
        anchors.centerIn: navigationLabel
        width: navigationLabel.width
        height: navigationLabel.implicitHeight + Style.space(6)
        radius: Style.cornerRadius
        color: navigationMouse.containsMouse ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"
      }

      Text {
        id: navigationLabel
        anchors.centerIn: parent
        width: Style.space(150)
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: root.pickingMonth
          ? String(root.pickerYear)
          : Qt.formatDate(root.viewDate, "MMMM yyyy").toUpperCase()
        color: navigationMouse.containsMouse
          ? Style.hoverStateColor(root.foreground, Color.accent)
          : Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.letterSpacing: 1
      }

      MouseArea {
        id: navigationMouse
        anchors.fill: navigationLabel
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePicker()

        PanelToolTip {
          visible: navigationMouse.containsMouse
          text: root.pickingMonth ? "Back to the days" : "Pick a month"
          fontFamily: root.fontFamily
        }
      }

      PanelActionButton {
        anchors.left: parent.left
        anchors.leftMargin: -Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰅁"
        tooltipText: root.pickingMonth ? "Previous year" : "Previous month"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.pickingMonth ? root.moveYear(-1) : root.moveMonth(-1)
      }

      PanelActionButton {
        anchors.right: parent.right
        anchors.rightMargin: -Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰅂"
        tooltipText: root.pickingMonth ? "Next year" : "Next month"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.pickingMonth ? root.moveYear(1) : root.moveMonth(1)
      }
    }
  }
}

.pragma library

var MS_PER_DAY = 86400000

var WEEKDAY_NAMES = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

function pad2(value) {
  var n = Number(value)
  return (n < 10 ? "0" : "") + n
}

function dateKey(year, month, day) {
  return year + "-" + pad2(Number(month) + 1) + "-" + pad2(day)
}

function keyForDate(date) {
  return dateKey(date.getFullYear(), date.getMonth(), date.getDate())
}

function coerceWeekStart(value) {
  if (value === undefined || value === null) return null
  if (typeof value === "number")
    return isFinite(value) ? ((Math.round(value) % 7) + 7) % 7 : null

  var text = String(value).replace(/^\s+|\s+$/g, "").toLowerCase()
  if (text === "") return null

  for (var i = 0; i < WEEKDAY_NAMES.length; i++)
    if (WEEKDAY_NAMES[i] === text || WEEKDAY_NAMES[i].substr(0, 3) === text) return i

  var parsed = parseInt(text, 10)
  return isFinite(parsed) ? ((parsed % 7) + 7) % 7 : null
}

function normalizedWeekStart(value, fallback) {
  var configured = coerceWeekStart(value)
  if (configured !== null) return configured
  var fallbackStart = coerceWeekStart(fallback)
  return fallbackStart === null ? 1 : fallbackStart
}

function weekStartSettingName(index) {
  return WEEKDAY_NAMES[normalizedWeekStart(index, 1)]
}

function toggledWeekStart(index) {
  return normalizedWeekStart(index, 1) === 1 ? 0 : 1
}

function weekdayOrder(weekStart) {
  var start = normalizedWeekStart(weekStart, 1)
  var order = []
  for (var i = 0; i < 7; i++) order.push((start + i) % 7)
  return order
}

function isoWeek(year, month, day) {
  var date = new Date(Date.UTC(year, month, day))
  var weekday = date.getUTCDay() || 7
  date.setUTCDate(date.getUTCDate() + 4 - weekday)
  var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil(((date.getTime() - yearStart.getTime()) / MS_PER_DAY + 1) / 7)
}

function isoWeekLiteral(year, month, day) {
  return pad2(isoWeek(year, month, day))
}

function dayOfYear(year, month, day) {
  return Math.round((Date.UTC(year, month, day) - Date.UTC(year, 0, 1)) / MS_PER_DAY) + 1
}

function daysInYear(year) {
  return dayOfYear(year, 11, 31)
}

function daysInMonth(year, month) {
  return new Date(year, Number(month) + 1, 0).getDate()
}

function yearProgress(year, month, day) {
  var total = daysInYear(year)
  if (total <= 0) return 0
  return Math.max(0, Math.min(1, (dayOfYear(year, month, day) - 1) / total))
}

function yearProgressPercent(year, month, day) {
  return Math.round(yearProgress(year, month, day) * 100)
}

function stepMonth(year, month, delta) {
  var target = new Date(year, Number(month) + Number(delta), 1)
  return { year: target.getFullYear(), month: target.getMonth() }
}

function stepDay(year, month, day, delta) {
  var target = new Date(year, month, Number(day) + Number(delta))
  return { year: target.getFullYear(), month: target.getMonth(), day: target.getDate() }
}

function clampDay(year, month, day) {
  return Math.max(1, Math.min(Number(day), daysInMonth(year, month)))
}

function daysBetween(fromYear, fromMonth, fromDay, toYear, toMonth, toDay) {
  return Math.round((Date.UTC(toYear, toMonth, toDay) - Date.UTC(fromYear, fromMonth, fromDay)) / MS_PER_DAY)
}

function relativeDayLabel(offset) {
  if (offset === 0) return "Today"
  if (offset === 1) return "Tomorrow"
  if (offset === -1) return "Yesterday"
  if (offset > 0) return "In " + offset + " days"
  return (-offset) + " days ago"
}

function monthGrid(year, month, weekStart, todayKey, selectedKey) {
  var start = normalizedWeekStart(weekStart, 1)
  var leading = (new Date(year, month, 1).getDay() - start + 7) % 7
  var cursor = new Date(year, month, 1 - leading)
  var today = String(todayKey || "")
  var selected = String(selectedKey || "")
  var weeks = []

  for (var row = 0; row < 6; row++) {
    var days = []
    var thursday = null
    for (var column = 0; column < 7; column++) {
      var cellYear = cursor.getFullYear()
      var cellMonth = cursor.getMonth()
      var cellDay = cursor.getDate()
      var weekday = cursor.getDay()
      var key = dateKey(cellYear, cellMonth, cellDay)
      if (weekday === 4) thursday = { year: cellYear, month: cellMonth, day: cellDay }
      days.push({
        key: key,
        year: cellYear,
        month: cellMonth,
        day: cellDay,
        weekday: weekday,
        inMonth: cellMonth === month && cellYear === year,
        weekend: weekday === 0 || weekday === 6,
        today: key === today,
        selected: key === selected
      })
      cursor.setDate(cursor.getDate() + 1)
    }
    var anchor = thursday || days[0]
    weeks.push({
      week: isoWeek(anchor.year, anchor.month, anchor.day),
      days: days
    })
  }
  return weeks
}

if (typeof module !== "undefined") {
  module.exports = {
    pad2: pad2,
    dateKey: dateKey,
    keyForDate: keyForDate,
    normalizedWeekStart: normalizedWeekStart,
    weekStartSettingName: weekStartSettingName,
    toggledWeekStart: toggledWeekStart,
    weekdayOrder: weekdayOrder,
    isoWeek: isoWeek,
    isoWeekLiteral: isoWeekLiteral,
    dayOfYear: dayOfYear,
    daysInYear: daysInYear,
    daysInMonth: daysInMonth,
    yearProgress: yearProgress,
    yearProgressPercent: yearProgressPercent,
    stepMonth: stepMonth,
    stepDay: stepDay,
    clampDay: clampDay,
    daysBetween: daysBetween,
    relativeDayLabel: relativeDayLabel,
    monthGrid: monthGrid
  }
}

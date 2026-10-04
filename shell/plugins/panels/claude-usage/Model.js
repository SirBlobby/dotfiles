function parseUsage(raw) {
  var values = {}
  var lines = String(raw || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    var tabIndex = lines[i].indexOf("\t")
    if (tabIndex === -1) continue
    values[lines[i].substring(0, tabIndex)] = lines[i].substring(tabIndex + 1).trim()
  }

  return {
    session: limitFrom(values, "session"),
    weekly: limitFrom(values, "weekly"),
    weeklyOpus: limitFrom(values, "weekly_opus")
  }
}

function limitFrom(values, name) {
  var percentText = values[name + "_percent"]
  if (percentText === undefined) return null

  var percent = parseInt(percentText, 10)
  return {
    percent: isNaN(percent) ? 0 : Math.max(0, Math.min(100, percent)),
    resetsAt: values[name + "_resets"] || ""
  }
}

function formatTimeUntil(resetsAt, nowMs) {
  if (!resetsAt) return ""

  var resetMs = new Date(resetsAt).getTime()
  if (isNaN(resetMs)) return ""

  var totalMinutes = Math.max(0, Math.round((resetMs - nowMs) / 60000))
  var days = Math.floor(totalMinutes / 1440)
  var hours = Math.floor((totalMinutes % 1440) / 60)
  var minutes = totalMinutes % 60

  if (days > 0) return days + "d " + hours + "h"
  if (hours > 0) return hours + "h " + minutes + "m"
  return minutes + "m"
}

function limitDetail(limit, nowMs) {
  if (!limit) return ""

  var timeUntilReset = formatTimeUntil(limit.resetsAt, nowMs)
  if (timeUntilReset === "") return limit.percent + "%"
  return limit.percent + "%  resets in " + timeUntilReset
}

if (typeof module !== "undefined") {
  module.exports = {
    parseUsage: parseUsage,
    formatTimeUntil: formatTimeUntil,
    limitDetail: limitDetail
  }
}

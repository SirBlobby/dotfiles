function numberValue(value) {
  var n = Number(value || 0)
  return isFinite(n) ? Math.round(n) : 0
}

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, value))
}

function formatTokenCount(count) {
  if (count === undefined || count === null) return "0"
  if (count >= 1e9) return (count / 1e9).toFixed(1) + "B"
  if (count >= 1e6) return (count / 1e6).toFixed(1) + "M"
  if (count >= 1e3) return (count / 1e3).toFixed(1) + "K"
  return String(count)
}

function modelWordCase(word) {
  if (word === "gpt") return "GPT"
  return word.charAt(0).toUpperCase() + word.slice(1)
}

function friendlyModelName(modelId) {
  if (!modelId) return "Unknown"
  var name = String(modelId).replace(/^claude-/, "").replace(/-\d{8}$/, "")
  var parts = name.split("-")
  var words = []
  var version = []
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i]
    if (part === "") continue
    if (/^\d/.test(part)) {
      version.push(part)
      continue
    }
    if (version.length > 0) {
      words.push(version.join("."))
      version = []
    }
    words.push(modelWordCase(part))
  }
  if (version.length > 0) words.push(version.join("."))
  return words.length > 0 ? words.join(" ") : "Unknown"
}

function dayName(date) {
  var parsed = new Date(String(date || "") + "T00:00:00")
  if (isNaN(parsed.getTime())) return String(date || "")
  return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][parsed.getDay()]
}

function formatDuration(milliseconds) {
  if (!(milliseconds > 0)) return "now"
  var minutes = Math.floor(milliseconds / 60000)
  var hours = Math.floor(minutes / 60)
  var days = Math.floor(hours / 24)
  if (days > 0) return days + "d " + (hours % 24) + "h"
  if (hours > 0) return hours + "h " + (minutes % 60) + "m"
  return Math.max(1, minutes) + "m"
}

function planLabel(record) {
  var tier = String(record && record.tierLabel || "")
  return tier === "" ? "" : tier.charAt(0).toUpperCase() + tier.slice(1)
}

function needsSignIn(record) {
  var status = String(record && record.usageStatusText || "")
  return status === "Sign-in expired" || status === "Waiting for sign-in"
}

function troubleText(record) {
  if (!record || String(record.usageStatusText || "") === "") return ""
  return String(record.authHelpText || record.usageStatusText)
}

function windowIsLong(text) {
  return text.indexOf("week") >= 0 || text.indexOf("7-day") >= 0 || text.indexOf("month") >= 0
}

function windowTitle(label) {
  var text = String(label || "").toLowerCase()
  if (text.indexOf("month") >= 0) return "Monthly"
  if (windowIsLong(text)) return "Weekly"
  if (text.indexOf("session") >= 0 || text.indexOf("hour") >= 0) return "Session"
  var plain = String(label || "").replace(/\s*\(.*\)\s*/, "").trim()
  return plain === "" ? "Limit" : plain
}

function limitWindows(record) {
  var windows = []
  var limits = record && record.limits ? record.limits : []
  for (var i = 0; i < limits.length; i++) {
    var entry = limits[i] || {}
    var percent = Number(entry.percent)
    if (!(percent >= 0)) continue
    windows.push({
      title: String(entry.title || "") !== "" ? String(entry.title) : windowTitle(entry.label),
      percent: percent,
      resetAt: String(entry.resetsAt || "")
    })
  }
  return windows
}

function scopedPart(title) {
  var match = String(title || "").match(/^(.+) (Session|Weekly|Monthly)$/)
  return match ? { model: match[1], window: match[2] } : null
}

function displayWindows(record) {
  var windows = limitWindows(record)
  var shown = []
  var byTitle = {}

  for (var i = 0; i < windows.length; i++) {
    if (scopedPart(windows[i].title)) continue
    windows[i].scoped = []
    shown.push(windows[i])
    byTitle[windows[i].title] = windows[i]
  }

  for (var j = 0; j < windows.length; j++) {
    var part = scopedPart(windows[j].title)
    if (!part) continue
    var base = byTitle[part.window]
    if (base) {
      base.scoped.push({ title: part.model, percent: windows[j].percent, resetAt: windows[j].resetAt })
    } else {
      windows[j].scoped = []
      shown.push(windows[j])
    }
  }
  return shown
}

function fullestWindow(record) {
  var windows = limitWindows(record)
  var fullest = null
  for (var i = 0; i < windows.length; i++) {
    if (!fullest || windows[i].percent > fullest.percent) fullest = windows[i]
  }
  return fullest
}

function resetMillisecondsFor(window, nowMs) {
  if (!window || window.resetAt === "") return -1
  var resetMs = new Date(window.resetAt).getTime()
  return isFinite(resetMs) ? resetMs - nowMs : -1
}

function limitTooltip(window, stale, fetchedAt, nowMs) {
  if (!window) return ""
  var lines = []
  var resetMs = resetMillisecondsFor(window, nowMs)
  lines.push(window.title + ": " + Math.round(window.percent * 100) + "% used"
    + (resetMs > 0 ? " · resets in " + formatDuration(resetMs) : ""))
  if (stale) {
    lines.push(fetchedAt > 0 && nowMs - fetchedAt > 60000
      ? "As of " + formatDuration(nowMs - fetchedAt) + " ago"
      : "Last known")
  }
  var scoped = window.scoped || []
  for (var i = 0; i < scoped.length; i++) {
    lines.push(scoped[i].title + ": " + Math.round(scoped[i].percent * 100) + "% of its "
      + window.title.toLowerCase() + " allowance")
  }
  return lines.join("\n")
}

function summaryPhrases(record) {
  if (!record) return []

  var weekTokens = 0
  var tokensByDay = {}
  var recentDays = record.recentDays || []
  for (var d = 0; d < recentDays.length; d++) {
    var dayTokens = Number(recentDays[d].messageCount || 0)
    weekTokens += dayTokens
    tokensByDay[recentDays[d].date] = (tokensByDay[recentDays[d].date] || 0) + dayTokens
  }

  var tokensByModel = {}
  var modelUsage = record.modelUsage || {}
  for (var modelId in modelUsage) {
    var bucket = modelUsage[modelId] || {}
    var total = Number(bucket.inputTokens || 0) + Number(bucket.outputTokens || 0)
      + Number(bucket.cacheReadInputTokens || 0) + Number(bucket.cacheCreationInputTokens || 0)
    var name = friendlyModelName(modelId)
    tokensByModel[name] = (tokensByModel[name] || 0) + total
  }

  var todayTokens = numberValue(record.todayTotalTokens)
  var todayPrompts = numberValue(record.todayPrompts)
  var todaySessions = numberValue(record.todaySessions)

  var phrases = []
  if (weekTokens > 0) phrases.push(formatTokenCount(weekTokens) + " tokens this week")
  if (todayTokens > 0) phrases.push(formatTokenCount(todayTokens) + " tokens today")

  var topModel = ""
  for (var model in tokensByModel) if (topModel === "" || tokensByModel[model] > tokensByModel[topModel]) topModel = model
  if (topModel !== "" && tokensByModel[topModel] > 0) phrases.push("Mostly " + topModel)

  var busiestDay = ""
  for (var date in tokensByDay) if (busiestDay === "" || tokensByDay[date] > tokensByDay[busiestDay]) busiestDay = date
  if (busiestDay !== "" && tokensByDay[busiestDay] > 0) phrases.push("Busiest day: " + dayName(busiestDay))

  if (todayPrompts > 0) phrases.push(todayPrompts + " prompt" + (todayPrompts === 1 ? "" : "s") + " today")
  if (todaySessions > 0) phrases.push(todaySessions + " session" + (todaySessions === 1 ? "" : "s") + " today")
  return phrases
}

if (typeof module !== "undefined") {
  module.exports = {
    numberValue: numberValue,
    clamp: clamp,
    formatTokenCount: formatTokenCount,
    friendlyModelName: friendlyModelName,
    dayName: dayName,
    formatDuration: formatDuration,
    planLabel: planLabel,
    needsSignIn: needsSignIn,
    troubleText: troubleText,
    windowTitle: windowTitle,
    limitWindows: limitWindows,
    displayWindows: displayWindows,
    fullestWindow: fullestWindow,
    resetMillisecondsFor: resetMillisecondsFor,
    limitTooltip: limitTooltip,
    summaryPhrases: summaryPhrases
  }
}

.pragma library

// Each history file is one line of JSON, so the reader concatenates the
// directory and parses line by line. Newest first, by timestamp.
function parseHistory(raw) {
  var lines = String(raw || "").split("\n")
  var entries = []
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    try {
      var value = JSON.parse(line)
      if (!value || typeof value !== "object") continue
      entries.push({
        id: value.id || 0,
        app: value.app || "",
        summary: value.summary || "",
        body: value.body || "",
        timestamp: Number(value.timestamp) || 0
      })
    } catch (e) {
      continue
    }
  }
  entries.sort(function(a, b) { return b.timestamp - a.timestamp })
  return entries
}

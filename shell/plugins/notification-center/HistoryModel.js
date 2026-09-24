.pragma library

// Each history file is one line of JSON, and the reader prefixes every line
// with the file's name and a tab so an entry can be removed later. Newest
// first, by timestamp.
function parseHistory(raw) {
  var lines = String(raw || "").split("\n")
  var entries = []
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    var tab = line.indexOf("\t")
    var fileName = tab >= 0 ? line.slice(0, tab) : ""
    var json = tab >= 0 ? line.slice(tab + 1) : line
    try {
      var value = JSON.parse(json)
      if (!value || typeof value !== "object") continue
      entries.push({
        id: value.id || 0,
        fileName: fileName,
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

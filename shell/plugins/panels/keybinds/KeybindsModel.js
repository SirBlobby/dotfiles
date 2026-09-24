.pragma library

var modifierNames = { SUPER: true, SHIFT: true, CTRL: true, CONTROL: true, ALT: true }

function canonicalKeys(keys) {
  var modifiers = []
  var key = ""
  var parts = String(keys || "").split("+")
  for (var i = 0; i < parts.length; i++) {
    var token = parts[i].trim().toUpperCase()
    if (token === "CONTROL") token = "CTRL"
    if (modifierNames[token]) modifiers.push(token)
    else if (token.length > 0) key = token
  }
  modifiers.sort()
  modifiers.push(key)
  return modifiers.join("+")
}

function parseBindings(raw) {
  var personal = []
  var defaults = []
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var fields = lines[i].split("\t")
    if (fields.length < 6) continue
    var binding = {
      origin: fields[0],
      state: fields[1],
      keys: fields[2],
      description: fields[3],
      kind: fields[4],
      action: fields[5],
      canonical: canonicalKeys(fields[2])
    }
    if (binding.origin === "personal") personal.push(binding)
    else defaults.push(binding)
  }
  return personal.concat(defaults)
}

function matchesFilter(binding, filterMode) {
  if (filterMode === "personal") return binding.origin === "personal"
  if (filterMode === "changed") return binding.state !== "active"
  return true
}

function matchesSearch(binding, query) {
  if (!query) return true
  return binding.keys.toLowerCase().indexOf(query) !== -1
    || binding.description.toLowerCase().indexOf(query) !== -1
    || binding.action.toLowerCase().indexOf(query) !== -1
}

function filterBindings(bindings, searchText, filterMode) {
  var query = String(searchText || "").trim().toLowerCase()
  var result = []
  for (var i = 0; i < bindings.length; i++) {
    if (matchesFilter(bindings[i], filterMode) && matchesSearch(bindings[i], query)) result.push(bindings[i])
  }
  return result
}

function conflictFor(bindings, keys, editingBinding) {
  var canonical = canonicalKeys(keys)
  if (canonical.charAt(canonical.length - 1) === "+" || canonical === "") return null
  for (var i = 0; i < bindings.length; i++) {
    var binding = bindings[i]
    if (binding.state !== "active" || binding.canonical !== canonical) continue
    if (editingBinding && editingBinding.origin === "personal" && editingBinding.canonical === canonical) continue
    return binding
  }
  return null
}

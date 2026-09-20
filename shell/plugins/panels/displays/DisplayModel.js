.pragma library

// hyprctl reports logical size as the raw mode divided by scale, so a 1920x1200
// panel at 1.5 occupies 1280x800 of layout space. Positions are in that same
// logical space, which is what the canvas has to draw.
function logicalSize(monitor) {
  var scale = Number(monitor.scale) || 1
  var width = Number(monitor.width) || 0
  var height = Number(monitor.height) || 0
  if (isRotated(monitor)) {
    var swap = width
    width = height
    height = swap
  }
  return {
    width: Math.round(width / scale),
    height: Math.round(height / scale)
  }
}

function isRotated(monitor) {
  var transform = Number(monitor.transform) || 0
  return transform === 1 || transform === 3 || transform === 5 || transform === 7
}

function parseMonitors(raw) {
  var parsed
  try {
    parsed = JSON.parse(String(raw || "[]"))
  } catch (e) {
    return []
  }
  if (!Array.isArray(parsed)) return []

  var monitors = []
  for (var i = 0; i < parsed.length; i++) {
    var m = parsed[i] || {}
    var size = logicalSize(m)
    monitors.push({
      name: String(m.name || ""),
      description: String(m.description || ""),
      mode: modeStringOf(m),
      modes: Array.isArray(m.availableModes) ? m.availableModes : [],
      x: Number(m.x) || 0,
      y: Number(m.y) || 0,
      width: size.width,
      height: size.height,
      scale: Number(m.scale) || 1,
      transform: Number(m.transform) || 0,
      disabled: m.disabled === true,
      focused: m.focused === true,
      mirrorOf: String(m.mirrorOf || "none")
    })
  }
  monitors.sort(function(a, b) { return a.x - b.x })
  return monitors
}

function modeStringOf(monitor) {
  var width = Number(monitor.width) || 0
  var height = Number(monitor.height) || 0
  var rate = Number(monitor.refreshRate) || 0
  if (!width || !height) return "preferred"
  return width + "x" + height + "@" + rate.toFixed(2)
}

// The canvas is a scaled-down picture of the desktop. Monitors can sit at
// negative coordinates, so the bounding box is translated to the origin before
// a single scale factor is chosen for both axes.
function layoutBounds(monitors) {
  if (!monitors.length) return { x: 0, y: 0, width: 1, height: 1 }
  var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (var i = 0; i < monitors.length; i++) {
    var m = monitors[i]
    if (m.disabled) continue
    minX = Math.min(minX, m.x)
    minY = Math.min(minY, m.y)
    maxX = Math.max(maxX, m.x + m.width)
    maxY = Math.max(maxY, m.y + m.height)
  }
  if (minX === Infinity) return { x: 0, y: 0, width: 1, height: 1 }
  return { x: minX, y: minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) }
}

function canvasScale(bounds, availableWidth, availableHeight) {
  return Math.min(availableWidth / bounds.width, availableHeight / bounds.height)
}

// Snap a dragged edge to a neighbour's edge when it lands within the threshold,
// so monitors end up touching exactly rather than a few pixels apart.
function snapPosition(monitors, name, x, y, threshold) {
  var snappedX = x
  var snappedY = y
  var self = null
  for (var i = 0; i < monitors.length; i++) {
    if (monitors[i].name === name) { self = monitors[i]; break }
  }
  if (!self) return { x: Math.round(x), y: Math.round(y) }

  for (var j = 0; j < monitors.length; j++) {
    var other = monitors[j]
    if (other.name === name || other.disabled) continue

    var candidatesX = [
      other.x + other.width,
      other.x - self.width,
      other.x
    ]
    for (var cx = 0; cx < candidatesX.length; cx++) {
      if (Math.abs(snappedX - candidatesX[cx]) <= threshold) {
        snappedX = candidatesX[cx]
        break
      }
    }

    var candidatesY = [
      other.y + other.height,
      other.y - self.height,
      other.y
    ]
    for (var cy = 0; cy < candidatesY.length; cy++) {
      if (Math.abs(snappedY - candidatesY[cy]) <= threshold) {
        snappedY = candidatesY[cy]
        break
      }
    }
  }
  return { x: Math.round(snappedX), y: Math.round(snappedY) }
}

// Hyprland's keyword form: monitor = name,mode,position,scale[,transform,N]
function monitorKeyword(monitor) {
  if (monitor.disabled) return monitor.name + ",disable"
  var parts = [
    monitor.name,
    monitor.mode,
    monitor.x + "x" + monitor.y,
    String(monitor.scale)
  ]
  var keyword = parts.join(",")
  if (monitor.transform && monitor.transform !== 0)
    keyword += ",transform," + monitor.transform
  if (monitor.mirrorOf && monitor.mirrorOf !== "none")
    keyword += ",mirror," + monitor.mirrorOf
  return keyword
}

function keywordsFor(monitors) {
  var out = []
  for (var i = 0; i < monitors.length; i++) out.push(monitorKeyword(monitors[i]))
  return out
}

// Hyprland rejects a fractional scale that does not land on a whole number of
// physical pixels. It steps in 1/120, so a scale is valid when both axes come
// out integral at that granularity.
function scaleIsValid(monitor, scale) {
  if (!scale || scale <= 0) return false
  var stepped = Math.round(scale * 120) / 120
  var width = Number(monitor.width) * Number(monitor.scale)
  var height = Number(monitor.height) * Number(monitor.scale)
  var logicalWidth = width / stepped
  var logicalHeight = height / stepped
  return Math.abs(logicalWidth - Math.round(logicalWidth)) < 0.001
    && Math.abs(logicalHeight - Math.round(logicalHeight)) < 0.001
}

function nearbyScales(monitor) {
  var options = []
  for (var step = 60; step <= 300; step += 6) {
    var candidate = step / 120
    if (scaleIsValid(monitor, candidate)) options.push(candidate)
  }
  if (!options.length) options.push(1)
  return options
}

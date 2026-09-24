o.bind("SUPER + SPACE", "Blob menu", "blob-menu toggle")
o.bind("SUPER + ALT + SPACE", "Apps menu", "blob-menu toggle apps")
o.bind("SUPER + CTRL + E", "Emojis", "blob-shell shell toggle blob.emojis")
o.bind("SUPER + CTRL + C", "Capture menu", "blob-menu toggle capture")
o.bind("SUPER + CTRL + O", "Toggle menu", "blob-menu toggle toggle")
o.bind("SUPER + CTRL + H", "Hardware menu", "blob-menu toggle hardware")
o.bind("SUPER + SHIFT + code:201", "Blob menu", "blob-menu toggle root")
o.bind("SUPER + ESCAPE", "System menu", "blob-menu toggle system")
o.bind("XF86PowerOff", "Power menu", "blob-menu toggle system", { locked = true })
o.bind("SUPER + K", "Keybindings", "blob-menu-keybindings")
o.bind("SUPER + SHIFT + K", "Manage keybindings", "blob-shell shell toggle blob.keybinds")

o.bind_toggle("SUPER + SHIFT + SPACE", "Toggle top bar", "bar")
o.bind("SUPER + CTRL + SPACE", "Background switcher", "blob-menu toggle background")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "blob-menu toggle theme")
o.bind("SUPER + BACKSPACE", "Toggle window transparency", "blob-hypr-window-transparency-toggle")
o.bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "blob-hypr-window-gaps-toggle")
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "blob-hypr-window-single-square-aspect-toggle")

-- xkbcommon names the comma keysym "comma"; the upper-case "COMMA" does not match.
o.bind("SUPER + comma", "Dismiss last notification", "blob-shell notifications dismissOne")
o.bind("SUPER + SHIFT + comma", "Dismiss all notifications", "blob-shell notifications dismissAll")
o.bind_toggle("SUPER + CTRL + comma", "Toggle silencing notifications", "notification-silencing")
o.bind("SUPER + ALT + comma", "Invoke last notification", "blob-shell notifications invokeLast")
o.bind("SUPER + SHIFT + ALT + comma", "Open notification history", "blob-shell notifications showHistory")

o.bind_toggle("SUPER + CTRL + I", "Toggle locking on idle", "idle")
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + CTRL + Delete", "Toggle laptop display", "blob-hypr-monitor-internal toggle")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "blob-hypr-monitor-mirror toggle")
o.bind("switch:on:Lid Switch", nil, "blob-system-lid", { locked = true })
o.bind("switch:off:Lid Switch", nil, "blob-hypr-monitor-clamshell", { locked = true })

o.bind("PRINT", "Screenshot", "blob-capture-screenshot")
o.bind("ALT + PRINT", "Screenrecording", "blob-capture-record --stop-recording || blob-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + ALT + code:34", "Make webcam overlay smaller", "blob-capture-webcam-resize smaller")
o.bind("SUPER + ALT + code:35", "Make webcam overlay larger", "blob-capture-webcam-resize larger")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "blob-capture-text")

-- Keyboard control for the slurp region picker (see blob-capture-region).
-- The binds live exactly as long as a selection layer is on screen (slurp
-- opens one per monitor), so they cannot leak or get stuck.
-- Unbinding by key would take a same-key binding out of the user's own config
-- with it, so each handle is kept and removed individually.
local selection_layers = 0
local selection_binds = {}

hl.on("layer.opened", function(layer)
  if layer.namespace == "selection" then
    selection_layers = selection_layers + 1
    if selection_layers == 1 then
      selection_binds = {
        hl.bind("RETURN", hl.dsp.exec_cmd("blob-capture-region --take-window"), { description = "Capture highlighted window" }),
        hl.bind("CTRL + RETURN", hl.dsp.exec_cmd("blob-capture-region --take-fullscreen"), { description = "Capture entire screen" }),
        hl.bind("TAB", hl.dsp.exec_cmd("blob-capture-region --select-window next"), { description = "Select next window to capture" }),
        hl.bind("CTRL + TAB", hl.dsp.exec_cmd("blob-capture-region --select-window prev"), { description = "Select previous window to capture" }),
      }
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        table.insert(
          selection_binds,
          hl.bind(direction:upper(), hl.dsp.exec_cmd("blob-capture-region --select-window " .. direction), { description = "Select window to capture" })
        )
      end
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == "selection" and selection_layers > 0 then
    selection_layers = selection_layers - 1
    if selection_layers == 0 then
      for _, keybind in ipairs(selection_binds) do
        keybind:unbind()
      end
      selection_binds = {}
    end
  end
end)

o.bind("SUPER + CTRL + S", "Share", "blob-menu toggle share")

o.bind("SUPER + CTRL + PERIOD", "Transcode", "blob-transcode")

o.bind("SUPER + CTRL + R", "Set reminder", "blob-menu toggle reminder-set")
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "blob-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "blob-reminder clear")

o.bind("SUPER + CTRL + ALT + T", "Show time", "blob-notification-time")
o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", "blob-notification-battery")
o.bind("SUPER + CTRL + ALT + W", "Toggle weather", "blob-notification-weather")

o.bind("SUPER + CTRL + A", "Audio", "blob-shell shell toggle blob.audio")
o.bind("SUPER + CTRL + B", "Bluetooth", "blob-shell shell toggle blob.bluetooth")
o.bind("SUPER + CTRL + D", "Display", "blob-shell shell toggle blob.monitor")
o.bind("SUPER + CTRL + ALT + D", "Calendar", "blob-shell shell toggle blob.clock")
o.bind("SUPER + CTRL + W", "Network", "blob-shell shell toggle blob.network")
o.bind("SUPER + CTRL + P", "Power", "blob-shell shell toggle blob.power")
o.bind("SUPER + CTRL + T", "Activity", { tui = "btop" })

-- The letters above name a panel; the numbers count them. 1 is the leftmost
-- panel in the bar's right section, and a widget with no panel of its own (the
-- tray) is not counted, so the number matches the icon a user would point at.
-- A bar with fewer panels than this leaves the tail of the range doing nothing.
for panel = 1, 9 do
  o.bind(
    "SUPER + CTRL + code:" .. tostring(panel + 9),
    "Bar panel " .. panel,
    "blob-shell -q shell togglePanelAt right " .. panel
  )
end

o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)

o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

o.bind("SUPER + CTRL + L", "Lock system", "blob-system-lock")

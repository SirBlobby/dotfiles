-- Essential application bindings.
o.bind("SUPER + RETURN", "Terminal", { blob = "terminal" })
o.bind("SUPER + SHIFT + RETURN", "Browser", { blob = "browser" })
o.bind("SUPER + SHIFT + F", "File manager", { blob = "nautilus" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { blob = "nautilus-cwd" })
o.bind("SUPER + SHIFT + B", "Browser", { blob = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { blob = "browser --private" })
o.bind("SUPER + SHIFT + N", "Editor", { blob = "editor" })

if o.preinstalled_bindings_enabled() then
  o.bind("SUPER + SHIFT + M", "Music", { blob = "spotify" })
  o.bind("SUPER + SHIFT + D", "Docker", { tui = "blob-launch-docker-tui" })
  o.bind("SUPER + SHIFT + G", "Signal", { blob = "signal" })
  o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
end

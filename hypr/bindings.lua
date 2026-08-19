-- Personal keybinding overrides on top of Omarchy's defaults.
-- See current bindings and descriptions: omarchy menu keybindings --print

o.bind("SUPER + ALT + W", "Wallpaper picker", "ags toggle wall-picker")

-- Swap Omarchy 4's defaults back: apps on SUPER + SPACE, root menu on ALT.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Omarchy menu", "omarchy-menu toggle")

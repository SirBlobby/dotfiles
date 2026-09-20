-- Personal keybinding overrides on top of the defaults.
-- See current bindings and descriptions: blob menu keybindings --print

o.bind("SUPER + ALT + W", "Wallpaper picker", "blob-wallpaper-set --menu")
o.bind("SUPER + CTRL + M", "System monitor", "blob-shell shell toggle blob.sysmon")
o.bind("SUPER + SHIFT + CTRL + D", "Displays", "blob-shell shell toggle blob.displays")
o.bind("SUPER + CTRL + Q", "Quick settings", "blob-shell shell toggle blob.quick-settings")

-- Apps on SUPER + SPACE, root menu on ALT, swapping the shipped defaults back.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + SPACE", "Apps menu", "blob-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Blob menu", "blob-menu toggle")

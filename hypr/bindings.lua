-- Personal keybinding overrides on top of the defaults.
-- See current bindings and descriptions: blob menu keybindings --print

o.bind("SUPER + ALT + W", "Wallpaper picker", "blob-wallpaper-set --menu")

-- Apps on SUPER + SPACE, root menu on ALT, swapping the shipped defaults back.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
o.bind("SUPER + SPACE", "Apps menu", "blob-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Blob menu", "blob-menu toggle")

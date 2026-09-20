-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   blob menu keybindings --print

-- To disable every Blob default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.blob"), then add
-- only the bindings you want below:
--   blob_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   blob_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Blob root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Blob menu", "blob-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "blob-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "blob-shell shell toggle blob.emojis")

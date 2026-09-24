-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Blob's bootstrap keeps path setup out of this user config.
dofile((os.getenv("BLOB_PATH") or (os.getenv("HOME") .. "/.local/share/blob")) .. "/default/hypr/bootstrap.lua")

-- Disable all Blob default bindings. Add your own in hypr/bindings.lua.
-- blob_default_bindings = false
--
-- Or disable only bindings for Blob's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- blob_preinstalled_bindings = false

-- Load Blob defaults.
require("default.hypr.blob")

-- Put your personal overrides in these files. They're loaded after Blob's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

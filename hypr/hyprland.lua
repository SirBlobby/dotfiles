-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

dofile((os.getenv("BLOB_PATH") or (os.getenv("HOME") .. "/.local/share/blob")) .. "/default/hypr/bootstrap.lua")

require("default.hypr.blob")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

require("default.hypr.toggles")

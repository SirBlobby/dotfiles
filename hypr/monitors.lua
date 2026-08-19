-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Dual external monitor setup (laptop lid closed).
-- Layout, left -> right: [ 1: C24 / DP-1 ] [ 2: F24 / HDMI-A-1 ] [ eDP-1 ]
-- eDP-1 sits to the right of the externals and Hyprland automatically
-- disables it when the lid is closed (since an external is connected).

-- Monitor 1 - C24 curved, DisplayPort via DP->HDMI adapter.
-- NOTE: the DP2HDMI adapter caps this panel at 1920x1080@60 (no 75Hz mode).
-- Both externals stay at scale 1. Hyprland's fractional scaling works in
-- 1/120 steps and needs whole pixels on both axes, so 1.0 and 1.2 are
-- adjacent valid scales on a 1920x1080 panel - nothing sits between them.
-- Apparent size is tuned with `omarchy display text size` instead.
hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- Monitor 2 - Sceptre F24, HDMI, native 75Hz.
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75", position = "1920x0", scale = 1 })

-- Laptop panel - only mode is 1920x1200@60. Parked right of the externals;
-- auto-off on lid close so no windows get stranded on a closed screen.
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "3840x0", scale = 1.5 })

-- Catch-all fallback for any other/unknown display.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- GDK_SCALE forced integer scaling is intentionally left unset: the external
-- monitors run at 1x, so a global 2x would blow up GTK apps on them. The
-- per-monitor scale factors above are enough.
-- hl.env("GDK_SCALE", "2")

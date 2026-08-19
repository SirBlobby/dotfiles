-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 4,
  },
})

-- Remove default window transparency. Turn it back on with `blob_glass on`,
-- which drops a flag into ~/.local/state/omarchy/toggles/hypr/ that is loaded
-- after this file.
o.window({ tag = "default-opacity" }, { opacity = "1.0 override 1.0 override" })

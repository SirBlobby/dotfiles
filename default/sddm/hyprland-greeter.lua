-- Hyprland config for the SDDM Wayland greeter. SDDM starts the greeter itself
-- once the compositor is up, so nothing here launches anything.
-- The greeter runs as SDDM's own user, with no BLOB_PATH and no read access to
-- the checkout, so it calls the copy install.sh puts in /usr/local/bin rather
-- than loading the Lua modules the session uses. A detector that is not there
-- yet reads as no acceleration, which is the fallback that always draws.
local function gpu_is_accelerated()
  local pipe = io.popen("/usr/local/bin/blob-hw-gpu-accelerated >/dev/null 2>&1 && echo OK")
  if not pipe then
    return false
  end

  local output = pipe:read("*a") or ""
  pipe:close()

  return output:match("OK") ~= nil
end

if not gpu_is_accelerated() then
  hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
  hl.env("WLR_NO_HARDWARE_CURSORS", "1")
end

hl.config({
  cursor = {
    no_hardware_cursors = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },

  animations = {
    enabled = false,
  },
})

local paths = require("default.hypr.paths")

local accelerated = paths.blob_path .. "/bin/blob-hw-gpu-accelerated"

if not o.shell_succeeds(o.shell_quote(accelerated)) then
  hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
  hl.env("WLR_NO_HARDWARE_CURSORS", "1")

  hl.config({
    cursor = {
      no_hardware_cursors = true,
    },
  })
end

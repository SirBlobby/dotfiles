-- Restore workspace layouts saved by blob-hypr-workspace-layout-toggle.

local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

local layouts_dir = paths.state_home .. "/blob/workspace-layouts"

require_all.files(layouts_dir, "blob.workspace-layouts", { reload = true })

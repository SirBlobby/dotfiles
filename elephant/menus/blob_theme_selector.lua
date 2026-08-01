Name = "blobThemeSelector"
NamePretty = "Blob's Theme Selector"
Cache = false
HideFromProviderlist = true
SearchName = true

local function ShellEscape(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function FormatName(slug)
  local name = slug:gsub("-", " ")
  name = name:gsub("%S+", function(word)
    return word:sub(1, 1):upper() .. word:sub(2):lower()
  end)
  return name
end

function GetEntries()
  local entries = {}
  local home = os.getenv("HOME")
  local omarchy_path = os.getenv("OMARCHY_PATH") or ""

  entries[1] = {
    Text = "Dynamic (from wallpaper)",
    Value = "dynamic",
    Actions = {
      activate = "blob_theme --dynamic",
    },
  }

  local dirs = {
    home .. "/.config/omarchy/themes",
    omarchy_path .. "/themes",
  }

  local seen = { ["blob-dynamic"] = true }

  for _, themes_dir in ipairs(dirs) do
    local handle = io.popen(
      "find " .. ShellEscape(themes_dir) .. " -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort"
    )
    if handle then
      for theme_dir in handle:lines() do
        local slug = theme_dir:match("([^/]+)$")
        if slug and not seen[slug] then
          local colors_file = io.open(theme_dir .. "/colors.toml", "r")
          if colors_file then
            colors_file:close()
            seen[slug] = true

            local entry = {
              Text = FormatName(slug),
              Value = slug,
              Actions = {
                activate = "blob_theme " .. ShellEscape(slug),
              },
            }

            local preview_file = io.open(theme_dir .. "/preview.png", "r")
            if preview_file then
              preview_file:close()
              entry.Preview = theme_dir .. "/preview.png"
              entry.PreviewType = "file"
            end

            table.insert(entries, entry)
          end
        end
      end
      handle:close()
    end
  end

  return entries
end

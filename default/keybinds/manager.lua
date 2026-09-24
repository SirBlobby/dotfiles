local action = arg[1] or "list"
local config_path = os.getenv("BLOB_KEYBINDS_CONFIG")
local user_file = os.getenv("BLOB_KEYBINDS_USER_FILE")
local personal_prefix = (os.getenv("HOME") or "") .. "/.config/hypr/"

local modifier_names = { SUPER = true, SHIFT = true, CTRL = true, ALT = true }

local function fail(message)
  io.stderr:write(message, "\n")
  os.exit(1)
end

local function trim(value)
  local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
  return trimmed
end

local function canonical_keys(keys)
  local modifiers, key = {}, ""
  for part in tostring(keys):gmatch("[^+]+") do
    local token = trim(part):upper()
    if token == "CONTROL" then token = "CTRL" end
    if modifier_names[token] then
      modifiers[#modifiers + 1] = token
    elseif token ~= "" then
      key = token
    end
  end
  table.sort(modifiers)
  modifiers[#modifiers + 1] = key
  return table.concat(modifiers, "+"), key
end

local bindings = {}

local function caller_source()
  for level = 2, 12 do
    local info = debug.getinfo(level, "S")
    if not info then break end
    local source = info.source or ""
    if source:sub(1, 1) == "@" and not source:match("helpers%.lua$") then
      return source:sub(2)
    end
  end
  return ""
end

local function dispatcher_proxy(path)
  return setmetatable({ path = path }, {
    __index = function(self, key)
      return dispatcher_proxy(self.path .. "." .. tostring(key))
    end,
    __call = function(self, first)
      if self.path == "hl.dsp.exec_cmd" and type(first) == "string" then
        return { blob_dispatcher = true, kind = "exec", text = first }
      end
      return { blob_dispatcher = true, kind = "dispatcher", text = (self.path:gsub("^hl%.dsp%.", "")) }
    end,
  })
end

local function describe_dispatcher(dispatcher)
  if type(dispatcher) == "table" and dispatcher.blob_dispatcher then
    return dispatcher.kind, dispatcher.text
  elseif type(dispatcher) == "string" then
    return "exec", dispatcher
  end
  return "dispatcher", "Lua function"
end

local noop
noop = setmetatable({}, {
  __index = function() return noop end,
  __call = function() return noop end,
})

hl = setmetatable({
  dsp = dispatcher_proxy("hl.dsp"),
  bind = function(keys, dispatcher, options)
    local opts = options or {}
    local kind, text = describe_dispatcher(dispatcher)
    local source = caller_source()
    bindings[#bindings + 1] = {
      keys = tostring(keys),
      canonical = canonical_keys(keys),
      description = opts.description or "",
      kind = kind,
      action = text,
      origin = source:sub(1, #personal_prefix) == personal_prefix and "personal" or "default",
      state = "active",
    }
    return noop
  end,
  unbind = function(keys)
    local canonical = canonical_keys(keys)
    for _, binding in ipairs(bindings) do
      if binding.canonical == canonical and binding.state == "active" then
        binding.state = "disabled"
      end
    end
    return noop
  end,
  get_config = function() return nil end,
}, {
  __index = function() return noop end,
})

local function load_bindings()
  local config_file = config_path and io.open(config_path, "r")
  if not config_file then
    fail("Hyprland config not found: " .. tostring(config_path))
  end
  config_file:close()
  local ok, message = pcall(dofile, config_path)
  if not ok then
    fail("Could not read the Hyprland config: " .. tostring(message))
  end

  local personal_active = {}
  for _, binding in ipairs(bindings) do
    if binding.origin == "personal" and binding.state == "active" then
      personal_active[binding.canonical] = true
    end
  end
  for _, binding in ipairs(bindings) do
    if binding.origin == "default" and binding.state == "disabled" and personal_active[binding.canonical] then
      binding.state = "overridden"
    end
  end
end

local function clean(value)
  return (tostring(value):gsub("[\t\n]", " "))
end

local function print_bindings()
  for _, binding in ipairs(bindings) do
    if binding.description ~= "" then
      print(table.concat({
        binding.origin, binding.state, clean(binding.keys),
        clean(binding.description), binding.kind, clean(binding.action),
      }, "\t"))
    end
  end
end

local function read_lines(path)
  local lines = {}
  local file = io.open(path, "r")
  if not file then return lines end
  for line in file:lines() do lines[#lines + 1] = line end
  file:close()
  return lines
end

local function write_lines(path, lines)
  local temporary = path .. ".tmp"
  local file = io.open(temporary, "w") or fail("Cannot write " .. temporary)
  file:write(table.concat(lines, "\n"), "\n")
  file:close()
  local ok, message = os.rename(temporary, path)
  if not ok then fail("Cannot replace " .. path .. ": " .. tostring(message)) end
end

local function bind_line_keys(line)
  return line:match('^%s*o%.bind_toggle%(%s*"(.-)"')
    or line:match('^%s*o%.bind%(%s*"(.-)"')
    or line:match('^%s*hl%.bind%(%s*"(.-)"')
end

local function unbind_line_keys(line)
  return line:match('^%s*hl%.unbind%(%s*"(.-)"%s*%)')
end

local function without_lines(lines, canonical, drop_binds, drop_unbinds)
  local kept, removed = {}, 0
  for _, line in ipairs(lines) do
    local bind_keys = bind_line_keys(line)
    local unbind_keys = unbind_line_keys(line)
    if drop_binds and bind_keys and canonical_keys(bind_keys) == canonical then
      removed = removed + 1
    elseif drop_unbinds and unbind_keys and canonical_keys(unbind_keys) == canonical then
      removed = removed + 1
    else
      kept[#kept + 1] = line
    end
  end
  return kept, removed
end

local function has_unbind(lines, canonical)
  for _, line in ipairs(lines) do
    local keys = unbind_line_keys(line)
    if keys and canonical_keys(keys) == canonical then return true end
  end
  return false
end

local function has_active_default(canonical)
  for _, binding in ipairs(bindings) do
    if binding.origin == "default" and binding.canonical == canonical and binding.state == "active" then
      return true
    end
  end
  return false
end

local function require_key(keys)
  local canonical, key = canonical_keys(keys)
  if key == "" then fail("Keys need a key besides the modifiers, such as SUPER + SHIFT + K") end
  return canonical
end

local function reject_newlines(...)
  for index = 1, select("#", ...) do
    if tostring(select(index, ...)):find("\n") then fail("Values must be a single line") end
  end
end

local function add_binding(keys, description, command, replaced_keys)
  reject_newlines(keys, description, command)
  if trim(description) == "" or trim(command) == "" then fail("A binding needs a description and a command") end
  local canonical = require_key(keys)
  local lines = read_lines(user_file)

  if replaced_keys and replaced_keys ~= "" then
    lines = without_lines(lines, canonical_keys(replaced_keys), true, true)
  end
  lines = without_lines(lines, canonical, true, false)

  if has_active_default(canonical) and not has_unbind(lines, canonical) then
    lines[#lines + 1] = string.format("hl.unbind(%q)", trim(keys))
  end
  lines[#lines + 1] = string.format("o.bind(%q, %q, %q)", trim(keys), trim(description), trim(command))
  write_lines(user_file, lines)
end

local function reset_binding(keys)
  local lines, removed = without_lines(read_lines(user_file), require_key(keys), true, true)
  if removed == 0 then fail("No personal binding or disabled default for " .. keys) end
  write_lines(user_file, lines)
end

local function disable_binding(keys)
  local canonical = require_key(keys)
  if not has_active_default(canonical) then fail("No active default binding for " .. keys) end
  local lines = read_lines(user_file)
  lines[#lines + 1] = string.format("hl.unbind(%q)", trim(keys))
  write_lines(user_file, lines)
end

load_bindings()

if action == "list" then
  print_bindings()
elseif action == "add" then
  add_binding(arg[2] or "", arg[3] or "", arg[4] or "", arg[5])
elseif action == "reset" then
  reset_binding(arg[2] or "")
elseif action == "disable" then
  disable_binding(arg[2] or "")
else
  fail("Unknown action: " .. action)
end

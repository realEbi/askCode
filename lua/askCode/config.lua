---@class Config
---@field agent string
---@field debug boolean
---@field quit_key string
---@field output_format string
---@field window table

local M = {}

---@type Config config
M.default = {
  agent = "gemini",
  debug = false,
  quit_key = "q",
  output_format = "json",
  window = {
    type = "float", -- float, vertical, horizontal
    width_ratio = 0.7,
    height_ratio = 0.7,
    max_width = 240,
    max_height = 60,
  },
}

--- updates config
---@param changes? Config
---@return Config
function M.merge_with_default(changes)
  changes = changes or {}
  M.current_config = vim.tbl_deep_extend("keep", vim.deepcopy(changes), M.current_config)
  return M.current_config
end

M.current_config = vim.deepcopy(M.default)

--- gets a config value
---@param key? string dot separated key
---@return any
function M.get(key)
  if not key then
    return M.current_config
  end
  local parts = vim.split(key, "%.")
  local current = M.current_config
  for _, part in ipairs(parts) do
    if type(current) ~= "table" or current[part] == nil then
      return nil
    end
    current = current[part]
  end
  return current
end

--- sets a config value
---@param key string dot separated key
---@param value any
---@return any new value
function M.set(key, value)
  local parts = vim.split(key, "%.")
  if type(value) == "string" then
    if value == "true" then
      value = true
    elseif value == "false" then
      value = false
    elseif tonumber(value) then
      value = tonumber(value)
    end
  end

  local t = {}
  local current = t
  for i, part in ipairs(parts) do
    if i == #parts then
      current[part] = value
    else
      current[part] = {}
      current = current[part]
    end
  end
  M.merge_with_default(t)
  return M.get(key)
end

--- resets config to default
function M.reset_config()
  M.current_config = vim.deepcopy(M.default)
end

--- gets all config keys as dot-separated strings
---@return string[]
function M.get_all_keys()
  local keys = {}
  local function traverse(tbl, prefix)
    for key, value in pairs(tbl) do
      local full_key = prefix == "" and key or prefix .. "." .. key
      if type(value) == "table" then
        traverse(value, full_key)
      else
        table.insert(keys, full_key)
      end
    end
  end
  traverse(M.default, "")
  return keys
end

return M

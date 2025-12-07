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

  -- merge basic settings
  ---@type Config
  local config = vim.tbl_deep_extend("force", M.default, changes)
  M.current_config = config
  return M.current_config
end

M.current_config = M.default

return M

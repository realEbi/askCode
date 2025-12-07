local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

-- Define main test set of this file
local T = new_set({
  -- Register hooks
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[M = require('askCode')]])
      child.lua([[M.setup()]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

-- Test set fields define nested structure
T["config"] = new_set()

-- Define test action as callable field of test set.
-- If it produces error - test fails.
T["config"]["default value"] = function()
  -- expected result
  eq(child.lua_get([[require('askCode.config').current_config]]), {
    agent = "gemini",
    debug = false,
    quit_key = "q",
    output_format = "json",
    window = {
      type = "float",
      width_ratio = 0.7,
      height_ratio = 0.7,
      max_width = 240,
      max_height = 60,
    },
  })
end

T["config"]["custom value"] = function()
  child.lua([[M.setup({agent="q"})]])
  eq(child.lua_get([[require('askCode.config').current_config]]), {
    agent = "q",
    debug = false,
    quit_key = "q",
    output_format = "json",
    window = {
      type = "float",
      width_ratio = 0.7,
      height_ratio = 0.7,
      max_width = 240,
      max_height = 60,
    },
  })
end

return T

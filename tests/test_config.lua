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

T["get()"] = new_set()

T["get()"]["returns entire config when no key provided"] = function()
  local config = child.lua_get([[require('askCode.config').get()]])
  eq(config.agent, "gemini")
  eq(config.debug, false)
end

T["get()"]["returns top-level value"] = function()
  eq(child.lua_get([[require('askCode.config').get('agent')]]), "gemini")
  eq(child.lua_get([[require('askCode.config').get('debug')]]), false)
end

T["get()"]["returns nested value with dot notation"] = function()
  eq(child.lua_get([[require('askCode.config').get('window.type')]]), "float")
  eq(child.lua_get([[require('askCode.config').get('window.width_ratio')]]), 0.7)
end

T["get()"]["returns nil for non-existent key"] = function()
  eq(child.lua_get([[require('askCode.config').get('nonexistent')]]), vim.NIL)
  eq(child.lua_get([[require('askCode.config').get('window.nonexistent')]]), vim.NIL)
end

T["set()"] = new_set()

T["set()"]["sets top-level value"] = function()
  child.lua([[require('askCode.config').set('agent', 'amazonq')]])
  eq(child.lua_get([[require('askCode.config').get('agent')]]), "amazonq")
end

T["set()"]["sets nested value with dot notation"] = function()
  child.lua([[require('askCode.config').set('window.type', 'vertical')]])
  eq(child.lua_get([[require('askCode.config').get('window.type')]]), "vertical")
end

T["set()"]["converts string 'true' to boolean"] = function()
  child.lua([[require('askCode.config').set('debug', 'true')]])
  eq(child.lua_get([[require('askCode.config').get('debug')]]), true)
end

T["set()"]["converts string 'false' to boolean"] = function()
  child.lua([[require('askCode.config').set('debug', 'false')]])
  eq(child.lua_get([[require('askCode.config').get('debug')]]), false)
end

T["set()"]["converts numeric string to number"] = function()
  child.lua([[require('askCode.config').set('window.max_width', '300')]])
  eq(child.lua_get([[require('askCode.config').get('window.max_width')]]), 300)
end

T["set()"]["returns the new value"] = function()
  local result = child.lua_get([[require('askCode.config').set('agent', 'gemini')]])
  eq(result, "gemini")
end

T["reset_config()"] = new_set()

T["reset_config()"]["resets config to default values"] = function()
  child.lua([[require('askCode.config').set('agent', 'amazonq')]])
  child.lua([[require('askCode.config').set('window.type', 'vertical')]])
  child.lua([[require('askCode.config').reset_config()]])
  
  eq(child.lua_get([[require('askCode.config').get('agent')]]), "gemini")
  eq(child.lua_get([[require('askCode.config').get('window.type')]]), "float")
end

return T

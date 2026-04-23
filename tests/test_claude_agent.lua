local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[Agent = require('askCode.agents.claude')]])
    end,
    post_once = child.stop,
  },
})

-- Test setup function
T["setup"] = new_set()

T["setup"]["should merge configuration"] = function()
  child.lua([[Agent.setup({ test_option = "test_value" })]])
  eq(child.lua_get([[Agent.config.test_option]]), "test_value")
end

-- Test prepare_command function
T["prepare_command"] = new_set()

T["prepare_command"]["should contain claude -p and a temp file cat"] = function()
  local command = child.lua_get([[Agent.prepare_command("test prompt")]])
  eq(type(command), "string")
  eq(command:match("claude %-p") ~= nil, true)
  eq(command:match("%$%(cat .+%)") ~= nil, true)
end

T["prepare_command"]["should clean up temp file in command"] = function()
  local command = child.lua_get([[Agent.prepare_command("test prompt")]])
  eq(command:match("rm %-f") ~= nil, true)
end

-- Test parse_response function
T["parse_response"] = new_set()

T["parse_response"]["should return trimmed plain text"] = function()
  local result = child.lua_get([[Agent.parse_response("  Hello, world!  ")]])
  eq(result, "Hello, world!")
end

T["parse_response"]["should return text as-is when no surrounding whitespace"] = function()
  local result = child.lua_get([[Agent.parse_response("plain response")]])
  eq(result, "plain response")
end

T["parse_response"]["should preserve internal newlines"] = function()
  local result = child.lua_get([[Agent.parse_response("line one\nline two")]])
  eq(result, "line one\nline two")
end

T["parse_response"]["should return nil for empty string"] = function()
  eq(child.lua_get([[Agent.parse_response("")]]), vim.NIL)
end

T["parse_response"]["should return nil for nil input"] = function()
  eq(child.lua_get([[Agent.parse_response(nil)]]), vim.NIL)
end

T["parse_response"]["should return nil for whitespace-only string"] = function()
  eq(child.lua_get([[Agent.parse_response("   ")]]), vim.NIL)
end

-- Test ask function with mocked io.popen
T["ask"] = new_set()

T["ask"]["should return parsed response from command"] = function()
  child.lua([[
    local original_popen = io.popen
    io.popen = function()
      return {
        read = function() return "mocked claude response" end,
        close = function() end,
      }
    end
  ]])

  eq(child.lua_get([[Agent.ask("test prompt")]]), "mocked claude response")
  child.lua([[io.popen = original_popen]])
end

T["ask"]["should return nil when command fails"] = function()
  child.lua([[
    local original_popen = io.popen
    io.popen = function() return nil end
  ]])
  eq(child.lua_get([[Agent.ask("test prompt")]]), vim.NIL)
  child.lua([[io.popen = original_popen]])
end

T["ask"]["should return nil for empty response"] = function()
  child.lua([[
    local original_popen = io.popen
    io.popen = function()
      return {
        read = function() return "" end,
        close = function() end,
      }
    end
  ]])
  eq(child.lua_get([[Agent.ask("test prompt")]]), vim.NIL)
  child.lua([[io.popen = original_popen]])
end

return T

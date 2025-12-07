local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create an isolated Neovim instance for testing
local child = MiniTest.new_child_neovim()

-- Define the main test set for this file
local T = new_set({
  hooks = {
    -- Before each test case, restart Neovim with a minimal config
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load the plugin or module you are testing
      child.lua([[
        M = require('askCode')
        runner = require('askCode.runner')
        ui = require('askCode.ui')
        utils = require('askCode.utils')
        agents = require('askCode.agents')
        config = require('askCode.config')

        -- Mock UI functions
        _G.show_window_calls = {}
        ui.show_window = function(content, on_close)
          table.insert(_G.show_window_calls, {content = content})
          return 1, 1 -- return mock win_id and buf_id
        end

        _G.update_window_calls = {}
        ui.update_window = function(win_id, buf_id, content)
          table.insert(_G.update_window_calls, {win_id = win_id, buf_id = buf_id, content = content})
        end
      ]])
    end,
    -- After all tests in this set are done, stop the child process
    post_once = child.stop,
  },
})

-- Define a nested test set for a specific function or feature
T["ask"] = new_set()

-- Define a test case for plain text response
T["ask"]["should show plain text response in new window"] = function()
  -- 1. Mock dependencies
  child.lua([[ 
    utils.get_buffer_content = function() return "mock buffer content" end
    agents.get_agent = function(name)
      return {
        prepare_command = function(question) return "echo 'mocked response'" end
      }
    end
    runner.run_command = function(cmd, on_stdout, opts)
      vim.defer_fn(function()
        on_stdout(nil, {"mocked response"}, nil)
        opts.on_exit()
      end, 10)
    end
  ]])

  -- 2. Execute the function
  child.lua([[M.ask('test question', 'visual')]])
  child.lua("vim.loop.sleep(100)") -- Wait for async operations

  -- 3. Assert the expected outcome
  local update_calls = child.lua_get("_G.update_window_calls")
  eq(#update_calls, 1)
  eq(update_calls[1].content, "AGENT: mocked response")
end

-- Define a test case for JSON response
T["ask"]["should parse and show JSON response in new window"] = function()
  -- 1. Mock dependencies
  child.lua([[ 
    utils.get_buffer_content = function() return "mock buffer content" end
    agents.get_agent = function(name)
      return {
        prepare_command = function(question) return "echo 'json response'" end,
        parse_response = function(json_string) return "parsed content" end
      }
    end
    runner.run_command = function(cmd, on_stdout, opts)
      vim.defer_fn(function()
        on_stdout(nil, {"json response"}, nil)
        opts.on_exit()
      end, 10)
    end
  ]])

  -- 2. Execute the function
  child.lua([[M.ask('test question', 'visual')]])
  child.lua("vim.loop.sleep(100)") -- Wait for async operations

  -- 3. Assert the expected outcome
  local update_calls = child.lua_get("_G.update_window_calls")
  eq(#update_calls, 1)
  eq(update_calls[1].content, "AGENT: parsed content")
end

T["follow_up"] = new_set()

T["follow_up"]["should update window with conversation"] = function()
  -- 1. Mock dependencies
  child.lua([[ 
    utils.get_buffer_content = function() return "mock buffer content" end
    agents.get_agent = function(name)
      return {
        prepare_command = function(question) return "echo 'response'" end,
        parse_response = function(res) return res end
      }
    end
    local ask_count = 0
    runner.run_command = function(cmd, on_stdout, opts)
      ask_count = ask_count + 1
      vim.defer_fn(function()
        if ask_count == 1 then
          on_stdout(nil, {"initial response"}, nil)
        else
          on_stdout(nil, {"follow-up response"}, nil)
        end
        opts.on_exit()
      end, 10)
    end
  ]])

  -- 2. Execute initial question and follow-up
  child.lua([[M.ask('initial question', 'visual')]])
  child.lua("vim.loop.sleep(100)") -- Wait for async operations
  child.lua([[M.follow_up('follow-up question')]])
  child.lua("vim.loop.sleep(100)") -- Wait for async operations

  -- 3. Assert the expected outcome
  local update_calls = child.lua_get("_G.update_window_calls")
  eq(#update_calls, 2) -- One for initial ask, one for follow-up
  local expected_content = "AGENT: initial response\n\n---\n\nUSER: follow-up question\n\nAGENT: follow-up response"
  eq(update_calls[2].content, expected_content)
end


return T
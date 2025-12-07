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
      -- Set editor dimensions for predictable window size
      child.o.columns = 100
      child.o.lines = 40
      -- Load config first, then UI module
      child.lua([[require('askCode.config').merge_with_default()]])
      child.lua([[ui = require('askCode.ui')]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

-- Test set for show_window
T["show_window()"] = new_set()

T["show_window()"]["creates a floating window with content"] = function()
  -- Execute the function
  child.lua([[ 
    win_id, buf_id = ui.show_window("hello\nworld")
  ]])
  local win_id = child.lua_get("win_id")
  local buf_id = child.lua_get("buf_id")

  -- Check if window and buffer are valid
  eq(child.lua_get("vim.api.nvim_win_is_valid(" .. win_id .. ")"), true)
  eq(child.lua_get("vim.api.nvim_buf_is_valid(" .. buf_id .. ")"), true)

  -- Verify buffer content
  local buffer_content = child.lua_get("vim.api.nvim_buf_get_lines(" .. buf_id .. ", 0, -1, false)")
  eq(buffer_content, { "hello", "world" })
end

T["show_window()"]["calls on_close when window is closed"] = function()
  child.lua([[ 
    _G.close_called = false
    local on_close = function()
      _G.close_called = true
    end
    win_id, buf_id = ui.show_window("test", on_close)
  ]])

  -- Close the window by sending 'q'
  child.api.nvim_input("q")
  child.lua("vim.loop.sleep(100)") -- give time for event to be processed

  -- Check if on_close was called
  eq(child.lua_get("_G.close_called"), true)
end


-- Test set for update_window
T["update_window()"] = new_set()

T["update_window()"]["updates the content of a floating window"] = function()
  -- Create a window first
  child.lua([[ 
    win_id, buf_id = ui.show_window("initial content")
  ]])
  local win_id = child.lua_get("win_id")
  local buf_id = child.lua_get("buf_id")

  -- Update the window
  child.lua("ui.update_window(" .. win_id .. ", " .. buf_id .. ", [[new\ncontent]])")
  child.lua("vim.loop.sleep(50)") -- Wait for vim.schedule

  -- Verify buffer content
  local buffer_content = child.lua_get("vim.api.nvim_buf_get_lines(" .. buf_id .. ", 0, -1, false)")
  eq(buffer_content, { "new", "content" })

  -- Verify cursor position
  local cursor_pos = child.lua_get("vim.api.nvim_win_get_cursor(" .. win_id .. ")")
  eq(cursor_pos[1], 2)
end

return T

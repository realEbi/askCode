local config = require("askCode.config")
local M = {}

--- Creates a window to show content.
--- @param content string The content to display.
--- @param on_close function A callback to execute when the window is closed.
--- @param editable boolean|nil Whether the window should be editable (default: false).
--- @param on_apply function|nil Callback for apply action (Q key) - receives edited content.
--- @return number, number The window ID and buffer ID.
function M.show_window(content, on_close, editable, on_apply)
  local window_config = config.current_config.window
  local window_type = window_config.type or "float"

  local buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf_id })

  local win_id
  if window_type == "vertical" then
    vim.api.nvim_command("vsplit")
    win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_id, buf_id)
    local width = math.floor(vim.o.columns * window_config.width_ratio)
    if width > window_config.max_width then
      width = window_config.max_width
    end
    vim.api.nvim_win_set_width(win_id, width)
  elseif window_type == "horizontal" then
    vim.api.nvim_command("split")
    win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_id, buf_id)
    local height = math.floor(vim.o.lines * window_config.height_ratio)
    if height > window_config.max_height then
      height = window_config.max_height
    end
    vim.api.nvim_win_set_height(win_id, height)
  else -- float is the default
    local width = math.floor(vim.o.columns * window_config.width_ratio)
    if width > window_config.max_width then
      width = window_config.max_width
    end

    local height = math.floor(vim.o.lines * window_config.height_ratio)
    if height > window_config.max_height then
      height = window_config.max_height
    end

    local win_opts = {
      relative = "cursor",
      width = width,
      height = height,
      row = 1,
      col = 0,
      style = "minimal",
      border = "rounded",
    }
    win_id = vim.api.nvim_open_win(buf_id, true, win_opts)
  end

  -- Prepare content with instructions if editable
  -- Set content
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(content, "\n"))

  if not editable then
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf_id })
  end

  -- Set up keymaps
  if editable and on_apply then
    -- Q to apply
    vim.keymap.set("n", "Q", function()
      local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
      local edited_content = table.concat(lines, "\n")
      -- Remove instruction lines
      edited_content = edited_content:gsub("^Press Q to apply replacement, q to cancel\n\n", "")

      if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
      end
      if on_apply then
        on_apply(edited_content)
      end
      if on_close then
        on_close()
      end
    end, { buffer = buf_id })
  end

  -- q to close
  vim.keymap.set("n", config.current_config.quit_key, function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
    end
    if on_close then
      on_close()
    end
  end, { buffer = buf_id })

  return win_id, buf_id
end

--- Updates the content of a window.
--- @param win_id number The ID of the window to update.
--- @param buf_id number The ID of the buffer to update.
--- @param content string The new content.
--- @param replacement? boolean if the buffer is for replacement command
--- @param cursor_line number|nil Optional line number to position cursor (defaults to end).
function M.update_window(win_id, buf_id, content, cursor_line, replacement)
  vim.schedule(function()
    if not (buf_id and vim.api.nvim_buf_is_valid(buf_id)) then
      return
    end
    if not (win_id and vim.api.nvim_win_is_valid(win_id)) then
      return
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(content, "\n"))
    -- in replacement mode the buffer should be editable
    if not replacement then
      vim.api.nvim_set_option_value("modifiable", false, { buf = buf_id })
    end

    -- Position cursor
    local line_count = vim.api.nvim_buf_line_count(buf_id)
    local target_line = cursor_line or line_count
    vim.api.nvim_win_set_cursor(win_id, { target_line, 0 })
  end)
end

return M

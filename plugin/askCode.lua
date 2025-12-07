require("askCode")

vim.api.nvim_create_user_command("AskCode", function(opts)
  local mode
  if opts.range == 0 then
    mode = "n"
  else
    mode = "v"
  end
  if #opts.args == 0 then
    vim.ui.input({ prompt = "Question: " }, function(question)
      if question and question ~= "" then
        require("askCode").ask_or_follow_up(question, mode)
      end
    end)
  else
    require("askCode").ask_or_follow_up(opts.args, mode)
  end
end, { range = true, nargs = "?" })

vim.api.nvim_create_user_command("AskCodeReplace", function(opts)
  local mode
  if opts.range == 0 then
    mode = "n"
  else
    mode = "v"
    -- Store range info in a global variable that can be accessed by get_buffer_content
    vim.g.askcode_range = { start_line = opts.line1, end_line = opts.line2 }
  end
  if #opts.args == 0 then
    vim.ui.input({ prompt = "Replacement request: " }, function(question)
      if question and question ~= "" then
        require("askCode").ask_replace(question, mode)
      end
    end)
  else
    require("askCode").ask_replace(opts.args, mode)
  end
end, { range = true, nargs = "?" })

vim.api.nvim_create_user_command("AskCodeConfig", function(opts)
  local args = vim.split(opts.args, "%s+")
  local key = args[1]
  local value = args[2]
  
  if not key or key == "" then
    vim.notify("Usage: AskCodeConfig <key> [value]", vim.log.levels.ERROR)
    return
  end
  
  if value then
    local new_value = require("askCode").set_config(key, value)
    vim.notify(string.format("Set %s = %s", key, vim.inspect(new_value)), vim.log.levels.INFO)
  else
    local current_value = require("askCode").get_config(key)
    vim.notify(string.format("%s = %s", key, vim.inspect(current_value)), vim.log.levels.INFO)
  end
end, {
  nargs = "+",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local args = vim.split(cmd_line, "%s+")
    if #args <= 2 then
      local keys = require("askCode.config").get_all_keys()
      return vim.tbl_filter(function(key)
        return vim.startswith(key, arg_lead)
      end, keys)
    end
    return {}
  end,
})

vim.keymap.set(
  "v",
  "<Plug>(AskCodeExplain)",
  'AskCode "Explain this code"<CR>',
  { desc = "Asking code agent to explain the selected code" }
)
vim.keymap.set(
  "v",
  "<Plug>(AskCodeAddDocstring)",
  ':AskCodeReplace "Add docstring to this function"<CR>',
  { desc = "Asking code agent add docstring to the selected function" }
)

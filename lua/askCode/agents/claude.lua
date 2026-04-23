local M = {
  config = {},
}

--- Merges the given configuration with the default settings.
--- @param cfg table The configuration table to merge.
function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

--- Prepares the shell command for sending a prompt to the Claude CLI.
--- Writes the prompt to a temp file to safely handle multiline content.
--- @param prompt string The prompt to be sent.
--- @return string The fully formed shell command.
function M.prepare_command(prompt)
  local tmpfile = vim.fn.tempname()
  local f = io.open(tmpfile, "w")
  if f then
    f:write(prompt)
    f:close()
  end
  return string.format('claude -p "$(cat %s)" 2>&1; rm -f %s', tmpfile, tmpfile)
end

--- Parses the plain-text response from the Claude CLI.
--- The `-p` flag produces plain text output, so this just trims whitespace.
--- @param response_string string The raw CLI output to parse.
--- @return string? The cleaned response, or nil if empty.
function M.parse_response(response_string)
  if not response_string or response_string == "" then
    vim.notify("Empty response from claude", vim.log.levels.ERROR)
    return nil
  end

  local result = response_string:gsub("^%s+", ""):gsub("%s+$", "")
  return result ~= "" and result or nil
end

--- Sends a prompt to the Claude CLI and returns the response.
--- @param prompt string The prompt to send.
--- @return string? The response from the CLI, or nil if an error occurred.
function M.ask(prompt)
  local command = M.prepare_command(prompt)

  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to execute claude command", vim.log.levels.ERROR)
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result and result ~= "" then
    return M.parse_response(result)
  end

  return nil
end

return M

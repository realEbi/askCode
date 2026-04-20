local M = {
  config = {},
}

--- Merges the given configuration with the default settings.
--- @param cfg table The configuration table to merge.
function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

--- Prepares the shell command for sending a prompt to the opencode CLI.
--- Writes the prompt to a temp file to safely handle multiline content.
--- Uses --format json so the process exits cleanly after the response.
--- @param prompt string The prompt to be sent.
--- @return string The fully formed shell command.
function M.prepare_command(prompt)
  local tmpfile = vim.fn.tempname()
  local f = io.open(tmpfile, "w")
  if f then
    f:write(prompt)
    f:close()
  end
  return string.format('opencode run --format json "$(cat %s)" 2>&1; rm -f %s', tmpfile, tmpfile)
end

--- Parses the JSON event stream response from the opencode CLI.
--- Concatenates all text parts from "text" type events.
--- @param response_string string The raw CLI output to parse.
--- @return string? The cleaned response, or nil if parsing fails.
function M.parse_response(response_string)
  if not response_string or response_string == "" then
    vim.notify("Empty response from opencode", vim.log.levels.ERROR)
    return nil
  end

  local parts = {}
  for line in response_string:gmatch("[^\n]+") do
    local ok, event = pcall(vim.fn.json_decode, line)
    if ok and type(event) == "table" and event.type == "text" and event.part and event.part.text then
      table.insert(parts, event.part.text)
    end
  end

  local result = table.concat(parts, ""):gsub("^%s+", ""):gsub("%s+$", "")
  return result ~= "" and result or nil
end

--- Sends a prompt to the opencode CLI and returns the response.
--- @param prompt string The prompt to send.
--- @return string? The response from the CLI, or nil if an error occurred.
function M.ask(prompt)
  local command = M.prepare_command(prompt)

  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to execute opencode command", vim.log.levels.ERROR)
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

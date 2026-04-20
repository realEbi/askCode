local M = {}

--- Runs an external command and streams the output via callbacks.
--- @param cmd table The command and its arguments (e.g., {"ls", "-l"}).
--- @param on_stdout function Callback for stdout, receives (job_id, data, event_name).
--- @param opts table|nil Optional parameters.
--   - on_stderr (function): Callback for stderr.
--   - on_exit (function): Callback for process exit.
--   - stdout_buffered (boolean): Whether to buffer stdout. Defaults to false.
--- @return number|nil job_id The job_id of the started process, or nil on error.
M.run_command = function(cmd, on_stdout, opts)
  opts = opts or {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = opts.stdout_buffered or false,
    stdin = opts.stdin or "null",
    on_stdout = on_stdout,
    on_stderr = opts.on_stderr,
    on_exit = opts.on_exit,
  })
  return job_id
end

return M

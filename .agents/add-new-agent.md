# Implementation Plan: Adding a New Agent to askCode.nvim

This document is a step-by-step, reproducible guide for an AI agent to add a new CLI-backed AI agent to the plugin. No files beyond what is listed here need to be created or modified.

---

## Inputs Required

Before starting, collect the following two pieces of information:

| Input | Description | Example |
|---|---|---|
| `AGENT_NAME` | The lowercase identifier used in config and filenames | `claude`, `gemini`, `opencode` |
| `CLI_INVOCATION` | The shell command pattern that sends a prompt non-interactively and exits | `claude -p "<prompt>"` |

---

## Step 1 — Determine the CLI Output Format

Inspect the CLI's non-interactive output to decide which `parse_response` strategy to use:

| Output type | Characteristics | Examples |
|---|---|---|
| **Plain text** | Raw human-readable text, possibly with ANSI codes | `claude -p`, `kiro-cli chat --no-interactive` |
| **JSON object** | Single JSON object on one line with a known response field | `gemini --output-format json` → `{"response": "..."}` |
| **JSON event stream** | One JSON object per line, only `"type":"text"` lines carry content | `opencode run --format json` |

Choose the matching strategy — it determines `parse_response` in Step 3.

---

## Step 2 — Determine the Prompt Input Method

Choose how the prompt is passed to the CLI:

### Option A — `shellescape` + pipe (simple CLIs)
Use when the CLI reads from stdin and the prompt is unlikely to contain complex multiline content.

```lua
function M.prepare_command(prompt)
  local escaped_prompt = vim.fn.shellescape(prompt)
  return string.format("echo %s | YOUR_CLI_COMMAND 2>&1", escaped_prompt)
end
```

### Option B — Tempfile (recommended for multiline-safe CLIs)
Use when the CLI takes the prompt as a flag argument, or when prompts may contain code with newlines and special characters. The tempfile is cleaned up inline.

```lua
function M.prepare_command(prompt)
  local tmpfile = vim.fn.tempname()
  local f = io.open(tmpfile, "w")
  if f then
    f:write(prompt)
    f:close()
  end
  return string.format('YOUR_CLI_COMMAND "$(cat %s)" 2>&1; rm -f %s', tmpfile, tmpfile)
end
```

> Use Option B when the CLI uses a flag like `-p "..."` or `run "..."` where the prompt is a positional/flag argument rather than stdin.

---

## Step 3 — Create the Agent File

Create the file `lua/askCode/agents/AGENT_NAME.lua`.

Use the template below, filling in the three sections marked with comments.

```lua
local M = {
  config = {},
}

function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

-- [SECTION 1] prepare_command — paste Option A or Option B from Step 2
-- Replace YOUR_CLI_COMMAND with the actual CLI invocation
function M.prepare_command(prompt)
  -- ...
end

-- [SECTION 2] parse_response — paste the matching strategy from below
function M.parse_response(response_string)
  -- ...
end

function M.ask(prompt)
  local command = M.prepare_command(prompt)
  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to execute AGENT_NAME command", vim.log.levels.ERROR)
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
```

### `parse_response` strategy: Plain text

```lua
function M.parse_response(response_string)
  if not response_string or response_string == "" then
    vim.notify("Empty response from AGENT_NAME", vim.log.levels.ERROR)
    return nil
  end
  local result = response_string:gsub("^%s+", ""):gsub("%s+$", "")
  return result ~= "" and result or nil
end
```

If the CLI output contains ANSI escape codes (e.g. color, cursor control), add this stripping step before trimming:

```lua
  local result = response_string
    :gsub("\27%[[%d;]*[mKHJhlABCDEFGST]", "")
    :gsub("\27%[%?%d+[hl]", "")
    :gsub("^%s+", ""):gsub("%s+$", "")
```

### `parse_response` strategy: JSON object

```lua
function M.parse_response(json_string)
  local ok, decoded = pcall(vim.fn.json_decode, json_string)
  if not ok or type(decoded) ~= "table" or not decoded.RESPONSE_FIELD then
    vim.notify("Failed to parse AGENT_NAME response: " .. tostring(json_string), vim.log.levels.ERROR)
    return nil
  end
  return decoded.RESPONSE_FIELD  -- replace with actual field name, e.g. decoded.response
end
```

### `parse_response` strategy: JSON event stream

```lua
function M.parse_response(response_string)
  if not response_string or response_string == "" then
    vim.notify("Empty response from AGENT_NAME", vim.log.levels.ERROR)
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
```

> Adjust the field path (`event.part.text`) to match the actual JSON schema your CLI emits.

---

## Step 4 — Register the Agent

Edit `lua/askCode/agents/init.lua`. Add one line inside the `M.agents` table:

```lua
M.agents = {
  gemini   = require("askCode.agents.gemini"),
  kiro     = require("askCode.agents.kiro"),
  opencode = require("askCode.agents.opencode"),
  claude   = require("askCode.agents.claude"),
  AGENT_NAME = require("askCode.agents.AGENT_NAME"),  -- add this line
}
```

---

## Step 5 — Update the Documentation

Edit `.agents/summary/interfaces.md`. Find the `agent` config line and append the new name:

```
  agent = "gemini",   -- "gemini" | "kiro" | "opencode" | "claude" | "AGENT_NAME"
```

---

## Step 6 — Write Unit Tests

Create the file `tests/test_AGENT_NAME_agent.lua`.

The test file must cover all four test groups below. Replace `AGENT_NAME` and adjust the mock output and assertions to match the actual CLI output format.

```lua
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[Agent = require('askCode.agents.AGENT_NAME')]])
    end,
    post_once = child.stop,
  },
})

-- Group 1: setup
T["setup"] = new_set()

T["setup"]["should merge configuration"] = function()
  child.lua([[Agent.setup({ test_option = "test_value" })]])
  eq(child.lua_get([[Agent.config.test_option]]), "test_value")
end

-- Group 2: prepare_command
T["prepare_command"] = new_set()

T["prepare_command"]["should contain the CLI binary name"] = function()
  local command = child.lua_get([[Agent.prepare_command("test prompt")]])
  eq(type(command), "string")
  -- Assert key parts of the command string are present, e.g.:
  eq(command:match("CLI_BINARY") ~= nil, true)
end

-- Group 3: parse_response
-- Add cases that reflect the actual output format (plain text, JSON, event stream)
T["parse_response"] = new_set()

T["parse_response"]["should return trimmed response"] = function()
  -- Adjust the input and expected value to match the CLI's output format
  local result = child.lua_get([[Agent.parse_response("  expected output  ")]])
  eq(result, "expected output")
end

T["parse_response"]["should return nil for empty string"] = function()
  eq(child.lua_get([[Agent.parse_response("")]]), vim.NIL)
end

T["parse_response"]["should return nil for nil input"] = function()
  eq(child.lua_get([[Agent.parse_response(nil)]]), vim.NIL)
end

-- Group 4: ask (always mock io.popen — never call the real CLI in tests)
T["ask"] = new_set()

T["ask"]["should return parsed response from command"] = function()
  -- Set mock_output to a string the real CLI would produce
  child.lua([[
    local original_popen = io.popen
    io.popen = function()
      return {
        read  = function() return "MOCK_CLI_OUTPUT" end,
        close = function() end,
      }
    end
  ]])
  eq(child.lua_get([[Agent.ask("test prompt")]]), "EXPECTED_PARSED_VALUE")
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
        read  = function() return "" end,
        close = function() end,
      }
    end
  ]])
  eq(child.lua_get([[Agent.ask("test prompt")]]), vim.NIL)
  child.lua([[io.popen = original_popen]])
end

return T
```

---

## Step 7 — Verify

Run the test suite and confirm all tests pass before considering the task done:

```bash
make test
```

The output must show `Fails (0)` and every case for `test_AGENT_NAME_agent.lua` must show a green `o`.

---

## Summary Checklist

- [ ] `lua/askCode/agents/AGENT_NAME.lua` created with `setup`, `prepare_command`, `parse_response`, `ask`
- [ ] `lua/askCode/agents/init.lua` updated — agent registered in `M.agents`
- [ ] `.agents/summary/interfaces.md` updated — agent name added to config schema comment
- [ ] `tests/test_AGENT_NAME_agent.lua` created with all four test groups
- [ ] `make test` passes with zero failures

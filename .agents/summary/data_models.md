# Data Models — askCode.nvim

## Config

```lua
---@class Config
---@field agent        string   -- active agent key ("gemini"|"kiro"|"opencode")
---@field debug        boolean  -- enables debug logging (currently wired to utils.log)
---@field quit_key     string   -- keymap to close response window
---@field output_format string  -- currently unused
---@field window       WindowConfig
```

```lua
---@class WindowConfig
---@field type         string  -- "float"|"vertical"|"horizontal"
---@field width_ratio  number  -- fraction of screen width
---@field height_ratio number  -- fraction of screen height
---@field max_width    number  -- column cap
---@field max_height   number  -- row cap
```

## Conversation State

Module-local table in `init.lua`:

```lua
state = {
  history_file    = string|nil,  -- path to temp file; nil when no active conversation
  win_id          = number|nil,  -- nvim window handle
  buf_id          = number|nil,  -- nvim buffer handle
  display_content = string,      -- accumulated text shown in window
}
```

## History File Format

Plain text written to `vim.fn.tempname()`. Structure grows with each turn:

```
<initial system prompt + buffer context>

--- USER ---
<first question>

--- AGENT ---
<first response>

--- USER ---
<follow-up question>

--- AGENT ---
<follow-up response>
```

The entire file is re-sent as the prompt on every follow-up call.

## Selection Info

Passed from `ask_replace` to `utils.apply_replacement`:

```lua
selection_info = {
  bufnr      = number,  -- buffer handle
  start_line = number,  -- 1-based
  end_line   = number,  -- 1-based inclusive
}
```

## Agent Module Shape

```lua
---@class Agent
---@field config       table
---@field setup        function  -- (cfg: table)
---@field prepare_command function -- (prompt: string) → string
---@field parse_response  function -- (raw: string) → string|nil
---@field ask          function  -- (prompt: string) → string|nil
```

## Replacement Parse Result

Returned by `utils.parse_replacement_response`:

```lua
{
  replacement_content = string,  -- code inside <REPLACE>…</REPLACE>
  explanation         = string,  -- everything outside the tags
}
```

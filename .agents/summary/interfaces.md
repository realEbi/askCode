# Interfaces — askCode.nvim

## Public Lua API

```lua
require("askCode").setup(cfg?)           -- merge config
require("askCode").get_config(key?)      -- get value or full config
require("askCode").set_config(key, value) -- set value at runtime
```

## Neovim Commands

```vim
:AskCode [question]           " ask or follow-up (range supported)
:AskCodeReplace [request]     " replacement mode (visual range required)
:AskCodeConfig <key> [value]  " get or set config; tab-completes keys
```

## Configuration Schema

```lua
require("askCode").setup({
  agent        = "gemini",   -- "gemini" | "kiro" | "opencode"
  debug        = false,      -- enables vim.notify debug logs
  quit_key     = "q",        -- key to close response window
  output_format = "json",    -- currently unused
  window = {
    type         = "float",  -- "float" | "vertical" | "horizontal"
    width_ratio  = 0.7,
    height_ratio = 0.7,
    max_width    = 240,
    max_height   = 60,
  },
})
```

## Agent Interface Contract

Every agent module must export:

```lua
-- Returns a shell command string to run
function M.prepare_command(prompt: string) → string

-- Parses raw CLI output into clean text; returns nil on failure
function M.parse_response(raw: string) → string|nil
```

Optional (used in tests / direct calls):
```lua
function M.ask(prompt: string) → string|nil
function M.setup(cfg: table)
```

Register in `agents/init.lua`:
```lua
M.agents.myagent = require("askCode.agents.myagent")
```

Users then set `agent = "myagent"` in their config.

## Replacement Protocol

The AI must wrap replacement code in `<REPLACE>…</REPLACE>` tags:

```
Explanation text here.

<REPLACE>
-- replacement code
</REPLACE>
```

`utils.parse_replacement_response` extracts the block; `utils.apply_replacement` writes it back to the buffer using `vim.api.nvim_buf_set_lines`.

## Runner Interface

```lua
runner.run_command(
  cmd,        -- string[] e.g. {"sh", "-c", command}
  on_stdout,  -- function(job_id, data, event)
  {
    on_stderr       = fn,
    on_exit         = fn,
    stdout_buffered = bool,  -- default false
    stdin           = str,   -- default "null"
  }
)
```

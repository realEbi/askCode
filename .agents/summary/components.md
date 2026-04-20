# Components — askCode.nvim

## init.lua — Orchestrator

Public API and conversation state. Start here for any feature work.

| Function | Signature | Description |
|---|---|---|
| `setup` | `(cfg?)` | Merges user config with defaults |
| `get_config` | `(key?)` | Returns config value or full config |
| `set_config` | `(key, value)` | Sets config value at runtime |
| `ask` | `(question, mode)` | Starts a new conversation; closes any existing one |
| `follow_up` | `(question)` | Appends to active conversation |
| `ask_replace` | `(question, mode)` | Visual-mode only; shows editable replacement window |
| `ask_or_follow_up` | `(question, mode)` | Dispatches to `ask` or `follow_up` based on state |

**State** (module-local):
- `history_file` — path to temp file holding conversation history
- `win_id`, `buf_id` — current response window
- `display_content` — accumulated display text

## config.lua — Configuration

Dot-notation config system. All keys defined in `M.default`.

| Function | Description |
|---|---|
| `merge_with_default(changes)` | Deep-merges changes using `"keep"` strategy |
| `get(key?)` | Returns value at dot-path, or full config if nil |
| `set(key, value)` | Sets value; auto-converts strings to bool/number |
| `reset_config()` | Restores `M.current_config` to `M.default` |
| `get_all_keys()` | Returns all dot-separated keys (used for tab completion) |

## runner.lua — Job Execution

Thin wrapper around `vim.fn.jobstart`.

| Function | Signature | Description |
|---|---|
| `run_command` | `(cmd, on_stdout, opts?)` | Starts async job; `stdin` defaults to `"null"` |

`opts` fields: `on_stderr`, `on_exit`, `stdout_buffered`, `stdin`.

## ui.lua — Window Management

| Function | Signature | Description |
|---|---|
| `show_window` | `(content, on_close, editable?, on_apply?)` | Creates float/split; wires `q`/`Q` keymaps |
| `update_window` | `(win_id, buf_id, content, cursor_line?, replacement?)` | Replaces buffer content via `vim.schedule` |

Window type is read from `config.current_config.window.type` (`"float"`, `"vertical"`, `"horizontal"`).

## utils.lua — Utilities

| Function | Description |
|---|---|
| `log(msg)` | Emits `vim.notify` at DEBUG level when `config.debug` is true |
| `get_buffer_content(mode)` | Returns visual selection or full buffer as string |
| `read_file(path)` | Reads file to string |
| `write_file(path, content)` | Overwrites file |
| `append_file(path, content)` | Appends to file |
| `delete_file(path)` | Removes file |
| `parse_replacement_response(response)` | Extracts `<REPLACE>…</REPLACE>` block |
| `apply_replacement(content, selection_info)` | Writes lines back to buffer |

## agents/init.lua — Registry

Maps agent name strings to modules. Add new agents here.

```lua
M.agents = {
  gemini   = require("askCode.agents.gemini"),
  kiro     = require("askCode.agents.kiro"),
  opencode = require("askCode.agents.opencode"),
}
```

## agents/gemini.lua

| Function | Description |
|---|---|
| `prepare_command(prompt)` | `echo <shellescape(prompt)> \| gemini --output-format json` |
| `parse_response(json)` | Decodes JSON, returns `decoded.response` |

## agents/kiro.lua

| Function | Description |
|---|---|
| `prepare_command(prompt)` | `echo <shellescape(prompt)> \| kiro-cli chat --no-interactive 2>&1` |
| `parse_response(str)` | Strips ANSI codes, extracts content after `>` prompt indicator |

Note: kiro writes its response to stderr; `init.lua` wires `on_stderr` only for this agent.

## agents/opencode.lua

| Function | Description |
|---|---|
| `prepare_command(prompt)` | Writes prompt to temp file; runs `opencode run --format json "$(cat <tmpfile>)"` |
| `parse_response(str)` | Parses newline-delimited JSON events; concatenates all `"text"` type parts |

Uses temp file to avoid shell quoting issues with multiline prompts. `--format json` ensures the process exits cleanly.

## plugin/askCode.lua — Entry Point

Defines three user commands and two `<Plug>` keymaps:

| Command | Args | Description |
|---|---|---|
| `:AskCode` | `[question]` | Ask or follow up; prompts if no args |
| `:AskCodeReplace` | `[request]` | Replacement mode (visual only) |
| `:AskCodeConfig` | `<key> [value]` | Get or set config at runtime |

`<Plug>(AskCodeExplain)` and `<Plug>(AskCodeAddDocstring)` are pre-built prompt shortcuts.

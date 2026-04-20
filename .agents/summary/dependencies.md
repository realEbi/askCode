# Dependencies — askCode.nvim

## Runtime Dependencies

### Neovim API (no external Lua deps)

| API | Used in | Purpose |
|---|---|---|
| `vim.fn.jobstart` | runner.lua | Async process execution |
| `vim.fn.tempname` | init.lua, opencode.lua | Temp file paths |
| `vim.fn.shellescape` | gemini.lua, kiro.lua | Shell argument escaping |
| `vim.fn.json_decode` | gemini.lua, opencode.lua | JSON parsing |
| `vim.api.nvim_open_win` | ui.lua | Floating window creation |
| `vim.api.nvim_buf_set_lines` | ui.lua, utils.lua | Buffer content writes |
| `vim.api.nvim_buf_get_lines` | utils.lua | Buffer content reads |
| `vim.fn.getpos` | utils.lua | Visual selection boundaries |
| `vim.schedule` | ui.lua | Defer UI updates across async boundary |
| `vim.tbl_deep_extend` | config.lua, agents | Config/table merging |
| `vim.notify` | throughout | User-facing messages and debug logs |
| `vim.bo.filetype` | init.lua | Include filetype in prompt context |

### External CLI Tools (user must install)

| Agent key | Binary | Install |
|---|---|---|
| `gemini` | `gemini` | [gemini-cli](https://github.com/google-gemini/gemini-cli) |
| `kiro` | `kiro-cli` | [kiro.dev](https://kiro.dev) |
| `opencode` | `opencode` | [opencode.ai](https://opencode.ai) |

All binaries must be available in `$PATH` as seen by Neovim's environment (not just the shell profile).

## Test Dependencies

| Dependency | Source | Purpose |
|---|---|---|
| `mini.nvim` | cloned to `deps/mini.nvim` via `make deps/mini.nvim` | MiniTest framework |

Run `make deps/mini.nvim` before the first test run.

## CI

| Workflow | File | Trigger |
|---|---|---|
| LuaRocks publish | `.github/workflows/luarocks.yml` | Release |
| Changelog + GitHub release | `.github/workflows/release-please.yml` | Push to main |

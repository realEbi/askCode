# AGENTS.md — askCode.nvim

A navigation guide for AI agents working in this codebase.

## Directory Overview

```
lua/askCode/          ← all plugin logic lives here
├── init.lua          ← public API + conversation state (start here)
├── config.lua        ← dot-notation config system
├── runner.lua        ← thin vim.fn.jobstart wrapper
├── ui.lua            ← window/buffer creation and updates
├── utils.lua         ← file I/O, buffer reads, replacement parsing, debug log
└── agents/
    ├── init.lua      ← agent registry (maps name → module)
    ├── gemini.lua    ← Gemini CLI integration
    ├── kiro.lua      ← Kiro CLI integration
    ├── opencode.lua  ← OpenCode CLI integration
    └── claude.lua    ← Claude CLI integration
plugin/askCode.lua    ← Neovim commands + <Plug> keymaps (entry point)
tests/                ← MiniTest suite (one file per module)
scripts/minimal_init.lua  ← headless Neovim init used by make test
CODE-STANDARDS.md     ← authoritative coding standards and architecture
.agents/add-new-agent.md  ← step-by-step plan for adding a new agent
.claude/skills/add-agent/ ← Claude Code skill that automates adding a new agent
```

## Key Entry Points

- **Feature work**: start in `lua/askCode/init.lua` — it orchestrates all modules
- **Adding an agent**: follow `.agents/add-new-agent.md`, or invoke the `/add-agent` Claude Code skill — create `lua/askCode/agents/<name>.lua`, register in `agents/init.lua`
- **Config changes**: `lua/askCode/config.lua` — update `M.default` and annotations
- **UI changes**: `lua/askCode/ui.lua` — `show_window` and `update_window`
- **Commands/keymaps**: `plugin/askCode.lua`

## Agent Interface

Every agent module must implement:

```lua
function M.prepare_command(prompt) → string   -- shell command to run
function M.parse_response(raw_output) → string|nil  -- clean the CLI output
```

Register in `agents/init.lua`:
```lua
M.agents.myagent = require("askCode.agents.myagent")
```

Then users set `agent = "myagent"` in their config.

## Patterns That Deviate from Defaults

- **`stdout_buffered = true`** is passed to `runner.run_command` for all agent calls — responses are collected in full before `on_exit` fires, not streamed line-by-line.
- **`stdin = "null"`** is the default in `runner.run_command` — prevents interactive CLIs from blocking on stdin.
- **`on_stderr` is only wired for the `kiro` agent** in `M.ask` — Kiro writes its response to stderr, not stdout. Note: `follow_up` and `ask_replace` do not wire `on_stderr`, so kiro follow-ups are currently broken.
- **UI updates use `vim.schedule()`** — all `update_window` calls are deferred to avoid crossing the async boundary unsafely.
- **Conversation history is a temp file**, not in-memory — `vim.fn.tempname()` path stored in `state.history_file`; full history is re-read and re-sent on every follow-up.
- **Config merging uses `"keep"` strategy** — `vim.tbl_deep_extend("keep", changes, current)` means user values win over defaults, not the other way around.
- **`opencode` agent uses a temp file for the prompt** — multiline prompts can't be safely passed via `shellescape` through `sh -c`; the agent writes the prompt to a temp file and uses `"$(cat <tmpfile>)"` in the command. It also requires `--format json` so the process exits cleanly.
- **`claude` agent uses a temp file for the prompt** — same rationale as opencode; the prompt is written to a temp file and passed to `claude -p "$(cat <tmpfile>)"`. The `-p` flag makes Claude CLI non-interactive and outputs plain text, so `parse_response` only trims whitespace with no JSON parsing.

## Repo-Specific Tools

- `make test` — runs the full test suite via headless Neovim
- `make test_file FILE=tests/test_foo.lua` — runs a single test file
- `make deps/mini.nvim` — clones mini.nvim into `deps/` (required before first test run)

## CI

- `.github/workflows/luarocks.yml` — publishes to LuaRocks on release
- `.github/workflows/release-please.yml` — automates changelog and GitHub releases

## Testing Conventions

Tests use `MiniTest.new_child_neovim()` — each test case restarts a fresh child Neovim process. See `.agents/summary/writing-unit-tests.md` for the full pattern. Key points:
- `pre_case` hook must call `child.restart({ "-u", "scripts/minimal_init.lua" })`
- Use `child.lua()` to execute, `child.lua_get()` to retrieve values
- Mock `io.popen` to avoid real CLI calls in agent tests

## Known Gaps (from review)

- `kiro.lua` internal comments and `vim.notify` strings still reference "AmazonQ" — cosmetic but misleading.
- `on_stderr` is not wired in `follow_up` or `ask_replace` — kiro agent follow-ups and replacements silently return empty responses.
- `output_format` config field exists in the schema but has no effect anywhere.
- `vim.g.askcode_range` is set in `plugin/askCode.lua` for `AskCodeReplace` but never read — dead code.
- `debug` logging only covers `init.lua`; agents and ui emit no debug output.

## Adding a New Agent

Use the `/add-agent` Claude Code skill to add a new agent in one step:

```
/add-agent <agent_name> <cli_invocation>
```

Example:

```
/add-agent claude "claude -p"
```

The skill reads the full implementation plan from `.agents/add-new-agent.md` and executes all steps automatically: creates the agent module, registers it, updates docs, writes unit tests, and verifies with `make test`.

To add an agent manually without the skill, follow `.agents/add-new-agent.md` step by step.

## Detailed Documentation

Full documentation is in `.agents/summary/`:
- `index.md` — navigation guide with per-file summaries
- `architecture.md` — layer diagrams and state machine
- `components.md` — per-module function reference
- `interfaces.md` — API contracts and config schema
- `data_models.md` — data structure definitions
- `workflows.md` — end-to-end sequence diagrams
- `dependencies.md` — Neovim API usage and external requirements

## Custom Instructions

<!-- This section is for human and agent-maintained operational knowledge.
     Add repo-specific conventions, gotchas, and workflow rules here.
     This section is preserved exactly as-is when re-running codebase-summary. -->

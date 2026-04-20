# Codebase Info — askCode.nvim

## Project Overview

A Neovim plugin that connects to CLI-based AI assistants (Gemini, Kiro, OpenCode) and lets users ask context-aware questions about selected code from within the editor. Responses appear in floating windows or splits, asynchronously.

## Technology Stack

- **Language**: Lua (Neovim plugin API)
- **Runtime**: Neovim ≥ 0.9.0
- **Test framework**: mini.nvim (MiniTest)
- **CI**: GitHub Actions (LuaRocks publish, release-please)

## Directory Layout

```
lua/askCode/          ← all plugin logic
├── init.lua          ← public API + conversation state
├── config.lua        ← dot-notation config system
├── runner.lua        ← vim.fn.jobstart wrapper
├── ui.lua            ← window/buffer management
├── utils.lua         ← file I/O, buffer reads, replacement parsing, debug log
└── agents/
    ├── init.lua      ← agent registry
    ├── gemini.lua    ← Gemini CLI integration
    ├── kiro.lua      ← Kiro CLI integration
    └── opencode.lua  ← OpenCode CLI integration
plugin/askCode.lua    ← Neovim commands + <Plug> keymaps (entry point)
tests/                ← MiniTest suite (one file per module)
scripts/minimal_init.lua  ← headless Neovim init for tests
.agents/summary/      ← AI agent documentation
CODE-STANDARDS.md     ← coding standards and architecture reference
```

## Supported Agents

| Key | CLI binary | Transport |
|---|---|---|
| `gemini` | `gemini` | stdin pipe, JSON output |
| `kiro` | `kiro-cli` | stdin pipe, stderr output |
| `opencode` | `opencode` | temp file arg, `--format json` |

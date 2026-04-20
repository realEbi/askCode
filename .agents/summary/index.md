# Documentation Index — askCode.nvim

## Instructions for AI Assistants

This index is the primary entry point for understanding the askCode.nvim codebase. Use it to locate the right file before diving into source code.

**How to use this index:**
1. Read the file summaries below to identify which document answers your question.
2. Load only the relevant file(s) into context — you do not need all files at once.
3. For source-level questions, cross-reference with the actual files in `lua/askCode/`.

---

## Table of Contents

| File | Purpose | Consult When... |
|---|---|---|
| [codebase_info.md](codebase_info.md) | Project overview, directory layout, tech stack, supported agents | You need a high-level orientation or want to know what files exist |
| [architecture.md](architecture.md) | Layer diagram, module relationships, state machine, key design decisions | You need to understand how modules connect or why certain patterns are used |
| [components.md](components.md) | Per-module responsibilities, function signatures | You need to know what a specific module does or what functions it exposes |
| [interfaces.md](interfaces.md) | Public Lua API, Neovim commands, agent contract, config schema, replacement protocol | You need to call the plugin programmatically or add a new agent |
| [data_models.md](data_models.md) | Config, conversation state, history file format, selection info, agent module shape | You need to understand data structures passed between modules |
| [workflows.md](workflows.md) | Sequence diagrams for ask, follow-up, replacement, config change, adding agents | You need to trace a user action end-to-end or understand async flow |
| [dependencies.md](dependencies.md) | Neovim API usage, external CLI requirements, test deps, CI | You need to know what APIs are used or what the user must install |
| [writing-unit-tests.md](writing-unit-tests.md) | MiniTest conventions, boilerplate, mocking guide | You need to write or understand a test |

---

## Quick Reference

**"How does a question get sent to the AI?"**
→ See `workflows.md` § New Conversation, then `components.md` § runner / agents

**"How do I add a new AI agent?"**
→ See `interfaces.md` § Agent Interface Contract + `workflows.md` § Adding a New Agent

**"What config options exist?"**
→ See `interfaces.md` § Configuration Schema or `data_models.md` § Config

**"How does code replacement work?"**
→ See `workflows.md` § Code Replacement + `interfaces.md` § Replacement Protocol

**"What Neovim APIs does this plugin use?"**
→ See `dependencies.md` § Runtime Dependencies

**"How are tests structured?"**
→ See `writing-unit-tests.md`

---

## Codebase at a Glance

```
lua/askCode/
├── init.lua        ← start here for any feature work
├── config.lua      ← all config logic
├── runner.lua      ← async job execution
├── ui.lua          ← window/buffer management
├── utils.lua       ← file I/O, replacement parsing, debug log
└── agents/
    ├── init.lua    ← agent registry
    ├── gemini.lua  ← Gemini CLI integration
    ├── kiro.lua    ← Kiro CLI integration
    └── opencode.lua ← OpenCode CLI integration
plugin/askCode.lua  ← Neovim commands + keymaps (entry point)
tests/              ← MiniTest suite
```

The plugin has no runtime Lua dependencies beyond Neovim itself. External AI CLIs must be installed and available in `$PATH`.

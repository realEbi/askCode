# Architecture — askCode.nvim

## Layer Diagram

```mermaid
graph TD
    A["plugin/askCode.lua<br/>(Neovim commands + keymaps)"]
    B["lua/askCode/init.lua<br/>(orchestrator + state)"]
    C["lua/askCode/config.lua"]
    D["lua/askCode/ui.lua"]
    E["lua/askCode/runner.lua"]
    F["lua/askCode/utils.lua"]
    G["lua/askCode/agents/init.lua<br/>(registry)"]
    H["agents/gemini.lua"]
    I["agents/kiro.lua"]
    J["agents/opencode.lua"]

    A --> B
    B --> C
    B --> D
    B --> E
    B --> F
    B --> G
    G --> H
    G --> I
    G --> J
```

## Module Responsibilities

| Module | Role |
|---|---|
| `plugin/askCode.lua` | Defines `:AskCode`, `:AskCodeReplace`, `:AskCodeConfig` commands and `<Plug>` keymaps |
| `init.lua` | Holds conversation `state`, builds prompts, wires async callbacks |
| `config.lua` | Stores and merges config; exposes dot-notation get/set |
| `ui.lua` | Creates float/split windows, handles `q`/`Q` keymaps |
| `runner.lua` | Thin `vim.fn.jobstart` wrapper with `stdin = "null"` default |
| `utils.lua` | File I/O, buffer reads, replacement parsing, debug logging |
| `agents/*` | Each agent implements `prepare_command` + `parse_response` |

## Conversation State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : AskCode (new)
    Loading --> Displaying : on_exit fires
    Displaying --> Loading : AskCode (follow-up)
    Displaying --> Idle : q (close window)
    Idle --> Replacing : AskCodeReplace
    Replacing --> Idle : q (cancel)
    Replacing --> Idle : Q (apply)
```

## Key Design Decisions

- **Async via jobstart**: all CLI calls use `vim.fn.jobstart` with `stdout_buffered = true`; `on_exit` delivers the full response at once.
- **`stdin = "null"`**: runner sets stdin to `/dev/null` by default so interactive CLIs don't block waiting for input.
- **History as temp file**: conversation history is written to `vim.fn.tempname()` and re-sent in full on every follow-up, keeping state simple.
- **`vim.schedule()` for UI**: all `update_window` calls are deferred to avoid crossing the async boundary.
- **Config merging with `"keep"`**: `vim.tbl_deep_extend("keep", changes, current)` — user-supplied values always win over defaults.

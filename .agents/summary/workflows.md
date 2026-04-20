# Workflows — askCode.nvim

## New Conversation (`:AskCode`)

```mermaid
sequenceDiagram
    actor User
    participant plugin as plugin/askCode.lua
    participant init as init.lua
    participant agent as agents/<name>.lua
    participant runner as runner.lua
    participant ui as ui.lua

    User->>plugin: :AskCode "question" (visual selection)
    plugin->>init: ask_or_follow_up(question, mode)
    init->>init: close existing window + delete history file
    init->>init: write prompt to new history_file (tempname)
    init->>agent: prepare_command(full_prompt)
    agent-->>init: shell command string
    init->>ui: show_window("Loading...")
    init->>runner: run_command(cmd, on_stdout, {stdout_buffered=true})
    runner->>runner: jobstart with stdin="null"
    Note over runner: process runs async
    runner-->>init: on_exit fires
    init->>agent: parse_response(raw)
    agent-->>init: cleaned text
    init->>init: append response to history_file
    init->>ui: update_window(content) via vim.schedule
```

## Follow-up Question

```mermaid
sequenceDiagram
    actor User
    participant init as init.lua
    participant agent as agents/<name>.lua
    participant runner as runner.lua
    participant ui as ui.lua

    User->>init: ask_or_follow_up(question, mode)
    Note over init: history_file exists + window valid → follow_up
    init->>init: append "--- USER ---\nquestion" to history_file
    init->>init: read full history_file
    init->>agent: prepare_command(full_history)
    agent-->>init: shell command string
    init->>runner: run_command(cmd, on_stdout)
    runner-->>init: on_exit fires
    init->>agent: parse_response(raw)
    init->>init: append response to history_file
    init->>ui: update_window(display_content, cursor_position)
```

## Code Replacement (`:AskCodeReplace`)

```mermaid
sequenceDiagram
    actor User
    participant plugin as plugin/askCode.lua
    participant init as init.lua
    participant agent as agents/<name>.lua
    participant runner as runner.lua
    participant ui as ui.lua
    participant utils as utils.lua

    User->>plugin: :AskCodeReplace "request" (visual)
    plugin->>init: ask_replace(question, mode)
    init->>init: capture selection_info (bufnr, start_line, end_line)
    init->>agent: prepare_command(prompt with <REPLACE> instruction)
    init->>ui: show_window(editable=true, on_apply=fn)
    init->>runner: run_command(cmd, on_stdout)
    runner-->>init: on_exit fires
    init->>agent: parse_response(raw)
    init->>ui: update_window(content, replacement=true)
    User->>ui: press Q (apply)
    ui->>utils: parse_replacement_response(edited_content)
    utils-->>ui: {replacement_content, explanation}
    ui->>utils: apply_replacement(content, selection_info)
    utils->>utils: nvim_buf_set_lines
```

## Adding a New Agent

```mermaid
flowchart TD
    A[Create lua/askCode/agents/myagent.lua] --> B[Implement prepare_command]
    B --> C[Implement parse_response]
    C --> D[Register in agents/init.lua]
    D --> E[Add test file tests/test_myagent.lua]
    E --> F[User sets agent = myagent in config]
```

## Config Change at Runtime

```
:AskCodeConfig agent opencode
  → plugin/askCode.lua parses args
  → init.set_config("agent", "opencode")
  → config.set() builds nested table, calls merge_with_default
  → config.current_config updated immediately
  → next :AskCode call uses new agent
```

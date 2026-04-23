---
name: add-agent
description: Add a new AI CLI agent to the askCode.nvim plugin. Implements the full agent contract (prepare_command, parse_response, ask), registers it in the agent registry, updates documentation, and writes a complete MiniTest unit test suite. Invoke with the agent name and its non-interactive CLI invocation pattern.
argument-hint: <agent_name> <cli_invocation>
arguments: [agent_name, cli_invocation]
allowed-tools: Read Glob Grep Write Edit Bash(make test)
---

# Task: Add a New Agent to askCode.nvim

You are implementing a new agent named **`$agent_name`** whose CLI is invoked as:

```
$cli_invocation
```

Follow the implementation plan in `.agents/add-new-agent.md` exactly. The relevant source files are:

- `lua/askCode/agents/` — existing agents to use as reference
- `lua/askCode/agents/init.lua` — agent registry (must be updated)
- `.agents/summary/interfaces.md` — config schema docs (must be updated)
- `tests/` — existing test files to use as reference

## Current agent registry
```!
cat lua/askCode/agents/init.lua
```

## Execution steps

Work through these steps in order. Do not skip any.

**Step 1 — Analyse the CLI output format.**
Determine whether `$cli_invocation` produces plain text, a single JSON object, or a JSON event stream. Use that to select the correct `parse_response` strategy from the plan.

**Step 2 — Determine the prompt input method.**
If the CLI reads the prompt from a flag argument (e.g. `-p "..."`) or if prompts can contain code with newlines, use the tempfile method. If the CLI reads from stdin, use the shellescape+pipe method.

**Step 3 — Create `lua/askCode/agents/$agent_name.lua`.**
Implement all four exports: `setup`, `prepare_command`, `parse_response`, `ask`. Use the chosen strategies from Steps 1 and 2.

**Step 4 — Register the agent.**
Add `$agent_name = require("askCode.agents.$agent_name")` to the `M.agents` table in `lua/askCode/agents/init.lua`.

**Step 5 — Update documentation.**
In `.agents/summary/interfaces.md`, append `| "$agent_name"` to the `agent` config comment line.

**Step 6 — Write unit tests.**
Create `tests/test_$agent_name_agent.lua` with all four test groups: `setup`, `prepare_command`, `parse_response`, `ask`. Mock `io.popen` in all `ask` tests. The mock output for the success case must be a string that the real CLI would produce, and the expected parsed value must match what `parse_response` returns for that input.

**Step 7 — Verify.**
Run `make test` and confirm the output shows `Fails (0)` and all cases for `test_$agent_name_agent.lua` are green. If any test fails, fix the implementation before finishing.

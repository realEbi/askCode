# Review Notes — askCode.nvim

## Inconsistencies Found

### kiro.lua internal comments still say "AmazonQ"
- `kiro.lua` docstrings and `vim.notify` messages reference "AmazonQ" (e.g. `"Empty response from AmazonQ"`, `"Failed to execute amazonq command"`).
- The agent was renamed to `kiro` but the internal strings were not updated.
- **Fix**: update all string literals in `kiro.lua` to say "Kiro".

### `debug` and `output_format` config fields have no effect
- Both fields exist in `config.M.default` and the schema annotation, but neither is consumed anywhere in the runtime code.
- `debug` is now partially wired — `utils.log` checks it — but only `init.lua` calls `utils.log`; agents and ui do not.
- `output_format` is completely unused.
- **Fix**: either implement or remove these fields to avoid misleading users.

### `vim.g.askcode_range` is dead code
- `plugin/askCode.lua` sets `vim.g.askcode_range` in the `AskCodeReplace` handler, but nothing reads it.
- `ask_replace` in `init.lua` reads selection boundaries directly via `vim.fn.getpos`.
- **Fix**: remove the `vim.g.askcode_range` assignment.

### `on_stderr` only wired in `M.ask`, not in `M.follow_up` or `M.ask_replace`
- The kiro agent writes its response to stderr, but `follow_up` and `ask_replace` don't wire `on_stderr`.
- This means follow-up questions and replacements silently produce empty responses when using the kiro agent.
- **Fix**: add `on_stderr` handler (mirroring `M.ask`) to both `follow_up` and `ask_replace`.

## Completeness Gaps

### No test for `init.lua` async flows with kiro agent
- `test_ask_code.lua` exists but likely doesn't cover the kiro stderr path for follow-up/replace.

### No test for `opencode` temp file cleanup
- `opencode.prepare_command` creates a temp file and appends `rm -f <tmpfile>` to the shell command. There is no test verifying the cleanup happens or that the file path is correctly embedded.

### `utils.log` not called in agents or ui
- Debug logging is only in `init.lua`. Agents and ui produce no debug output, making it harder to trace issues inside those modules.

## Recommendations

1. Update `kiro.lua` string literals to remove "AmazonQ" references.
2. Wire `on_stderr` for kiro in `follow_up` and `ask_replace`.
3. Remove `vim.g.askcode_range` dead code.
4. Either implement `output_format` or remove it from the config schema.
5. Add `utils.log` calls to agent `prepare_command` and `parse_response` for better debug traceability.

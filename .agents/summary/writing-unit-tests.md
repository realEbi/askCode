# AI Agent Guide: Writing Unit Tests

This guide outlines the rules and conventions for writing unit tests for `askCode.nvim`. The goal is to maintain consistency and ensure tests are robust and isolated.

## 1. Testing Framework

The project uses [mini.nvim's test framework](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md). All new tests must be written using this framework.

## 2. File and Test Naming

- Test files must be placed in the `tests/` directory.
- Test filenames must be prefixed with `test_`, for example `tests/test_utils.lua`.
- Test sets should be named descriptively, reflecting the module or functionality they cover.

## 3. Test Structure and Boilerplate

Every test file should follow a standard structure using a child Neovim process to ensure isolation.

```lua
-- tests/test_your_feature.lua
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create an isolated Neovim instance for testing
local child = MiniTest.new_child_neovim()

-- Define the main test set for this file
local T = new_set({
  hooks = {
    -- Before each test case, restart Neovim with a minimal config
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load the plugin or module you are testing
      child.lua([[M = require('askCode.your_module')]])
    end,
    -- After all tests in this set are done, stop the child process
    post_once = child.stop,
  },
})

-- Define a nested test set for a specific function or feature
T["your_function"] = new_set()

-- Define a test case
T["your_function"]["should do something correctly"] = function()
  -- 1. Execute code in the child Neovim instance
  local result = child.lua_get([[M.your_function('some_input')]])

  -- 2. Assert the expected outcome
  eq(result, "expected_output")
end

return T
```

## 4. Key Principles

- **Isolation**: Always use the `child` Neovim process (`MiniTest.new_child_neovim`) to run tests. This prevents the host Neovim environment from affecting test results. The `pre_case` hook is mandatory for restarting the child process.
- **Assertions**: Use `MiniTest.expect` for assertions. `eq` (`MiniTest.expect.equality`) is preferred for comparing values.
- **Interaction**: Use `child.lua("...")` to execute commands and `child.lua_get("...")` to retrieve values from the child process.

## 5. Mocking External Dependencies

For unit tests, it is crucial to mock functions with external dependencies (e.g., shell commands, file system access, network requests) to ensure tests are fast, deterministic, and don't have side effects.

To test a function that calls an external command (like `gemini.ask`), you must mock the underlying system call (`io.popen`).

### Example: Mocking `io.popen` for `gemini.ask`

```lua
-- In your test case for the gemini agent
T["ask"]["should return mocked output"] = function()
  -- Mock io.popen to avoid running the actual 'gemini' command
  child.lua([[
    -- Store the original io.popen
    local original_popen = io.popen

    -- Create a mock function
    io.popen = function(command)
      -- Assert that the correct command is being called
      assert(command == 'echo "test prompt" | gemini')

      -- Return a mock file handle with a read method
      return {
        read = function() return "mocked gemini response" end,
        close = function() end,
      }
    end
  ]])

  -- Load the agent module *after* the mock is in place
  child.lua([[Agent = require('askCode.agents.gemini')]])

  -- Run the function that uses the mocked dependency
  local response = child.lua_get([[Agent.ask('test prompt')]])

  -- Assert that the function returned the mocked response
  eq(response, "mocked gemini response")

  -- (Optional but good practice) Restore the original function
  child.lua([[io.popen = original_popen]])
end
```

By following these rules, you will create tests that are consistent with the existing test suite and effectively verify the plugin's functionality.

You can run `make test` command to run the test

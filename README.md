# AskCode.nvim

AskCode is a Neovim plugin that helps developers explore and understand codebases by connecting to CLI-based AI assistants like `gemini-cli`, `kiro-cli`, and `opencode`. It acts as your in-editor guide, letting you ask context-aware questions about selected code and receive answers without leaving Neovim.

![Image](https://github.com/user-attachments/assets/e5f0dadb-9bdc-4b43-8c77-15a11810a3da)

✨ **Features**

- **Multi-agent support**: Choose your preferred AI backend (Gemini, Kiro, OpenCode, etc.).
- **Configurable**: Select agents and tweak settings via a simple Lua API.
- **Prepared prompts**: Built-in use cases like explaining code, finding bugs, or suggesting optimizations.
- **Code replacement**: Select code and ask AI to modify it directly in your buffer (add docstrings, fix bugs, refactor, etc.).
- **Extensible**: Add your own agents and custom prompts.
- **Neovim-native UI**: Responses are displayed in floating windows or splits, asynchronously and non-blockingly.

## 🚀 Getting Started

### Prerequisites

- Neovim (v0.9.0 or later)
- A compatible AI assistant CLI installed and configured in your shell environment (e.g., `gemini-cli`, `kiro-cli`, `opencode`).

### Supported Agents

| Agent key  | CLI                                                         | Notes                     |
| ---------- | ----------------------------------------------------------- | ------------------------- |
| `gemini`   | [`gemini-cli`](https://github.com/google-gemini/gemini-cli) | Default agent             |
| `kiro`     | [`kiro-cli`](https://kiro.dev)                              | Reads from stderr         |
| `opencode` | [`opencode`](https://opencode.ai)                           | Uses `--format json` mode |

### Installation

Install `askCode.nvim` using your favorite package manager.

**Lazy.nvim**

```lua
{
  "realEbi/askCode",
  config = function()
    require("askCode").setup({
      -- Your configuration here
    })
  end,
}
```

**Packer.nvim**

```lua
use {
  "realEbi/askCode",
  config = function()
    require("askCode").setup({
      -- Your configuration here
    })
  end,
}
```

### Basic Configuration

By default, `askCode.nvim` uses `gemini-cli`. You can configure it to use a different agent or customize its behavior.

```lua
require("askCode").setup({
  agent = "gemini",        -- AI agent to use (default: "gemini")
  debug = false,           -- Enable debug mode (default: false)
  quit_key = "q",          -- Key to quit floating windows (default: "q")
  output_format = "json",  -- Output format (default: "json")
  window = {               -- Configuration for the display window
    type = "float",        -- Type of window: "float", "vertical", or "horizontal" (default: "float")
    width_ratio = 0.7,     -- Window width as ratio of screen width (default: 0.7)
    height_ratio = 0.7,    -- Window height as ratio of screen height (default: 0.7)
    max_width = 240,       -- Maximum window width in columns (default: 240)
    max_height = 60,       -- Maximum window height in rows (default: 60)
  },
})
```

## Usage

### Asking Questions

1.  **Select code**: Select a block of code in visual mode.
2.  **Ask initial question**: Use the `:AskCode <question>` command (e.g., `:AskCode "Explain this code"`).
3.  **Ask follow-up questions**: Use `:AskCode <follow_up_question>` again to continue the conversation in the same window.
4.  **View responses**: AI-generated responses appear in a floating window, with conversation history maintained.

The `:AskCode` command automatically detects whether to start a new conversation or continue an existing one.

### Code Replacement

1.  **Select code**: Select a block of code in visual mode.
2.  **Request replacement**: Use the `:AskCodeReplace <request>` command (e.g., `:AskCodeReplace "Add docstring to this function"`).
3.  **Review changes**: The AI response appears in an editable floating window.
4.  **Apply or cancel**: Press `Q` to apply the replacement to your buffer, or `q` to cancel.

**Note**: Code replacement only works in visual mode with selected text.

### Configuration Management

You can get and set configuration values at runtime using the `:AskCodeConfig` command:

**Get a configuration value:**

```vim
:AskCodeConfig agent
:AskCodeConfig window.type
```

**Set a configuration value:**

```vim
:AskCodeConfig agent kiro
:AskCodeConfig window.type vertical
:AskCodeConfig window.width_ratio 0.8
:AskCodeConfig debug true
```

The command supports tab completion for all available configuration keys. Values are automatically converted to the appropriate type (booleans, numbers, strings).

**Programmatic access:**

```lua
-- Get config
local agent = require("askCode").get_config("agent")
local all_config = require("askCode").get_config()

-- Set config
require("askCode").set_config("window.type", "horizontal")
```

### Keybinding Examples

You can map the commands to keybindings for easier access:

```lua
-- Ask questions about code
vim.keymap.set("v", "<leader>ae", ":AskCode <Plug>(AskCodeExplain)")
vim.keymap.set("v", "<leader>ab", ":AskCode \"Find potential bugs\"<CR>")

-- Code replacement shortcuts
vim.keymap.set("v", "<leader>ae", ":AskCode <Plug>(AskCodeAddDocstring)")
vim.keymap.set("v", "<leader>ar", ":AskCodeReplace \"Refactor this code\"<CR>", { noremap = true, silent = true })
```

## Development

Contributions are welcome! To get started with development:

1.  **Clone the repository**:

    ```sh
    git clone https://github.com/realEbi/askCode.git askCode.nvim
    cd askCode.nvim
    ```

2.  **Set up the development environment**:

    The plugin uses `mini.nvim` for its test framework. The tests can be run using the `make test` command.

3.  **Run the tests**:

    ```sh
    make test
    ```

    This command will run the test suite and ensure that everything is working as expected.

### Test Framework

The project uses `mini.nvim` for its testing framework. You can find more information about it in the [mini.nvim TESTING.md](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md) file.

## Similar Projects

- [gen.nvim](https://github.com/David-Kunz/gen.nvim)

## Todo

- [ ] **Support Prompt Templates**: Allow users to define custom prompt templates in the configuration.
- [ ] **Integrate Claude-Code Agent**: Add a new agent for ClaudeCode by implementing the `prepare_command` function for its CLI.
- [ ] **Support Streaming JSON**: Improve the stream processor to parse chunked JSON responses for real-time display.
- [x] **Support Follow-up Questions**: Maintain conversation history to allow for follow-up questions.
- [x] **Integrate Kiro Agent**: Add a new agent for Kiro by implementing the `prepare_command` function for its CLI.
- [x] **Support Text Replacement Actions**: Enable agent to perform text replacements or modifications (e.g., adding function docstrings, refactoring code) directly in the buffer instead of just displaying responses.

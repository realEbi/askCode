local M = {}

---@class Agent
---@field prepare_command function
---@field parse_response function

M.agents = {
  gemini = require("askCode.agents.gemini"),
  kiro = require("askCode.agents.kiro"),
  opencode = require("askCode.agents.opencode"),
  claude = require("askCode.agents.claude"),
}

---@param name string The name of the agent to get.
---@return Agent? The agent module.
function M.get_agent(name)
  return M.agents[name]
end

return M

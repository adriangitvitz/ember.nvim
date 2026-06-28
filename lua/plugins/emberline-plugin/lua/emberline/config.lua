-- Configuration for emberline
local M = {}

--- Default configuration
M.defaults = {
  enabled = true,

  -- Icons and indicators (text-only per user preference)
  icons = {
    filetype = false, -- No filetype icons
    modified = "[+]", -- Modified indicator
    pinned = "", -- Pinned indicator
    close = "×", -- Close button
  },

  -- Separators
  separator = {
    left = "▎", -- Left separator
    right = "", -- Right separator (optional)
  },

  -- Display options
  max_name_length = 25, -- Truncate long names
  padding = 1, -- Padding on each side of buffer name
  clickable = true, -- Enable mouse support

  -- Jump mode
  jump_letters = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP",

  -- Behavior
  focus_on_close = "left", -- Focus left/right/previous on close

  -- Sidebar integration
  sidebar_filetypes = { "NvimTree", "neo-tree", "undotree", "netrw" },

  -- Highlight groups (can be customized)
  highlights = {
    current = "EmberlineCurrent",
    current_mod = "EmberlineCurrentMod",
    current_pin = "EmberlineCurrentPin",
    visible = "EmberlineVisible",
    visible_mod = "EmberlineVisibleMod",
    visible_pin = "EmberlineVisiblePin",
    inactive = "EmberlineInactive",
    inactive_mod = "EmberlineInactiveMod",
    inactive_pin = "EmberlineInactivePin",
    separator = "EmberlineSeparator",
    close = "EmberlineClose",
    fill = "EmberlineFill",
    jump = "EmberlineJump",
  },
}

--- Current configuration
M.options = {}

--- Setup configuration
---@param user_config table|nil User configuration
function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

--- Get current configuration
---@return table Configuration
function M.get()
  if vim.tbl_isempty(M.options) then
    M.setup({})
  end
  return M.options
end

--- Get a specific configuration value
---@param key string Dot-notation key (e.g., "icons.modified")
---@return any Value
function M.get_value(key)
  local config = M.get()
  local parts = vim.split(key, ".", { plain = true })
  local value = config

  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[part]
  end

  return value
end

return M

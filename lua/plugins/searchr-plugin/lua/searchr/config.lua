-- searchr/config.lua - Configuration management

local M = {}

M.defaults = {
  -- Ripgrep path
  rg_path = "rg",

  -- UI settings
  ui = {
    mode = "split",       -- "split" | "float" | "vsplit"
    height = 0.4,         -- For split mode (proportion)
    width = 0.8,          -- For float mode (proportion)
    border = "rounded",   -- Float border style
    position = "bottom",  -- "bottom" | "top" for split
  },

  -- Search behavior
  search = {
    case_mode = "smart",      -- "smart" | "sensitive" | "insensitive"
    use_regex = false,        -- Default to literal search
    include_hidden = false,
    follow_symlinks = false,
    max_results = 10000,
    context_lines = 0,
  },

  -- Progressive debounce
  debounce = {
    enabled = true,
    thresholds = {
      { len = 2, delay = 0 },     -- Instant for 1-2 chars
      { len = 4, delay = 50 },    -- 50ms for 3-4 chars
      { len = 8, delay = 100 },   -- 100ms for 5-8 chars
      { default = 150 },          -- 150ms max
    },
  },

  -- Replace settings
  replace = {
    confirm = true,
    preview_inline = true,
  },

  -- Keymaps (set to false to disable)
  keymaps = {
    open = "<leader>sr",
    open_word = "<leader>sw",
  },

  -- Integration
  integration = {
    picker = true,
    quickfix = true,
  },

  -- Highlights (link to existing groups)
  highlights = {
    match = "Search",
    replace = "DiffAdd",
    delete = "DiffDelete",
    path = "Directory",
    line_nr = "LineNr",
    status = "Comment",
    border = "FloatBorder",
    input_label = "Identifier",
  },
}

-- Current config (merged with user config)
M.config = {}

-- Setup config with user overrides
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", {}, M.defaults, user_config or {})
  return M.config
end

-- Get current config
function M.get()
  if vim.tbl_isempty(M.config) then
    return M.defaults
  end
  return M.config
end

-- Get debounce delay based on pattern length
function M.get_debounce_delay(pattern_len)
  local cfg = M.get()
  if not cfg.debounce.enabled then
    return 0
  end

  for _, threshold in ipairs(cfg.debounce.thresholds) do
    if threshold.len and pattern_len <= threshold.len then
      return threshold.delay
    end
    if threshold.default then
      return threshold.default
    end
  end

  return 150 -- Fallback
end

return M

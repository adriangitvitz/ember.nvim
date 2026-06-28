-- Highlight groups for emberline
local M = {}

-- Store colors for separator highlights
M.colors = {}

--- Create highlight groups with sensible defaults
function M.setup()
  local config = require("emberline.config").get()

  -- Get colors from existing highlight groups
  local function get_hl(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl then
      return hl
    end
    return {}
  end

  local normal = get_hl("Normal")

  -- Midnight-ember inspired colors (with fallbacks)
  local colors = {
    bg = "#222831",           -- Main background
    bg_dark = "#1B262C",      -- Fill/darker background
    bg_light = "#393E46",     -- Active buffer background
    bg_medium = "#313131",    -- Inactive buffer background
    fg = "#c1c1c1",           -- Normal text
    fg_bright = "#ECDBBA",    -- Bright text for active
    fg_dim = "#8a8a8a",       -- Dimmed text for inactive
    amber = "#e9bd47",        -- Accent color (modified indicator)
    amber_deep = "#efaf56",   -- Pin indicator
    green = "#88c4a8",        -- Success/visible indicator
  }

  -- Try to get colors from colorscheme
  local tabline_fill = get_hl("TabLineFill")
  local tabline_sel = get_hl("TabLineSel")
  if tabline_fill.bg then colors.bg_dark = string.format("#%06x", tabline_fill.bg) end
  if tabline_sel.bg then colors.bg_light = string.format("#%06x", tabline_sel.bg) end
  if normal.bg then colors.bg = string.format("#%06x", normal.bg) end

  -- Store colors for use in render
  M.colors = colors

  -- Set highlight groups
  local highlights = {
    -- Current buffer (active) - bright and prominent
    EmberlineCurrent = { fg = colors.fg_bright, bg = colors.bg_light, bold = true },
    EmberlineCurrentMod = { fg = colors.amber, bg = colors.bg_light, bold = true },
    EmberlineCurrentPin = { fg = colors.amber_deep, bg = colors.bg_light, bold = true },

    -- Visible buffer (in window but not current)
    EmberlineVisible = { fg = colors.fg, bg = colors.bg_medium },
    EmberlineVisibleMod = { fg = colors.amber, bg = colors.bg_medium },
    EmberlineVisiblePin = { fg = colors.amber_deep, bg = colors.bg_medium },

    -- Inactive buffer - dimmed
    EmberlineInactive = { fg = colors.fg_dim, bg = colors.bg_dark },
    EmberlineInactiveMod = { fg = colors.amber, bg = colors.bg_dark },
    EmberlineInactivePin = { fg = colors.amber_deep, bg = colors.bg_dark },

    -- Separators for slanted style (fg = left bg, bg = right bg)
    EmberlineSepActiveToInactive = { fg = colors.bg_light, bg = colors.bg_dark },
    EmberlineSepInactiveToActive = { fg = colors.bg_dark, bg = colors.bg_light },
    EmberlineSepInactiveToInactive = { fg = colors.bg_dark, bg = colors.bg_dark },
    EmberlineSepActiveToFill = { fg = colors.bg_light, bg = colors.bg_dark },
    EmberlineSepInactiveToFill = { fg = colors.bg_dark, bg = colors.bg_dark },
    EmberlineSepFillToActive = { fg = colors.bg_dark, bg = colors.bg_light },
    EmberlineSepFillToInactive = { fg = colors.bg_dark, bg = colors.bg_dark },

    -- Other elements
    EmberlineClose = { fg = colors.fg_dim, bg = colors.bg_dark },
    EmberlineCloseCurrent = { fg = colors.fg_dim, bg = colors.bg_light },
    EmberlineFill = { bg = colors.bg_dark },
    EmberlineJump = { fg = colors.fg_bright, bg = colors.bg_light, bold = true },
  }

  for name, def in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, def)
  end
end

--- Get highlight name for a buffer based on its state
---@param opts table Options with current, visible, modified, pinned
---@return string Highlight group name
function M.get_buffer_hl(opts)
  local config = require("emberline.config").get()
  local hls = config.highlights

  local base
  if opts.current then
    base = "current"
  elseif opts.visible then
    base = "visible"
  else
    base = "inactive"
  end

  -- Priority: pinned > modified > base
  if opts.pinned then
    return hls[base .. "_pin"]
  elseif opts.modified then
    return hls[base .. "_mod"]
  else
    return hls[base]
  end
end

return M

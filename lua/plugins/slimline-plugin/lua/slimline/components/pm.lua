local C = {}
local pm_module = nil
local pm_checked = false
local slimline = require('slimline')
local function get_pm()
  if not pm_checked then
    local ok, pm = pcall(require, 'pm')
    pm_module = ok and pm or nil
    pm_checked = true
  end
  return pm_module
end
function C.render(opts)
  local pm = get_pm()
  if not pm then return '' end
  if not vim.g.pm_current_workspace then return '' end
  local config = slimline.config.configs.pm or {}
  local statusline = pm.statusline
  local status = ''
  if statusline then
    local ok, sl_module = pcall(require, 'pm.statusline')
    if ok and sl_module.get then
      status = sl_module.get()
    end
  end
  if status == '' then return '' end
  local icon = config.icon or ''
  local display = icon ~= '' and (icon .. ' ' .. status) or status
  return slimline.highlights.hl_component(
    { primary = display },
    opts.hls,
    opts.sep,
    opts.direction,
    opts.active,
    opts.style
  )
end
return C

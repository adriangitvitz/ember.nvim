local C = {}
local with_icons = false
local initialized = false
local lsp_clients = {}
local lsp_loading = {}
local spinner_idx = 1
local spinner_frames = { '*', '+', '*', '+' }
local icons_module = nil
local slimline = require('slimline')
local function get_config()
  return slimline.config.configs.filetype_lsp or {}
end
local track_lsp = vim.schedule_wrap(function(data)
  if not vim.api.nvim_buf_is_valid(data.buf) then
    lsp_clients[data.buf] = nil
    lsp_loading[data.buf] = nil
    return
  end
  local config = get_config()
  local attached_clients = vim.lsp.get_clients({ bufnr = data.buf })
  local names = {}
  for _, client in ipairs(attached_clients) do
    if not (config.map_lsps and config.map_lsps[client.name] == false) then
      local name = (config.map_lsps and config.map_lsps[client.name]) or client.name:gsub('language.server', 'ls')
      table.insert(names, name)
    end
  end
  if #names > 0 then
    lsp_clients[data.buf] = table.concat(names, config.lsp_sep or ',')
  else
    lsp_clients[data.buf] = nil
    lsp_loading[data.buf] = nil
  end
end)
local track_progress = vim.schedule_wrap(function(ev)
  local bufnr = vim.api.nvim_get_current_buf()
  local value = ev.data and ev.data.params and ev.data.params.value
  if not value then return end
  if value.kind == 'begin' or value.kind == 'report' then
    lsp_loading[bufnr] = true
    spinner_idx = (spinner_idx % #spinner_frames) + 1
  elseif value.kind == 'end' then
    vim.defer_fn(function()
      lsp_loading[bufnr] = nil
      vim.cmd.redrawstatus()
    end, 100)
  end
  vim.cmd.redrawstatus()
end)
local function init()
  if initialized then return end
  local ok
  ok, icons_module = pcall(require, 'ember.icons')
  if ok then
    with_icons = true
  else
    ok, icons_module = pcall(require, 'mini.icons')
    if ok then with_icons = true end
  end
  initialized = true
  slimline.au({ 'LspAttach', 'LspDetach', 'BufEnter' }, '*', track_lsp, 'Track LSP')
  slimline.au({ 'LspProgress' }, '*', track_progress, 'Track LSP Progress')
end
function C.render(opts)
  init()
  local config = get_config()
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  if filetype == '' then filetype = '[No Name]' end
  if with_icons and icons_module then
    local icon
    if icons_module.get_icon_by_filetype then
      icon = icons_module.get_icon_by_filetype(filetype)
    elseif icons_module.get then
      icon = icons_module.get('filetype', filetype)
    end
    if icon then
      filetype = icon .. ' ' .. filetype
    end
  end
  local lsp_indicator = ''
  local lsp_name = lsp_clients[buf]
  if lsp_name then
    if lsp_loading[buf] then
      lsp_indicator = spinner_frames[spinner_idx]
    else
      lsp_indicator = config.icons and config.icons.ready or '*'
    end
  end
  local primary = filetype
  local secondary = ''
  if lsp_name then
    secondary = lsp_indicator .. ' ' .. lsp_name
  end
  return slimline.highlights.hl_component(
    { primary = primary, secondary = secondary },
    opts.hls,
    opts.sep,
    opts.direction,
    opts.active,
    opts.style
  )
end
return C

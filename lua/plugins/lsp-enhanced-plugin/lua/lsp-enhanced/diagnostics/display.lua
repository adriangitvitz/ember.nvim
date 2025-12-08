local M = {}
function M.truncate_diagnostic(message, max_length)
  max_length = max_length or 50
  if #message <= max_length then
    return message
  end
  local truncated = message:sub(1, max_length)
  local last_period = truncated:reverse():find('.', 1, true)
  if last_period and last_period < max_length * 0.3 then
    return message:sub(1, max_length - last_period + 1)
  end
  local last_space = truncated:reverse():find(' ', 1, true)
  if last_space then
    return message:sub(1, max_length - last_space) .. '…'
  end
  return truncated .. '…'
end
function M.format_virtual_text(diagnostic, opts)
  opts = vim.tbl_extend('force', {
    format = nil,
    prefix = '',
    suffix = '',
    max_length = 50,
  }, opts or {})
  local message = diagnostic.message
  if opts.format then
    message = opts.format(diagnostic)
  end
  message = M.truncate_diagnostic(message, opts.max_length)
  if diagnostic.source then
    message = string.format('[%s] %s', diagnostic.source, message)
  end
  return opts.prefix .. message .. opts.suffix
end
function M.setup_virtual_text(config)
  local default_config = {
    enabled = true,
    max_length = 50,
    prefix = '■ ',
    spacing = 4,
    severity = {
      min = vim.diagnostic.severity.HINT,
    },
  }
  config = vim.tbl_extend('force', default_config, config or {})
  if not config.enabled then
    vim.diagnostic.config({
      virtual_text = false,
    })
    return
  end
  vim.diagnostic.config({
    virtual_text = {
      prefix = config.prefix,
      spacing = config.spacing,
      severity = config.severity,
      format = function(diagnostic)
        return M.format_virtual_text(diagnostic, {
          max_length = config.max_length,
        })
      end,
    },
  })
end
function M.setup_signs(config)
  config = config or {}
  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = config.error or '✘',
        [vim.diagnostic.severity.WARN] = config.warn or '▲',
        [vim.diagnostic.severity.HINT] = config.hint or '⚑',
        [vim.diagnostic.severity.INFO] = config.info or '»',
      },
    },
  })
end
function M.show_diagnostic_float(opts)
  opts = vim.tbl_extend('force', {
    scope = 'cursor',
    border = 'rounded',
    source = 'always',
    format = function(d)
      local message = d.message
      if d.code then
        message = string.format('[%s] %s', d.code, message)
      end
      if d.source then
        message = string.format('%s: %s', d.source, message)
      end
      return message
    end,
  }, opts or {})
  vim.diagnostic.open_float(nil, opts)
end
function M.setup_underline(config)
  config = config or {}
  vim.diagnostic.config({
    underline = config.enabled ~= false,
  })
end
function M.setup_severity_sort(enabled)
  vim.diagnostic.config({
    severity_sort = enabled ~= false,
  })
end
function M.update_config(display_config)
  if display_config.virtual_text ~= nil then
    if type(display_config.virtual_text) == 'table' then
      M.setup_virtual_text(display_config.virtual_text)
    elseif display_config.virtual_text == true then
      M.setup_virtual_text({})
    else
      M.setup_virtual_text({ enabled = false })
    end
  end
  if display_config.signs ~= nil then
    if type(display_config.signs) == 'table' then
      M.setup_signs(display_config.signs)
    elseif display_config.signs == true then
      M.setup_signs({})
    end
  end
  if display_config.underline ~= nil then
    if type(display_config.underline) == 'table' then
      M.setup_underline(display_config.underline)
    else
      M.setup_underline({ enabled = display_config.underline })
    end
  end
  if display_config.severity_sort ~= nil then
    M.setup_severity_sort(display_config.severity_sort)
  end
end
return M

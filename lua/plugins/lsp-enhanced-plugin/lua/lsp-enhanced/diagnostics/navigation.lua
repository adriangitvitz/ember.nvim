local M = {}
function M.get_sorted_diagnostics(bufnr, opts)
  bufnr = bufnr or 0
  opts = opts or {}
  local diagnostics = vim.diagnostic.get(bufnr, opts)
  table.sort(diagnostics, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    return a.col < b.col
  end)
  return diagnostics
end
function M.goto_next(opts)
  opts = vim.tbl_extend('force', {
    severity = nil,
    wrap = true,
    float = true,
  }, opts or {})
  local diagnostics = M.get_sorted_diagnostics(0, { severity = opts.severity })
  if #diagnostics == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  local current_col = cursor[2]
  local next_diag = nil
  for _, diag in ipairs(diagnostics) do
    if diag.lnum > current_line or
       (diag.lnum == current_line and diag.col > current_col) then
      next_diag = diag
      break
    end
  end
  if not next_diag and opts.wrap then
    next_diag = diagnostics[1]
  end
  if next_diag then
    vim.api.nvim_win_set_cursor(0, { next_diag.lnum + 1, next_diag.col })
    if opts.float then
      require('lsp-enhanced.diagnostics.display').show_diagnostic_float({
        scope = 'cursor',
      })
    end
  else
    vim.notify('No more diagnostics', vim.log.levels.INFO)
  end
end
function M.goto_prev(opts)
  opts = vim.tbl_extend('force', {
    severity = nil,
    wrap = true,
    float = true,
  }, opts or {})
  local diagnostics = M.get_sorted_diagnostics(0, { severity = opts.severity })
  if #diagnostics == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  local current_col = cursor[2]
  local prev_diag = nil
  for i = #diagnostics, 1, -1 do
    local diag = diagnostics[i]
    if diag.lnum < current_line or
       (diag.lnum == current_line and diag.col < current_col) then
      prev_diag = diag
      break
    end
  end
  if not prev_diag and opts.wrap then
    prev_diag = diagnostics[#diagnostics]
  end
  if prev_diag then
    vim.api.nvim_win_set_cursor(0, { prev_diag.lnum + 1, prev_diag.col })
    if opts.float then
      require('lsp-enhanced.diagnostics.display').show_diagnostic_float({
        scope = 'cursor',
      })
    end
  else
    vim.notify('No more diagnostics', vim.log.levels.INFO)
  end
end
function M.goto_first_error(opts)
  opts = opts or {}
  local diagnostics = M.get_sorted_diagnostics(0, {
    severity = { min = vim.diagnostic.severity.WARN },
  })
  if #diagnostics == 0 then
    vim.notify('No errors or warnings', vim.log.levels.INFO)
    return
  end
  local first = diagnostics[1]
  vim.api.nvim_win_set_cursor(0, { first.lnum + 1, first.col })
  if opts.float ~= false then
    require('lsp-enhanced.diagnostics.display').show_diagnostic_float({
      scope = 'cursor',
    })
  end
end
function M.get_diagnostic_counts(bufnr)
  bufnr = bufnr or 0
  local diagnostics = vim.diagnostic.get(bufnr)
  local counts = {
    error = 0,
    warn = 0,
    info = 0,
    hint = 0,
  }
  for _, diag in ipairs(diagnostics) do
    if diag.severity == vim.diagnostic.severity.ERROR then
      counts.error = counts.error + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      counts.warn = counts.warn + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      counts.info = counts.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      counts.hint = counts.hint + 1
    end
  end
  return counts
end
function M.has_diagnostics_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  for _, diag in ipairs(diagnostics) do
    if diag.col <= col and col <= diag.end_col then
      return true
    end
  end
  return false
end
return M

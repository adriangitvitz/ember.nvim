local M = {}
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local utils = require("picker.utils")
local function location_to_string(location, root)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange
  if not uri or not range then
    return nil
  end
  local path = vim.uri_to_fname(uri)
  local rel_path = utils.relative_path(path, root)
  local line = range.start.line + 1
  local col = range.start.character + 1
  return string.format("%s:%d:%d", rel_path, line, col), path
end
local function symbol_to_string(symbol, root)
  local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown"
  if symbol.location then
    local uri = symbol.location.uri
    local range = symbol.location.range
    local path = vim.uri_to_fname(uri)
    local rel_path = utils.relative_path(path, root)
    local line = range.start.line + 1
    local col = range.start.character + 1
    return string.format("[%s] %s  %s:%d:%d", kind, symbol.name, rel_path, line, col), path, line, col
  elseif symbol.selectionRange then
    local line = symbol.selectionRange.start.line + 1
    local col = symbol.selectionRange.start.character + 1
    return string.format("[%s] %s  :%d:%d", kind, symbol.name, line, col), nil, line, col
  end
  return string.format("[%s] %s", kind, symbol.name), nil, nil, nil
end
local function pick_locations(locations, opts)
  opts = opts or {}
  local root = utils.get_project_root()
  if not locations or #locations == 0 then
    utils.notify("No locations found", vim.log.levels.INFO)
    return
  end
  if #locations == 1 and not opts.force_picker then
    local loc = locations[1]
    local _, path = location_to_string(loc, root)
    local uri = loc.uri or loc.targetUri
    local range = loc.range or loc.targetSelectionRange
    path = vim.uri_to_fname(uri)
    local line = range.start.line + 1
    local col = range.start.character + 1
    actions.open_file(path, line, col)
    return
  end
  local items = {}
  local paths = {}
  for _, loc in ipairs(locations) do
    local str, path = location_to_string(loc, root)
    if str then
      table.insert(items, str)
      paths[str] = path
    end
  end
  fzf.run({
    items = items,
    prompt = opts.prompt or "LSP",
    delimiter = ":",
    preview_cmd = 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || head -500 {1}',
    on_select = function(selection, action)
      local parsed = actions.parse_lsp_location(selection)
      if parsed then
        local full_path = paths[selection] or parsed.file
        if not full_path:match("^/") then
          full_path = root .. "/" .. full_path
        end
        actions.open_file(full_path, parsed.line, parsed.col, action)
      end
    end,
  })
end
function M.definitions(opts)
  opts = opts or {}
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    local locations = result
    if result and result.range then
      locations = { result }
    end
    pick_locations(locations, { prompt = "Definitions" })
  end)
end
function M.references(opts)
  opts = opts or {}
  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = true }
  vim.lsp.buf_request(0, "textDocument/references", params, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    pick_locations(result, { prompt = "References", force_picker = true })
  end)
end
function M.implementations(opts)
  opts = opts or {}
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/implementation", params, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    local locations = result
    if result and result.range then
      locations = { result }
    end
    pick_locations(locations, { prompt = "Implementations" })
  end)
end
function M.type_definitions(opts)
  opts = opts or {}
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/typeDefinition", params, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    local locations = result
    if result and result.range then
      locations = { result }
    end
    pick_locations(locations, { prompt = "Type Definitions" })
  end)
end
function M.document_symbols(opts)
  opts = opts or {}
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  local bufname = vim.api.nvim_buf_get_name(0)
  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    if not result or #result == 0 then
      utils.notify("No symbols found", vim.log.levels.INFO)
      return
    end
    local items = {}
    local function flatten(symbols, prefix)
      for _, sym in ipairs(symbols) do
        local kind = vim.lsp.protocol.SymbolKind[sym.kind] or "Unknown"
        local range = sym.selectionRange or sym.range
        local line = range.start.line + 1
        local col = range.start.character + 1
        local name = prefix .. sym.name
        table.insert(items, string.format("[%s] %s  :%d:%d", kind, name, line, col))
        if sym.children then
          flatten(sym.children, name .. ".")
        end
      end
    end
    flatten(result, "")
    fzf.run({
      items = items,
      prompt = "Document Symbols",
      on_select = function(selection)
        local line, col = selection:match(":(%d+):(%d+)$")
        if line then
          vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) - 1 })
          vim.cmd("normal! zz")
        end
      end,
    })
  end)
end
function M.workspace_symbols(opts)
  opts = opts or {}
  local query = opts.query or ""
  local root = utils.get_project_root()
  vim.lsp.buf_request(0, "workspace/symbol", { query = query }, function(err, result)
    if err then
      utils.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end
    if not result or #result == 0 then
      utils.notify("No symbols found", vim.log.levels.INFO)
      return
    end
    local items = {}
    local data = {}
    for _, sym in ipairs(result) do
      local str, path, line, col = symbol_to_string(sym, root)
      if str then
        table.insert(items, str)
        data[str] = { path = path, line = line, col = col }
      end
    end
    fzf.run({
      items = items,
      prompt = "Workspace Symbols",
      on_select = function(selection, action)
        local info = data[selection]
        if info and info.path then
          actions.open_file(info.path, info.line, info.col, action)
        elseif info and info.line then
          vim.api.nvim_win_set_cursor(0, { info.line, (info.col or 1) - 1 })
          vim.cmd("normal! zz")
        end
      end,
    })
  end)
end
function M.diagnostics(opts)
  opts = opts or {}
  local root = utils.get_project_root()
  local bufnr = opts.bufnr
  local diagnostics
  if bufnr then
    diagnostics = vim.diagnostic.get(bufnr)
  else
    diagnostics = vim.diagnostic.get()
  end
  if #diagnostics == 0 then
    utils.notify("No diagnostics", vim.log.levels.INFO)
    return
  end
  local items = {}
  local severity_names = { "ERROR", "WARN", "INFO", "HINT" }
  for _, diag in ipairs(diagnostics) do
    local path = vim.api.nvim_buf_get_name(diag.bufnr)
    local rel_path = utils.relative_path(path, root)
    local severity = severity_names[diag.severity] or "UNKNOWN"
    local line = diag.lnum + 1
    local col = diag.col + 1
    local message = diag.message:gsub("\n", " ")
    table.insert(items, string.format("[%s] %s:%d:%d %s", severity, rel_path, line, col, message))
  end
  fzf.run({
    items = items,
    prompt = "Diagnostics",
    on_select = function(selection, action)
      local path, line, col = selection:match("%[%w+%] (.+):(%d+):(%d+)")
      if path then
        local full_path = path
        if not path:match("^/") then
          full_path = root .. "/" .. path
        end
        actions.open_file(full_path, tonumber(line), tonumber(col), action)
      end
    end,
  })
end
return M

local M = {}
M.CompletionItemKind = {
  Text = 1,
  Method = 2,
  Function = 3,
  Constructor = 4,
  Field = 5,
  Variable = 6,
  Class = 7,
  Interface = 8,
  Module = 9,
  Property = 10,
  Unit = 11,
  Value = 12,
  Enum = 13,
  Keyword = 14,
  Snippet = 15,
  Color = 16,
  File = 17,
  Reference = 18,
  Folder = 19,
  EnumMember = 20,
  Constant = 21,
  Struct = 22,
  Event = 23,
  Operator = 24,
  TypeParameter = 25,
}
M.CompletionItemKindName = {}
for name, value in pairs(M.CompletionItemKind) do
  M.CompletionItemKindName[value] = name
end
M.DiagnosticSeverity = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}
M.SymbolKind = {
  File = 1,
  Module = 2,
  Namespace = 3,
  Package = 4,
  Class = 5,
  Method = 6,
  Property = 7,
  Field = 8,
  Constructor = 9,
  Enum = 10,
  Interface = 11,
  Function = 12,
  Variable = 13,
  Constant = 14,
  String = 15,
  Number = 16,
  Boolean = 17,
  Array = 18,
  Object = 19,
  Key = 20,
  Null = 21,
  EnumMember = 22,
  Struct = 23,
  Event = 24,
  Operator = 25,
  TypeParameter = 26,
}
M.ErrorCodes = {
  ParseError = -32700,
  InvalidRequest = -32600,
  MethodNotFound = -32601,
  InvalidParams = -32602,
  InternalError = -32603,
  ServerNotInitialized = -32002,
  UnknownErrorCode = -32001,
  RequestCancelled = -32800,
  ContentModified = -32801,
  ServerCancelled = -32802,
  RequestFailed = -32803,
}
function M.is_request_cancelled(err)
  return err and err.code == M.ErrorCodes.RequestCancelled
end
function M.is_content_modified(err)
  return err and err.code == M.ErrorCodes.ContentModified
end
function M.get_completion_kind_name(kind)
  return M.CompletionItemKindName[kind] or 'Unknown'
end
function M.is_position_before(pos1, pos2)
  if pos1.line < pos2.line then
    return true
  elseif pos1.line == pos2.line then
    return pos1.character < pos2.character
  end
  return false
end
function M.is_position_in_range(pos, range)
  if M.is_position_before(pos, range.start) then
    return false
  end
  if M.is_position_before(range['end'], pos) then
    return false
  end
  return true
end
function M.compare_positions(pos1, pos2)
  if pos1.line < pos2.line then
    return -1
  elseif pos1.line > pos2.line then
    return 1
  elseif pos1.character < pos2.character then
    return -1
  elseif pos1.character > pos2.character then
    return 1
  end
  return 0
end
function M.vim_to_lsp_position(line, col)
  return {
    line = line - 1,
    character = col,
  }
end
function M.lsp_to_vim_position(pos)
  return pos.line + 1, pos.character
end
function M.extract_completion_items(result)
  if not result then
    return {}
  end
  if result.items then
    return result.items
  end
  if vim.tbl_islist(result) then
    return result
  end
  return {}
end
function M.is_completion_incomplete(result)
  if not result then
    return false
  end
  if type(result.isIncomplete) == 'boolean' then
    return result.isIncomplete
  end
  return false
end
function M.create_text_edit(range, new_text)
  return {
    range = range,
    newText = new_text,
  }
end
function M.create_range(start_line, start_char, end_line, end_char)
  return {
    start = { line = start_line, character = start_char },
    ['end'] = { line = end_line, character = end_char },
  }
end
function M.normalize_method(method)
  if not vim.startswith(method, 'textDocument/') and
     not vim.startswith(method, '$/') and
     not vim.startswith(method, 'workspace/') then
    return 'textDocument/' .. method
  end
  return method
end
function M.supports_method(server_capabilities, method)
  if not server_capabilities then
    return false
  end
  local capability_map = {
    ['textDocument/completion'] = 'completionProvider',
    ['textDocument/hover'] = 'hoverProvider',
    ['textDocument/signatureHelp'] = 'signatureHelpProvider',
    ['textDocument/definition'] = 'definitionProvider',
    ['textDocument/typeDefinition'] = 'typeDefinitionProvider',
    ['textDocument/implementation'] = 'implementationProvider',
    ['textDocument/references'] = 'referencesProvider',
    ['textDocument/documentHighlight'] = 'documentHighlightProvider',
    ['textDocument/documentSymbol'] = 'documentSymbolProvider',
    ['textDocument/codeAction'] = 'codeActionProvider',
    ['textDocument/codeLens'] = 'codeLensProvider',
    ['textDocument/formatting'] = 'documentFormattingProvider',
    ['textDocument/rangeFormatting'] = 'documentRangeFormattingProvider',
    ['textDocument/rename'] = 'renameProvider',
    ['textDocument/publishDiagnostics'] = true,
  }
  local capability = capability_map[method]
  if capability == nil then
    return false
  end
  if capability == true then
    return true
  end
  local value = server_capabilities[capability]
  return value == true or (type(value) == 'table' and vim.tbl_count(value) > 0)
end
return M

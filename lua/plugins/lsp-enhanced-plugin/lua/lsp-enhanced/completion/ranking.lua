local M = {}
local WEIGHTS = {
  prefix_match = 100,
  fuzzy_match = 50,
  locality = 30,
  recency = 20,
  type_compatibility = 15,
  lsp_sort = 10,
}
function M.camel_case_match(text, pattern)
  local capitals = text:sub(1, 1)
  for char in text:gmatch('[A-Z]') do
    capitals = capitals .. char
  end
  return vim.startswith(capitals:lower(), pattern:lower())
end
function M.fuzzy_match(text, pattern)
  local text_lower = text:lower()
  local pattern_lower = pattern:lower()
  local text_idx = 1
  for i = 1, #pattern_lower do
    local char = pattern_lower:sub(i, i)
    local found = text_lower:find(char, text_idx, true)
    if not found then
      return false
    end
    text_idx = found + 1
  end
  return true
end
local function prefix_score(item_label, prefix)
  if prefix == '' then
    return 0
  end
  if vim.startswith(item_label:lower(), prefix:lower()) then
    if vim.startswith(item_label, prefix) then
      return 100
    end
    return 80
  end
  if M.camel_case_match(item_label, prefix) then
    return 60
  end
  if M.fuzzy_match(item_label, prefix) then
    return 40
  end
  if item_label:lower():find(prefix:lower(), 1, true) then
    return 20
  end
  return 0
end
local function locality_score(item, context)
  if not item.data or not item.data.uri then
    return 0
  end
  if item.data.uri == context.buffer_uri then
    return 100
  end
  if context.buffer_path then
    local item_path = vim.uri_to_fname(item.data.uri)
    local item_dir = vim.fn.fnamemodify(item_path, ':h')
    local buffer_dir = vim.fn.fnamemodify(context.buffer_path, ':h')
    if item_dir == buffer_dir then
      return 70
    end
    if context.project_root and vim.startswith(item_dir, context.project_root) then
      return 40
    end
  end
  return 0
end
local function recency_score(item, recency_cache)
  local cache = require('lsp-enhanced.completion.cache')
  local timestamp = cache.get_item_last_used(item)
  if not timestamp then
    return 0
  end
  local age_ms = vim.loop.now() - timestamp
  local age_minutes = age_ms / (60 * 1000)
  return math.max(0, 100 * math.exp(-age_minutes / 30))
end
local function detect_expected_type(context)
  if not context.before_cursor then
    return nil
  end
  local before = context.before_cursor
  local spec = require('lsp-enhanced.util.spec')
  local type_annotation = before:match(':([%w_%.]+)%s*=%s*$')
  if type_annotation then
    return { type = type_annotation, confidence = 90 }
  end
  local return_type = before:match('function%s+%w+%([^)]*%)%s*:%s*([%w_%.]+).*return%s*$')
  if return_type then
    return { type = return_type, confidence = 85 }
  end
  local param_type = before:match('%(.-,%s*%w+%s*:%s*([%w_%.]+)%s*=%s*$')
    or before:match('%(%s*%w+%s*:%s*([%w_%.]+)%s*=%s*$')
  if param_type then
    return { type = param_type, confidence = 85 }
  end
  if before:match('%[%s*$') then
    return { kind = spec.CompletionItemKind.Variable, confidence = 60 }
  end
  if before:match('{%s*$') or before:match(',%s*$') and context.in_object then
    return { kind = spec.CompletionItemKind.Property, confidence = 60 }
  end
  if before:match('%w+%(%s*$') or before:match(',%s*$') and context.in_function_call then
    return { kind = spec.CompletionItemKind.Variable, confidence = 40 }
  end
  if before:match('=%s*$') and not before:match('==%s*$') and not before:match('!=%s*$') then
    return { kind = spec.CompletionItemKind.Variable, confidence = 30 }
  end
  return nil
end
local function extract_item_type(item)
  local spec = require('lsp-enhanced.util.spec')
  local type_info = {}
  if item.detail then
    local simple_type = item.detail:match('^%s*(%w+)%s*$')
    if simple_type then
      type_info.type = simple_type
    end
    if item.detail:match('=>') or item.detail:match('function') then
      type_info.is_function = true
    end
    local return_type = item.detail:match('=>%s*([%w_%.]+)')
    if return_type then
      type_info.return_type = return_type
    end
  end
  type_info.kind = item.kind
  if item.kind == spec.CompletionItemKind.Function or
     item.kind == spec.CompletionItemKind.Method or
     item.kind == spec.CompletionItemKind.Constructor then
    type_info.is_function = true
  elseif item.kind == spec.CompletionItemKind.Class then
    type_info.is_type = true
  elseif item.kind == spec.CompletionItemKind.Interface or
         item.kind == spec.CompletionItemKind.Enum then
    type_info.is_type = true
  end
  return type_info
end
local function types_compatible(expected, actual)
  if expected.type and actual.type then
    if expected.type == actual.type then
      return true, 100
    end
    local compatible_types = {
      string = { 'String', 'str', 'text' },
      number = { 'Number', 'int', 'float', 'double', 'integer' },
      boolean = { 'Boolean', 'bool' },
      array = { 'Array', 'List', 'Vec', 'list', 'vector' },
      object = { 'Object', 'Map', 'Dict', 'HashMap', 'dict', 'table' },
    }
    local expected_lower = expected.type:lower()
    for base_type, variants in pairs(compatible_types) do
      if expected_lower == base_type or vim.tbl_contains(variants, expected.type) then
        if actual.type:lower() == base_type or vim.tbl_contains(variants, actual.type) then
          return true, 80
        end
      end
    end
  end
  if expected.kind and actual.kind then
    if expected.kind == actual.kind then
      return true, 70
    end
    local spec = require('lsp-enhanced.util.spec')
    local function_kinds = {
      spec.CompletionItemKind.Function,
      spec.CompletionItemKind.Method,
      spec.CompletionItemKind.Constructor,
    }
    if vim.tbl_contains(function_kinds, expected.kind) and
       vim.tbl_contains(function_kinds, actual.kind) then
      return true, 60
    end
  end
  if expected.type and actual.return_type then
    if expected.type == actual.return_type then
      return true, 90
    end
  end
  return false, 0
end
local function type_compatibility_score(item, context)
  local expected = detect_expected_type(context)
  if not expected then
    return 0
  end
  local actual = extract_item_type(item)
  if not actual then
    return 0
  end
  local compatible, confidence = types_compatible(expected, actual)
  if compatible then
    local context_confidence = expected.confidence or 50
    return (confidence / 100) * (context_confidence / 100) * 100
  end
  return 0
end
local function lsp_sort_score(item)
  if not item.sortText then
    return 50
  end
  local sort_num = tonumber(item.sortText)
  if sort_num then
    return math.max(0, math.min(100, 100 - sort_num))
  end
  return 50
end
function M.rank_items(items, context, recency_cache)
  local prefix = context.prefix or ''
  local scored_items = {}
  for _, item in ipairs(items) do
    local score = 0
    score = score + prefix_score(item.label, prefix) * WEIGHTS.prefix_match
    score = score + locality_score(item, context) * WEIGHTS.locality
    if recency_cache then
      score = score + recency_score(item, recency_cache) * WEIGHTS.recency
    end
    score = score + type_compatibility_score(item, context) * WEIGHTS.type_compatibility
    score = score + lsp_sort_score(item) * WEIGHTS.lsp_sort
    table.insert(scored_items, {
      item = item,
      score = score,
    })
  end
  table.sort(scored_items, function(a, b)
    return a.score > b.score
  end)
  local ranked = {}
  for _, scored in ipairs(scored_items) do
    table.insert(ranked, scored.item)
  end
  return ranked
end
function M.mark_used(item, recency_cache)
  local cache = require('lsp-enhanced.completion.cache')
  cache.mark_item_used(item)
end
function M.get_item_key(item)
  local cache = require('lsp-enhanced.completion.cache')
  return cache.make_item_key(item)
end
function M.set_weights(custom_weights)
  WEIGHTS = vim.tbl_extend('force', WEIGHTS, custom_weights)
end
function M.get_weights()
  return vim.deepcopy(WEIGHTS)
end
return M

local M = {}
local cache = require('lsp-enhanced.completion.cache')
local ranking = require('lsp-enhanced.completion.ranking')
local filtering = require('lsp-enhanced.completion.filtering')
local default_config = {
  enabled = true,
  ranking = true,
  filtering = true,
  cache = true,
  deduplicate = true,
  max_items = 100,
  min_prefix_length = 0,
}
local config = vim.deepcopy(default_config)
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', default_config, user_config or {})
end
function M.get_config()
  return vim.deepcopy(config)
end
function M.enhance_items(items, context)
  if not config.enabled or not items or #items == 0 then
    return items
  end
  context = context or filtering.get_completion_context()
  if context.prefix and #context.prefix < config.min_prefix_length then
    return items
  end
  local enhanced = items
  if config.filtering then
    enhanced = filtering.filter_by_prefix(enhanced, context.prefix)
  end
  if config.deduplicate then
    enhanced = filtering.deduplicate(enhanced)
  end
  if config.filtering then
    enhanced = filtering.filter_by_context(enhanced, context)
  end
  if config.ranking then
    local recency = config.cache and cache.get_recency_cache() or nil
    enhanced = ranking.rank_items(enhanced, context, recency)
  end
  enhanced = filtering.limit_items(enhanced, config.max_items)
  return enhanced
end
function M.process_completion_result(result, context)
  if not result then
    return result
  end
  local spec = require('lsp-enhanced.util.spec')
  local items = spec.extract_completion_items(result)
  local enhanced = M.enhance_items(items, context)
  if result.items then
    return {
      isIncomplete = result.isIncomplete,
      items = enhanced,
    }
  else
    return enhanced
  end
end
function M.mark_completion_used(item)
  if not config.enabled or not config.cache then
    return
  end
  cache.mark_item_used(item)
end
function M.cache_completion(bufnr, line, col, prefix, trigger, items)
  if not config.enabled or not config.cache then
    return
  end
  local key = cache.make_completion_key(bufnr, line, col, prefix, trigger)
  cache.cache_completion(key, items)
end
function M.get_cached_completion(bufnr, line, col, prefix, trigger, max_age_ms)
  if not config.enabled or not config.cache then
    return nil
  end
  local key = cache.make_completion_key(bufnr, line, col, prefix, trigger)
  return cache.get_cached_completion(key, max_age_ms)
end
function M.clear_caches()
  cache.clear_all()
end
function M.get_cache_stats()
  return cache.get_stats()
end
function M.enable()
  config.enabled = true
end
function M.disable()
  config.enabled = false
end
function M.toggle()
  config.enabled = not config.enabled
  return config.enabled
end
function M.is_enabled()
  return config.enabled
end
return M

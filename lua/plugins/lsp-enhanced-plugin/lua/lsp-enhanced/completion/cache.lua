local Cache = require('lsp-enhanced.util.lru_cache').Cache
local M = {}
local completion_cache = Cache.new(100)
local recency_cache = Cache.new(1000)
function M.get_completion_cache()
  return completion_cache
end
function M.get_recency_cache()
  return recency_cache
end
function M.make_completion_key(bufnr, line, col, prefix, trigger)
  return string.format("%d:%d:%d:%s:%s",
    bufnr, line, col, prefix or '', trigger or '')
end
function M.is_cache_valid(cached, max_age_ms)
  max_age_ms = max_age_ms or 5000
  if not cached or not cached.timestamp then
    return false
  end
  local age = vim.loop.now() - cached.timestamp
  return age < max_age_ms
end
function M.cache_completion(key, items)
  completion_cache:set(key, {
    items = items,
    timestamp = vim.loop.now(),
  })
end
function M.get_cached_completion(key, max_age_ms)
  local cached = completion_cache:get(key)
  if not cached then
    return nil
  end
  if not M.is_cache_valid(cached, max_age_ms) then
    completion_cache:remove(key)
    return nil
  end
  return cached.items
end
function M.mark_item_used(item)
  local key = M.make_item_key(item)
  recency_cache:set(key, vim.loop.now())
end
function M.get_item_last_used(item)
  local key = M.make_item_key(item)
  return recency_cache:get(key)
end
function M.make_item_key(item)
  return string.format("%s:%s:%s",
    item.label or '',
    item.kind or '',
    item.detail or ''
  )
end
function M.clear_completion_cache()
  completion_cache:clear()
end
function M.clear_recency_cache()
  recency_cache:clear()
end
function M.clear_all()
  completion_cache:clear()
  recency_cache:clear()
end
function M.get_stats()
  return {
    completion_cache_size = completion_cache:size(),
    completion_cache_max = completion_cache.max_size,
    recency_cache_size = recency_cache:size(),
    recency_cache_max = recency_cache.max_size,
  }
end
return M

local M = {}
local Cache = {}
Cache.__index = Cache
function Cache.new(max_size)
  return setmetatable({
    max_size = max_size or 1000,
    items = {},
    order = {},
    key_to_idx = {},
  }, Cache)
end
function Cache:get(key)
  if not self.items[key] then
    return nil
  end
  self:_touch(key)
  return self.items[key]
end
function Cache:set(key, value)
  if self.items[key] then
    self.items[key] = value
    self:_touch(key)
    return
  end
  if #self.order >= self.max_size then
    self:_evict_oldest()
  end
  self.items[key] = value
  table.insert(self.order, key)
  self.key_to_idx[key] = #self.order
end
function Cache:_touch(key)
  local idx = self.key_to_idx[key]
  if not idx then return end
  table.remove(self.order, idx)
  for i = idx, #self.order do
    self.key_to_idx[self.order[i]] = i
  end
  table.insert(self.order, key)
  self.key_to_idx[key] = #self.order
end
function Cache:_evict_oldest()
  if #self.order == 0 then return end
  local oldest_key = self.order[1]
  self.items[oldest_key] = nil
  self.key_to_idx[oldest_key] = nil
  table.remove(self.order, 1)
  for i = 1, #self.order do
    self.key_to_idx[self.order[i]] = i
  end
end
function Cache:has(key)
  return self.items[key] ~= nil
end
function Cache:remove(key)
  if not self.items[key] then return end
  local idx = self.key_to_idx[key]
  self.items[key] = nil
  self.key_to_idx[key] = nil
  if idx then
    table.remove(self.order, idx)
    for i = idx, #self.order do
      self.key_to_idx[self.order[i]] = i
    end
  end
end
function Cache:clear()
  self.items = {}
  self.order = {}
  self.key_to_idx = {}
end
function Cache:size()
  return #self.order
end
function Cache:keys()
  return vim.deepcopy(self.order)
end
function Cache:values()
  local vals = {}
  for _, key in ipairs(self.order) do
    table.insert(vals, self.items[key])
  end
  return vals
end
M.Cache = Cache
return M

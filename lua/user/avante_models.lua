local M = {}

local cache_dir = vim.fn.stdpath("cache") .. "/avante-models"
vim.fn.mkdir(cache_dir, "p")

local fetchable = {
  openrouter = { url = "https://openrouter.ai/api/v1/models", auth_env = "OPENROUTER_API_KEY" },
  lmstudio   = { url = "http://localhost:1234/v1/models",     auth_env = nil },
  mlx        = { url = "http://localhost:8080/v1/models",     auth_env = nil },
}

local function cache_path(provider) return cache_dir .. "/" .. provider .. ".json" end

function M.read(provider)
  local f = io.open(cache_path(provider), "r")
  if not f then return {} end
  local body = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, body)
  return (ok and type(data) == "table") and data or {}
end

local function write(provider, ids)
  local f = io.open(cache_path(provider), "w")
  if not f then return end
  f:write(vim.json.encode(ids))
  f:close()
end

local function fetch(provider)
  local spec = fetchable[provider]
  if not spec then
    vim.notify("avante-models: unknown provider " .. provider, vim.log.levels.WARN)
    return nil
  end

  local headers = { Accept = "application/json" }
  if spec.auth_env then
    local key = vim.env[spec.auth_env]
    if key and key ~= "" then headers.Authorization = "Bearer " .. key end
  end

  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    vim.notify("avante-models: plenary.curl not available", vim.log.levels.ERROR)
    return nil
  end

  local resp = curl.get(spec.url, { headers = headers, timeout = 10000 })
  if not resp or resp.status ~= 200 then
    vim.notify(
      ("avante-models: %s -> HTTP %s"):format(provider, resp and resp.status or "?"),
      vim.log.levels.ERROR
    )
    return nil
  end

  local jok, body = pcall(vim.json.decode, resp.body)
  if not jok or type(body) ~= "table" or type(body.data) ~= "table" then
    vim.notify("avante-models: failed to parse " .. provider .. " response", vim.log.levels.ERROR)
    return nil
  end

  local ids = {}
  for _, m in ipairs(body.data) do
    if type(m.id) == "string" then table.insert(ids, m.id) end
  end
  table.sort(ids)
  return ids
end

function M.refresh(provider)
  local targets = provider and { provider } or vim.tbl_keys(fetchable)
  for _, p in ipairs(targets) do
    local ids = fetch(p)
    if ids then
      write(p, ids)
      pcall(function()
        local Config = require("avante.config")
        if Config.providers[p] then Config.providers[p].model_names = ids end
        rawset(require("avante.providers"), p, nil)
      end)
      vim.notify(
        ("avante-models: cached %d %s models"):format(#ids, p),
        vim.log.levels.INFO
      )
    end
  end
end

function M.providers() return vim.tbl_keys(fetchable) end

return M

if vim.b.did_orgdown_ftplugin then
  return
end
vim.b.did_orgdown_ftplugin = true
local ok, _ = pcall(require, "orgdown")
if not ok then
  return
end
local config_ok, config = pcall(require, "orgdown.config")
if not config_ok then
  return
end
local bufnr = vim.api.nvim_get_current_buf()
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"
local function setup_module(module_name, setup_fn)
  if config.get("modules." .. module_name) then
    local mod_ok, mod = pcall(require, "orgdown." .. module_name)
    if mod_ok and setup_fn then
      pcall(setup_fn, mod, bufnr)
    end
  end
end
setup_module("preview", function(mod, buf)
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
setup_module("agenda", function(mod, buf)
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
setup_module("babel", function(mod, buf)
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
setup_module("navigation", function(mod, buf)
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
setup_module("folding", function(mod, buf)
  if mod.enable then
    mod.enable(buf)
  end
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
setup_module("capture", function(mod, buf)
  if mod.setup_keymaps then
    mod.setup_keymaps(buf)
  end
end)
local events_ok, events = pcall(require, "orgdown.events")
if events_ok then
  events.emit(events.EVENTS.BUFFER_ENTERED, { bufnr = bufnr })
end

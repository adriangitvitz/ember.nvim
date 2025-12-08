local M = {}
M.loaded = {}
M.deferred = {}
local function get_ember_path()
  return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
end
function M.add_to_rtp(path)
  if not vim.uv.fs_stat(path) then
    return false
  end
  vim.opt.runtimepath:prepend(path)
  local after = path .. "/after"
  if vim.uv.fs_stat(after) then
    vim.opt.runtimepath:append(after)
  end
  local lua_path = path .. "/lua"
  if vim.uv.fs_stat(lua_path) then
    package.path = lua_path .. "/?.lua;" .. lua_path .. "/?/init.lua;" .. package.path
  end
  return true
end
function M.load_plugin(name, opts)
  opts = opts or {}
  if M.loaded[name] then
    return true
  end
  local ember_path = get_ember_path()
  local plugin_path = ember_path .. "/lua/plugins/" .. name
  if not M.add_to_rtp(plugin_path) then
    if not opts.silent then
      vim.notify("[ember] Plugin not found: " .. name, vim.log.levels.WARN)
    end
    return false
  end
  M.loaded[name] = true
  if opts.setup then
    local ok, err = pcall(opts.setup)
    if not ok and not opts.silent then
      vim.notify("[ember] Failed to setup " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
  end
  local plugin_dir = plugin_path .. "/plugin"
  if vim.uv.fs_stat(plugin_dir) then
    for _, file in ipairs(vim.fn.readdir(plugin_dir)) do
      local filepath = plugin_dir .. "/" .. file
      if file:match("%.lua$") then
        vim.cmd("source " .. vim.fn.fnameescape(filepath))
      elseif file:match("%.vim$") then
        vim.cmd("source " .. vim.fn.fnameescape(filepath))
      end
    end
  end
  return true
end
function M.load_external(path, opts)
  opts = opts or {}
  if not vim.uv.fs_stat(path) then
    if not opts.silent then
      vim.notify("[ember] External plugin not found: " .. path, vim.log.levels.WARN)
    end
    return false
  end
  M.add_to_rtp(path)
  if opts.setup then
    local ok, err = pcall(opts.setup)
    if not ok and not opts.silent then
      vim.notify("[ember] Failed to setup external plugin: " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
  end
  return true
end
function M.on_event(events, name, opts)
  if type(events) == "string" then
    events = { events }
  end
  table.insert(M.deferred, { name = name, events = events, opts = opts })
  vim.api.nvim_create_autocmd(events, {
    once = true,
    callback = function()
      M.load_plugin(name, opts)
    end,
  })
end
function M.on_cmd(cmds, name, opts)
  if type(cmds) == "string" then
    cmds = { cmds }
  end
  for _, cmd in ipairs(cmds) do
    vim.api.nvim_create_user_command(cmd, function(args)
      vim.api.nvim_del_user_command(cmd)
      M.load_plugin(name, opts)
      vim.cmd(cmd .. " " .. args.args)
    end, { nargs = "*", complete = opts.complete })
  end
end
function M.on_keys(keys, name, opts)
  if type(keys) == "string" then
    keys = { { keys } }
  elseif type(keys[1]) == "string" then
    keys = { keys }
  end
  for _, key in ipairs(keys) do
    local lhs = key[1] or key.lhs
    local mode = key.mode or "n"
    local rhs = key[2] or key.rhs
    vim.keymap.set(mode, lhs, function()
      pcall(vim.keymap.del, mode, lhs)
      M.load_plugin(name, opts)
      if rhs then
        if type(rhs) == "function" then
          rhs()
        else
          vim.cmd(rhs:gsub("^<cmd>", ""):gsub("<CR>$", ""))
        end
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "m", false)
      end
    end, { desc = key.desc })
  end
end
function M.load_all_bundled()
  local ember_path = get_ember_path()
  local plugins_dir = ember_path .. "/lua/plugins"
  if not vim.uv.fs_stat(plugins_dir) then
    return
  end
  for _, name in ipairs(vim.fn.readdir(plugins_dir)) do
    local plugin_path = plugins_dir .. "/" .. name
    if vim.fn.isdirectory(plugin_path) == 1 then
      M.add_to_rtp(plugin_path)
      M.loaded[name] = true
    end
  end
end
function M.setup_treesitter()
  local data_path = vim.fn.stdpath("data")
  local ts_path = data_path .. "/site/pack/ember/start/nvim-treesitter"
  if not vim.uv.fs_stat(ts_path) then
    vim.notify("[ember] Installing nvim-treesitter...", vim.log.levels.INFO)
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/nvim-treesitter/nvim-treesitter.git",
      ts_path,
    })
    vim.notify("[ember] nvim-treesitter installed. Please restart Neovim.", vim.log.levels.INFO)
  end
end
function M.refresh()
  if vim.loader then
    vim.loader.reset()
  end
end
function M.disable_builtins()
  local disabled = {
    "gzip",
    "matchit",
    "matchparen",
    "tarPlugin",
    "tohtml",
    "tutor",
    "zipPlugin",
  }
  for _, plugin in ipairs(disabled) do
    vim.g["loaded_" .. plugin] = 1
  end
end
return M

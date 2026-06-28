local M = {}
M.current = nil
M.available = {}

-- Get ember's colors directory
local function get_colors_path()
  local ember_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  return ember_path .. "/colors"
end

-- Load a theme by name
function M.load(name)
  -- Clear all highlights
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  -- Load colorscheme
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if ok then
    M.current = name
    -- Emit event for plugins to react
    vim.api.nvim_exec_autocmds("User", { pattern = "EmberThemeChanged" })
    return true
  else
    vim.notify("[ember] Failed to load theme: " .. name .. " - " .. tostring(err), vim.log.levels.ERROR)
    return false, err
  end
end

-- List available themes from ember's colors/ directory
function M.list()
  local colors_path = get_colors_path()
  local themes = {}

  if vim.uv.fs_stat(colors_path) then
    for _, file in ipairs(vim.fn.readdir(colors_path)) do
      if file:match("%.lua$") then
        local name = file:gsub("%.lua$", "")
        table.insert(themes, name)
      end
    end
  end

  table.sort(themes)
  return themes
end

-- Get current theme
function M.get_current()
  return M.current or vim.g.colors_name
end

-- Setup commands
function M.setup()
  -- :Theme <name> - switch to a theme
  vim.api.nvim_create_user_command("Theme", function(opts)
    M.load(opts.args)
  end, {
    nargs = 1,
    complete = function()
      return M.list()
    end,
    desc = "Switch to a theme",
  })

  -- :ThemeList - list available themes
  vim.api.nvim_create_user_command("ThemeList", function()
    local themes = M.list()
    if #themes > 0 then
      local current = M.get_current()
      local lines = {}
      for _, theme in ipairs(themes) do
        if theme == current then
          table.insert(lines, "* " .. theme .. " (current)")
        else
          table.insert(lines, "  " .. theme)
        end
      end
      print("Available themes:\n" .. table.concat(lines, "\n"))
    else
      print("No themes found in colors/ directory")
    end
  end, {
    desc = "List available themes",
  })

  -- :ThemeReload - reload current theme
  vim.api.nvim_create_user_command("ThemeReload", function()
    local current = M.get_current()
    if current then
      M.load(current)
      print("Reloaded theme: " .. current)
    else
      print("No theme currently loaded")
    end
  end, {
    desc = "Reload current theme",
  })
end

return M

local M = {}
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error_fn = health.error or health.report_error
local info = health.info or health.report_info
local function check_neovim_version()
  start("Neovim version")
  local version = vim.version()
  local version_str = string.format("%d.%d.%d", version.major, version.minor, version.patch)
  if version.major > 0 or (version.major == 0 and version.minor >= 9) then
    ok("Neovim version: " .. version_str .. " (>= 0.9 required)")
  else
    error_fn("Neovim version: " .. version_str .. " (requires >= 0.9)")
  end
end
local function check_treesitter()
  start("Treesitter")
  local ts_ok, _ = pcall(require, "nvim-treesitter")
  if ts_ok then
    ok("nvim-treesitter is installed")
  else
    info("nvim-treesitter is not installed (optional, but recommended)")
  end
  local has_markdown = pcall(vim.treesitter.language.inspect, "markdown")
  if has_markdown then
    ok("Markdown parser is available")
  else
    warn("Markdown parser not found. Install with :TSInstall markdown")
  end
  local has_inline = pcall(vim.treesitter.language.inspect, "markdown_inline")
  if has_inline then
    ok("Markdown inline parser is available")
  else
    warn("Markdown inline parser not found. Install with :TSInstall markdown_inline")
  end
end
local function check_babel_languages()
  start("Babel (code execution)")
  local languages = {
    { name = "Python", cmd = "python3", alt = "python" },
    { name = "Node.js", cmd = "node" },
    { name = "Shell", cmd = "bash", alt = "sh" },
  }
  for _, lang in ipairs(languages) do
    local cmd = lang.cmd
    local found = vim.fn.executable(cmd) == 1
    if not found and lang.alt then
      cmd = lang.alt
      found = vim.fn.executable(cmd) == 1
    end
    if found then
      ok(lang.name .. " is available: " .. cmd)
    else
      info(lang.name .. " not found (" .. lang.cmd .. "). Code blocks in this language won't execute.")
    end
  end
  ok("Lua is available (built-in)")
end
local function check_configuration()
  start("Configuration")
  local config_ok, config = pcall(require, "orgdown.config")
  if not config_ok then
    error_fn("Failed to load config module")
    return
  end
  ok("Config module loaded")
  local modules = { "preview", "agenda", "babel", "folding", "navigation", "capture" }
  local enabled_count = 0
  for _, mod in ipairs(modules) do
    if config.get("modules." .. mod) then
      enabled_count = enabled_count + 1
    end
  end
  info(enabled_count .. "/" .. #modules .. " modules enabled")
  local agenda_files = config.get("agenda.files") or {}
  if #agenda_files > 0 then
    ok("Agenda files configured: " .. #agenda_files .. " file patterns")
  else
    info("No agenda files configured (set agenda.files in setup)")
  end
  local capture_file = config.get("capture.default_file")
  if capture_file then
    local expanded = vim.fn.expand(capture_file)
    if vim.fn.filereadable(expanded) == 1 then
      ok("Capture file exists: " .. capture_file)
    else
      info("Capture file doesn't exist yet: " .. capture_file)
    end
  end
end
local function check_plugin()
  start("Plugin status")
  if vim.g.loaded_orgdown then
    ok("Plugin is loaded")
  else
    warn("Plugin not loaded. Did you run require('orgdown').setup()?")
  end
  local modules = {
    "orgdown.preview",
    "orgdown.agenda",
    "orgdown.babel",
    "orgdown.navigation",
    "orgdown.folding",
    "orgdown.capture",
  }
  local all_ok = true
  for _, mod in ipairs(modules) do
    local mod_ok, err = pcall(require, mod)
    if not mod_ok then
      warn("Failed to load " .. mod .. ": " .. tostring(err))
      all_ok = false
    end
  end
  if all_ok then
    ok("All modules can be loaded")
  end
end
function M.check()
  check_neovim_version()
  check_treesitter()
  check_babel_languages()
  check_configuration()
  check_plugin()
end
return M

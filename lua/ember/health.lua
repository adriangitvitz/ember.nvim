local M = {}
local health = vim.health
function M.check()
  health.start("ember.nvim")
  local nvim_version = vim.version()
  local version_str = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)
  if nvim_version.major == 0 and nvim_version.minor < 10 then
    health.error("Neovim 0.10+ required, found " .. version_str)
  else
    health.ok("Neovim version: " .. version_str)
  end
  health.start("Dependencies")
  local deps = {
    { cmd = "git", name = "Git" },
    { cmd = "rg", name = "ripgrep" },
    { cmd = "fd", name = "fd-find" },
  }
  for _, dep in ipairs(deps) do
    if vim.fn.executable(dep.cmd) == 1 then
      health.ok(dep.name .. " found")
    else
      health.warn(dep.name .. " not found (some features may not work)")
    end
  end
  health.start("Language Servers")
  local lsp_servers = {
    { cmd = "pyright-langserver", name = "Pyright (Python)" },
    { cmd = "lua-language-server", name = "lua_ls (Lua)" },
    { cmd = "typescript-language-server", name = "ts_ls (TypeScript)" },
    { cmd = "zls", name = "ZLS (Zig)" },
    { cmd = "clangd", name = "clangd (C/C++)" },
    { cmd = "rust-analyzer", name = "rust-analyzer (Rust)" },
    { cmd = "gopls", name = "gopls (Go)" },
    { cmd = "crystalline", name = "crystalline (Crystal)" },
    { cmd = "ols", name = "OLS (Odin)" },
    { cmd = "nimlangserver", name = "nimlangserver (Nim)" },
  }
  local found_count = 0
  for _, server in ipairs(lsp_servers) do
    if vim.fn.executable(server.cmd) == 1 then
      health.ok(server.name)
      found_count = found_count + 1
    else
      health.info(server.name .. " not installed (will be skipped)")
    end
  end
  if found_count == 0 then
    health.warn("No LSP servers found. Install servers for your languages.")
  end
  health.start("Formatters")
  local formatters = {
    { cmd = "ruff", name = "ruff (Python)" },
    { cmd = "stylua", name = "stylua (Lua)" },
    { cmd = "prettierd", name = "prettierd (JS/TS)" },
    { cmd = "rustfmt", name = "rustfmt (Rust)" },
    { cmd = "gofumpt", name = "gofumpt (Go)" },
    { cmd = "clang-format", name = "clang-format (C/C++)" },
  }
  for _, fmt in ipairs(formatters) do
    if vim.fn.executable(fmt.cmd) == 1 then
      health.ok(fmt.name)
    else
      health.info(fmt.name .. " not installed")
    end
  end
  health.start("Optional CLI Tools")
  local tools = {
    { cmd = "pm", name = "pm-cli (Project Manager)" },
    { cmd = "dn-tui", name = "dn-tui (Notes)", path = vim.fn.expand("~/Projects/organized/lua/dn-tui/build/dn-tui") },
    { cmd = "lazygit", name = "lazygit" },
  }
  for _, tool in ipairs(tools) do
    local found = vim.fn.executable(tool.cmd) == 1
    if not found and tool.path then
      found = vim.fn.filereadable(tool.path) == 1
    end
    if found then
      health.ok(tool.name)
    else
      health.info(tool.name .. " not installed (optional)")
    end
  end
  health.start("Bundled Plugins")
  local ember_path = require("ember").path
  local bundled = {
    "lsp-enhanced",
    "slimline",
    "autopairs",
    "miniterm",
    "pm",
    "pyeval",
    "quicksearch",
    "notelinks",
  }
  for _, plugin in ipairs(bundled) do
    local plugin_path = ember_path .. "/lua/plugins/" .. plugin .. "-plugin/lua/" .. plugin
    if vim.fn.isdirectory(plugin_path) == 1 then
      health.ok(plugin)
    else
      health.error(plugin .. " not found at " .. plugin_path)
    end
  end
  health.start("Colorscheme")
  local colors_path = ember_path .. "/colors/midnight-ember.vim"
  if vim.fn.filereadable(colors_path) == 1 then
    health.ok("midnight-ember colorscheme found")
  else
    health.error("midnight-ember colorscheme not found")
  end
end
return M

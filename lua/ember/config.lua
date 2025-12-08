local M = {}
M.defaults = {
  core = {
    options = true,
    keymaps = true,
    autocmds = true,
    performance = true,
  },
  plugins = {
    editor = {
      enabled = true,
      autopairs = { enabled = true },
      bookmarks = { enabled = true },
      ["which-key"] = { enabled = true },
      gitsigns = { enabled = true },
      diffview = { enabled = true },
      ["todo-comments"] = { enabled = true },
    },
    lsp = {
      enabled = true,
      ["lsp-enhanced"] = { enabled = true },
      conform = { enabled = true },
    },
    ui = {
      enabled = true,
      slimline = { enabled = true },
      telescope = { enabled = true },
      alpha = { enabled = true },
    },
    tools = {
      enabled = true,
      pm = { enabled = true },
      learn = { enabled = true },
      pyeval = { enabled = true },
      miniterm = { enabled = true },
      quicksearch = { enabled = true },
      notelink = { enabled = true },
    },
    syntax = {
      enabled = true,
    },
  },
  lsp = {
    keymaps = { enabled = true },
    handlers = {
      hover = { border = "rounded" },
      diagnostic = { virtual_text = true },
    },
    langs = {
      python = { enabled = true },
      lua = { enabled = true },
      typescript = { enabled = true },
      zig = { enabled = true },
      c = { enabled = true },
      rust = { enabled = true },
      go = { enabled = true },
      crystal = { enabled = true },
      odin = { enabled = true },
      nim = { enabled = true },
    },
  },
  ui = {
    colorscheme = "midnight-ember",
    transparent = false,
    border = "rounded",
    italics = true,
  },
  netrw = {
    enabled = true,
  },
}
M.config = {}
function M.setup(user_config)
  M.config = vim.deepcopy(M.defaults)
  local ok, user_file_config = pcall(require, "user.config")
  if ok and type(user_file_config) == "table" then
    M.config = vim.tbl_deep_extend("force", M.config, user_file_config)
  end
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end
  return M.config
end
function M.get(path)
  local parts = vim.split(path, ".", { plain = true })
  local value = M.config
  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[part]
  end
  return value
end
setmetatable(M, {
  __index = function(_, key)
    return M.config[key]
  end,
})
return M

local M = {}
local expr = require("orgdown.folding.expr")
M.foldexpr = expr.foldexpr
M.foldtext = expr.foldtext
function M.toggle()
  local line = vim.fn.line(".")
  local foldclosed = vim.fn.foldclosed(line)
  if foldclosed == -1 then
    pcall(vim.cmd, "normal! zc")
  else
    vim.cmd("normal! zo")
  end
end
function M.toggle_recursive()
  local line = vim.fn.line(".")
  local foldclosed = vim.fn.foldclosed(line)
  if foldclosed == -1 then
    pcall(vim.cmd, "normal! zC")
  else
    vim.cmd("normal! zO")
  end
end
function M.close_all()
  vim.cmd("normal! zM")
end
function M.open_all()
  vim.cmd("normal! zR")
end
function M.close_to_level(level)
  vim.cmd("normal! zM")
  for _ = 1, level do
    vim.cmd("normal! zr")
  end
end
function M.apply_initial_state(bufnr)
  local config = require("orgdown.config")
  local state = config.get("folding.default_state")
  vim.api.nvim_buf_call(bufnr, function()
    if state == "all_closed" then
      M.close_all()
    elseif state == "all_open" then
      M.open_all()
    elseif state == "top_level" then
      M.close_to_level(1)
    end
  end)
end
function M.enable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_call(bufnr, function()
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.require('orgdown.folding').foldexpr(v:lnum)"
    vim.wo.foldtext = "v:lua.require('orgdown.folding').foldtext()"
    vim.wo.foldenable = true
    vim.wo.foldlevel = 99
  end)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      M.apply_initial_state(bufnr)
    end
  end, 10)
end
function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_call(bufnr, function()
    vim.wo.foldmethod = "manual"
    vim.wo.foldenable = false
  end)
end
function M.setup_keymaps(bufnr)
  local config = require("orgdown.config")
  local keymaps = config.get("keymaps")
  local function map(key, fn, desc)
    if key and key ~= false then
      vim.keymap.set("n", key, fn, {
        buffer = bufnr,
        desc = desc,
        silent = true,
      })
    end
  end
  map(keymaps.fold_toggle, M.toggle, "Toggle fold")
  map(keymaps.fold_all, M.close_all, "Close all folds")
  map(keymaps.unfold_all, M.open_all, "Open all folds")
end
function M.setup_commands()
  vim.api.nvim_create_user_command("OrgdownFoldAll", function()
    M.close_all()
  end, { desc = "Close all folds" })
  vim.api.nvim_create_user_command("OrgdownUnfoldAll", function()
    M.open_all()
  end, { desc = "Open all folds" })
  vim.api.nvim_create_user_command("OrgdownFoldLevel", function(opts)
    local level = tonumber(opts.args)
    if level then
      M.close_to_level(level)
    end
  end, { desc = "Close folds to level", nargs = 1 })
end
function M.setup()
  M.setup_commands()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "orgdown" },
    callback = function(args)
      local config = require("orgdown.config")
      if config.get("modules.folding") then
        M.enable(args.buf)
        M.setup_keymaps(args.buf)
      end
    end,
    group = vim.api.nvim_create_augroup("orgdown_folding", { clear = true }),
  })
end
return M

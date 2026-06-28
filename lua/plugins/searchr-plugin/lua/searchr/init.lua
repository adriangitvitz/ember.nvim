-- searchr/init.lua - Main entry point for searchr plugin
-- A minimal, fast search/replace plugin for Neovim

local M = {}

-- Setup the plugin
function M.setup(opts)
  local config = require("searchr.config")
  local utils = require("searchr.utils")

  -- Merge user config
  config.setup(opts)
  local cfg = config.get()

  -- Check for ripgrep
  if not utils.is_executable(cfg.rg_path) then
    utils.notify("ripgrep (rg) not found. Please install ripgrep.", vim.log.levels.ERROR)
    return
  end

  -- Create commands
  M.create_commands()

  -- Setup keymaps
  M.setup_keymaps()
end

-- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command("Searchr", function(args)
    local pattern = args.args ~= "" and args.args or nil
    require("searchr.ui").open({ pattern = pattern })
  end, {
    nargs = "?",
    desc = "Open searchr",
  })

  vim.api.nvim_create_user_command("SearchrWord", function()
    M.search_word()
  end, {
    desc = "Search word under cursor",
  })

  vim.api.nvim_create_user_command("SearchrVisual", function()
    M.search_visual()
  end, {
    range = true,
    desc = "Search visual selection",
  })

  vim.api.nvim_create_user_command("SearchrReplace", function(args)
    local parts = vim.split(args.args, "/", { plain = true })
    if #parts >= 2 then
      require("searchr.ui").open({
        pattern = parts[1],
        replacement = parts[2],
      })
    else
      require("searchr.ui").open()
    end
  end, {
    nargs = "?",
    desc = "Open searchr with replacement",
  })

  vim.api.nvim_create_user_command("SearchrToggle", function()
    require("searchr.ui").toggle()
  end, {
    desc = "Toggle searchr",
  })

  vim.api.nvim_create_user_command("SearchrQuickfix", function()
    require("searchr.ui").to_quickfix()
  end, {
    desc = "Send searchr results to quickfix",
  })
end

-- Setup global keymaps
function M.setup_keymaps()
  local config = require("searchr.config")
  local cfg = config.get()

  if cfg.keymaps.open then
    vim.keymap.set("n", cfg.keymaps.open, function()
      require("searchr.ui").open()
    end, { desc = "Open searchr" })
  end

  if cfg.keymaps.open_word then
    vim.keymap.set("n", cfg.keymaps.open_word, function()
      M.search_word()
    end, { desc = "Search word under cursor" })

    vim.keymap.set("v", cfg.keymaps.open_word, function()
      M.search_visual()
    end, { desc = "Search visual selection" })
  end
end

-- Search word under cursor
function M.search_word()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    require("searchr.ui").open({ pattern = word })
  end
end

-- Search visual selection
function M.search_visual()
  local utils = require("searchr.utils")
  local selection = utils.get_visual_selection()
  if selection and selection ~= "" then
    require("searchr.ui").open({ pattern = selection })
  end
end

-- Open UI (convenience function)
function M.open(opts)
  require("searchr.ui").open(opts)
end

-- Close UI
function M.close()
  require("searchr.ui").close()
end

-- Toggle UI
function M.toggle()
  require("searchr.ui").toggle()
end

-- Send to quickfix
function M.to_quickfix()
  require("searchr.ui").to_quickfix()
end

-- Send to picker
function M.to_picker()
  require("searchr.ui").to_picker()
end

-- Get search results
function M.get_results()
  local search = require("searchr.search")
  return search.get_results()
end

return M

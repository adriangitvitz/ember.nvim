local M = {}
local headings = require("orgdown.navigation.headings")
local links = require("orgdown.navigation.links")
local outline = require("orgdown.navigation.outline")
M.headings = headings
M.links = links
M.outline = outline
function M.next_heading()
  if not headings.next_heading() then
    vim.notify("No more headings", vim.log.levels.INFO)
  end
end
function M.prev_heading()
  if not headings.prev_heading() then
    vim.notify("No previous heading", vim.log.levels.INFO)
  end
end
function M.parent_heading()
  if not headings.parent_heading() then
    vim.notify("No parent heading", vim.log.levels.INFO)
  end
end
function M.next_sibling()
  if not headings.next_sibling() then
    vim.notify("No next sibling", vim.log.levels.INFO)
  end
end
function M.prev_sibling()
  if not headings.prev_sibling() then
    vim.notify("No previous sibling", vim.log.levels.INFO)
  end
end
function M.follow_link()
  links.follow()
end
function M.go_back()
  if not links.go_back() then
    vim.notify("No history", vim.log.levels.INFO)
  end
end
function M.insert_link()
  links.insert_link()
end
function M.toggle_outline()
  outline.toggle()
end
function M.open_outline()
  outline.open()
end
function M.close_outline()
  outline.close()
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
  map(keymaps.next_heading, M.next_heading, "Next heading")
  map(keymaps.prev_heading, M.prev_heading, "Previous heading")
  map(keymaps.parent_heading, M.parent_heading, "Parent heading")
  map(keymaps.next_sibling, M.next_sibling, "Next sibling heading")
  map(keymaps.prev_sibling, M.prev_sibling, "Previous sibling heading")
  map(keymaps.follow_link, M.follow_link, "Follow link")
  map(keymaps.go_back, M.go_back, "Go back")
  map(keymaps.insert_link, M.insert_link, "Insert link to note")
  map(keymaps.outline_toggle, M.toggle_outline, "Toggle outline")
end
function M.setup_commands()
  vim.api.nvim_create_user_command("OrgdownOutline", function()
    M.toggle_outline()
  end, { desc = "Toggle document outline" })
  vim.api.nvim_create_user_command("OrgdownFollowLink", function()
    M.follow_link()
  end, { desc = "Follow link under cursor" })
  vim.api.nvim_create_user_command("OrgdownGoBack", function()
    M.go_back()
  end, { desc = "Go back in navigation history" })
  vim.api.nvim_create_user_command("OrgdownInsertLink", function()
    M.insert_link()
  end, { desc = "Insert link to note at cursor" })
end
function M.setup()
  M.setup_commands()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "orgdown" },
    callback = function(args)
      local config = require("orgdown.config")
      if config.get("modules.navigation") then
        M.setup_keymaps(args.buf)
      end
    end,
    group = vim.api.nvim_create_augroup("orgdown_navigation", { clear = true }),
  })
end
return M

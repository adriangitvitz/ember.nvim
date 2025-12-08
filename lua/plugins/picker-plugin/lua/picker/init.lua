local M = {}
function M.setup(opts)
  require("picker.config").setup(opts)
  M.create_commands()
  M.create_keymaps()
  M.setup_highlights()
end
function M.create_commands()
  local cmd = vim.api.nvim_create_user_command
  cmd("PickerFiles", function(args)
    M.files({ cwd = args.args ~= "" and args.args or nil })
  end, { nargs = "?", complete = "dir", desc = "Find files" })
  cmd("PickerDirs", function(args)
    M.directories({ cwd = args.args ~= "" and args.args or nil })
  end, { nargs = "?", complete = "dir", desc = "Find directories" })
  cmd("PickerGrep", function(args)
    M.grep(args.args ~= "" and args.args or nil)
  end, { nargs = "?", desc = "Grep with pattern" })
  cmd("PickerLiveGrep", function()
    M.live_grep()
  end, { desc = "Live grep" })
  cmd("PickerBuffers", function()
    M.buffers()
  end, { desc = "List buffers" })
  cmd("PickerRecent", function()
    M.recent()
  end, { desc = "Recent files" })
  cmd("PickerDefinitions", function()
    M.lsp_definitions()
  end, { desc = "LSP definitions" })
  cmd("PickerReferences", function()
    M.lsp_references()
  end, { desc = "LSP references" })
  cmd("PickerSymbols", function()
    M.lsp_document_symbols()
  end, { desc = "LSP document symbols" })
  cmd("PickerWorkspaceSymbols", function(args)
    M.lsp_workspace_symbols({ query = args.args })
  end, { nargs = "?", desc = "LSP workspace symbols" })
  cmd("PickerDiagnostics", function()
    M.lsp_diagnostics()
  end, { desc = "LSP diagnostics" })
  cmd("PickerHelp", function()
    M.help_tags()
  end, { desc = "Help tags" })
end
function M.create_keymaps()
  local map = vim.keymap.set
  map("n", "<leader>ff", function() M.files() end, { desc = "Find files" })
  map("n", "<leader>fg", function() M.live_grep() end, { desc = "Live grep" })
  map("n", "<leader>fb", function() M.buffers() end, { desc = "Buffers" })
  map("n", "<leader>fr", function() M.recent() end, { desc = "Recent files" })
  map("n", "<leader>fw", function() M.grep_word() end, { desc = "Grep word" })
  map("v", "<leader>fw", function() M.grep_visual() end, { desc = "Grep selection" })
  map("n", "<leader>fd", function() M.directories() end, { desc = "Find directories" })
  map("n", "<leader>fh", function() M.help_tags() end, { desc = "Help tags" })
  map("n", "<leader>ls", function() M.lsp_document_symbols() end, { desc = "Document symbols" })
  map("n", "<leader>lS", function() M.lsp_workspace_symbols() end, { desc = "Workspace symbols" })
  map("n", "<leader>ld", function() M.lsp_diagnostics() end, { desc = "Diagnostics" })
  map("n", "<leader>lr", function() M.lsp_references() end, { desc = "References" })
  map("n", "<leader>sf", function() M.files() end, { desc = "Search files" })
  map("n", "<leader>sg", function() M.live_grep() end, { desc = "Search grep" })
  map("n", "<leader>sb", function() M.buffers() end, { desc = "Search buffers" })
  map("n", "<leader>sr", function() M.recent() end, { desc = "Search recent" })
  map("n", "<leader>sh", function() M.help_tags() end, { desc = "Search help" })
end
function M.setup_highlights()
  vim.api.nvim_set_hl(0, "PickerBorder", { link = "FloatBorder", default = true })
  vim.api.nvim_set_hl(0, "PickerPrompt", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "PickerMatch", { link = "Search", default = true })
end
function M.files(opts)
  require("picker.sources.files").find_files(opts)
end
function M.directories(opts)
  require("picker.sources.files").find_directories(opts)
end
function M.find_all(opts)
  require("picker.sources.files").find_all(opts)
end
function M.grep(pattern, opts)
  require("picker.sources.grep").grep(pattern, opts)
end
function M.live_grep(opts)
  require("picker.sources.grep").live_grep(opts)
end
function M.grep_buffer(pattern, opts)
  require("picker.sources.grep").grep_buffer(pattern, opts)
end
function M.buffers(opts)
  require("picker.sources.buffers").buffers(opts)
end
function M.delete_buffers(opts)
  require("picker.sources.buffers").delete_buffers(opts)
end
function M.recent(opts)
  require("picker.sources.recent").recent(opts)
end
function M.recent_project(opts)
  require("picker.sources.recent").recent_project(opts)
end
function M.lsp_definitions(opts)
  require("picker.sources.lsp").definitions(opts)
end
function M.lsp_references(opts)
  require("picker.sources.lsp").references(opts)
end
function M.lsp_implementations(opts)
  require("picker.sources.lsp").implementations(opts)
end
function M.lsp_type_definitions(opts)
  require("picker.sources.lsp").type_definitions(opts)
end
function M.lsp_document_symbols(opts)
  require("picker.sources.lsp").document_symbols(opts)
end
function M.lsp_workspace_symbols(opts)
  require("picker.sources.lsp").workspace_symbols(opts)
end
function M.lsp_diagnostics(opts)
  require("picker.sources.lsp").diagnostics(opts)
end
function M.help_tags(opts)
  require("picker.sources.help").help_tags(opts)
end
function M.help_grep(opts)
  require("picker.sources.help").help_grep(opts)
end
function M.grep_word()
  local word = vim.fn.expand("<cword>")
  if word ~= "" then
    M.grep(word)
  end
end
function M.grep_visual()
  local utils = require("picker.utils")
  local selection = utils.get_visual_selection()
  if selection and selection ~= "" then
    M.grep(selection)
  end
end
function M.run(opts)
  require("picker.fzf").run(opts)
end
return M

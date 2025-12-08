local M = {}
M.keywords = {
  TODO = { icon = " ", color = "#7ebae4", alt = { "todo" } },
  FIX = { icon = " ", color = "#f7768e", alt = { "FIXME", "BUG", "FIXIT", "ISSUE", "fix", "fixme", "bug" } },
  HACK = { icon = " ", color = "#e0af68", alt = { "hack" } },
  WARN = { icon = " ", color = "#e0af68", alt = { "WARNING", "XXX", "warn", "warning" } },
  PERF = { icon = " ", color = "#9d7cd8", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE", "perf" } },
  NOTE = { icon = " ", color = "#1abc9c", alt = { "INFO", "note", "info" } },
  TEST = { icon = "⏲ ", color = "#a9b1d6", alt = { "TESTING", "PASSED", "FAILED", "test" } },
}
function M.setup_highlights()
  for kw, opts in pairs(M.keywords) do
    local hl_name = "Todo" .. kw
    vim.api.nvim_set_hl(0, hl_name, { fg = opts.color, bold = true, default = true })
    vim.api.nvim_set_hl(0, hl_name .. "Sign", { fg = opts.color, default = true })
    vim.api.nvim_set_hl(0, hl_name .. "Bg", { fg = opts.color, bg = opts.color, blend = 85, default = true })
  end
end
function M.setup_syntax()
  local all_keywords = {}
  for kw, opts in pairs(M.keywords) do
    table.insert(all_keywords, kw)
    if opts.alt then
      for _, alt in ipairs(opts.alt) do
        table.insert(all_keywords, alt)
      end
    end
  end
  local pattern = table.concat(all_keywords, "\\|")
  vim.cmd(string.format(
    [[syntax match TodoKeyword /\v<(%s):?/ containedin=.*Comment.* contained]],
    pattern
  ))
  for kw, opts in pairs(M.keywords) do
    local keywords_for_hl = { kw }
    if opts.alt then
      vim.list_extend(keywords_for_hl, opts.alt)
    end
    for _, keyword in ipairs(keywords_for_hl) do
      vim.cmd(string.format(
        [[syntax match Todo%s /\v<%s>:?/ containedin=.*Comment.*]],
        kw,
        keyword
      ))
    end
  end
end
function M.search(opts)
  opts = opts or {}
  local keywords = {}
  for kw, kw_opts in pairs(M.keywords) do
    table.insert(keywords, kw)
    if kw_opts.alt then
      vim.list_extend(keywords, kw_opts.alt)
    end
  end
  local pattern = table.concat(keywords, "|")
  pattern = "(" .. pattern .. "):"
  local ok, picker = pcall(require, "picker")
  if ok then
    picker.grep(pattern, { regex = true })
  else
    vim.cmd("vimgrep /" .. pattern .. "/j **/*")
    vim.cmd("copen")
  end
end
function M.jump_next()
  local pattern = M.get_search_pattern()
  vim.fn.search(pattern, "w")
end
function M.jump_prev()
  local pattern = M.get_search_pattern()
  vim.fn.search(pattern, "bw")
end
function M.get_search_pattern()
  local keywords = {}
  for kw, kw_opts in pairs(M.keywords) do
    table.insert(keywords, kw)
    if kw_opts.alt then
      vim.list_extend(keywords, kw_opts.alt)
    end
  end
  return "\\<\\(" .. table.concat(keywords, "\\|") .. "\\)\\>"
end
function M.setup(opts)
  opts = opts or {}
  if opts.keywords then
    M.keywords = vim.tbl_deep_extend("force", M.keywords, opts.keywords)
  end
  M.setup_highlights()
  vim.api.nvim_create_autocmd({ "Syntax" }, {
    group = vim.api.nvim_create_augroup("EmberTodo", { clear = true }),
    callback = function()
      M.setup_syntax()
    end,
  })
  vim.api.nvim_create_user_command("TodoSearch", function()
    M.search()
  end, { desc = "Search for TODOs" })
  vim.api.nvim_create_user_command("TodoNext", function()
    M.jump_next()
  end, { desc = "Jump to next TODO" })
  vim.api.nvim_create_user_command("TodoPrev", function()
    M.jump_prev()
  end, { desc = "Jump to previous TODO" })
  vim.keymap.set("n", "]t", M.jump_next, { desc = "Next TODO" })
  vim.keymap.set("n", "[t", M.jump_prev, { desc = "Previous TODO" })
end
return M

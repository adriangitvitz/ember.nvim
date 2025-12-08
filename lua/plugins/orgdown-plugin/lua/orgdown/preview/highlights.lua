local M = {}
M.defaults = {
  OrgdownH1 = { fg = "#ff79c6", bold = true },
  OrgdownH2 = { fg = "#bd93f9", bold = true },
  OrgdownH3 = { fg = "#8be9fd", bold = true },
  OrgdownH4 = { fg = "#50fa7b" },
  OrgdownH5 = { fg = "#ffb86c" },
  OrgdownH6 = { fg = "#ff5555" },
  OrgdownTodo = { fg = "#ff5555", bold = true },
  OrgdownDone = { fg = "#50fa7b", bold = true },
  OrgdownNext = { fg = "#ffb86c", bold = true },
  OrgdownWaiting = { fg = "#6272a4", bold = true },
  OrgdownLink = { fg = "#8be9fd", underline = true },
  OrgdownLinkText = { fg = "#8be9fd" },
  OrgdownCode = { bg = "#44475a" },
  OrgdownCodeBlock = { bg = "#282a36" },
  OrgdownBlockquote = { fg = "#6272a4", italic = true },
  OrgdownBlockquoteBorder = { fg = "#6272a4" },
  OrgdownCheckbox = { fg = "#ffb86c" },
  OrgdownCheckboxDone = { fg = "#50fa7b" },
  OrgdownBullet = { fg = "#bd93f9" },
  OrgdownListNumber = { fg = "#bd93f9" },
  OrgdownTableBorder = { fg = "#6272a4" },
  OrgdownTableHeader = { bold = true },
  OrgdownHR = { fg = "#6272a4" },
  OrgdownBold = { bold = true },
  OrgdownItalic = { italic = true },
  OrgdownStrikethrough = { strikethrough = true },
  OrgdownImage = { fg = "#50fa7b", italic = true },
}
function M.setup(custom)
  custom = custom or {}
  local highlights = vim.tbl_deep_extend("force", M.defaults, custom)
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end
function M.heading_hl(level)
  level = math.max(1, math.min(6, level))
  return "OrgdownH" .. level
end
function M.todo_hl(state)
  local map = {
    TODO = "OrgdownTodo",
    DONE = "OrgdownDone",
    NEXT = "OrgdownNext",
    WAITING = "OrgdownWaiting",
  }
  return map[state] or "OrgdownTodo"
end
return M

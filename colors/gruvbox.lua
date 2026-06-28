vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "gruvbox"

-- Check if italics are enabled (default true)
local use_italics = true
local ok, config = pcall(require, "ember.config")
if ok and config.config and config.config.ui then
  use_italics = config.config.ui.italics ~= false
end

-- Gruvbox Color Palette (Medium Contrast Dark)
local colors = {
  -- Background
  bg0 = "#282828",    -- main bg
  bg0_h = "#1d2021",  -- darker bg (hard)
  bg0_s = "#32302f",  -- lighter bg (soft)
  bg1 = "#3c3836",    -- lighter bg (statusline)
  bg2 = "#504945",    -- lighter bg (visual)
  bg3 = "#665c54",    -- lighter bg
  bg4 = "#7c6f64",    -- lighter bg

  -- Foreground (adjusted for 7.0-8.6:1 contrast)
  fg0 = "#ccc4a4",    -- brightest fg (8.42:1) - adjusted from #fbf1c7
  fg1 = "#d1bf8f",    -- main fg (8.12:1) - adjusted from #ebdbb2
  fg2 = "#d5c4a1",    -- darker fg (8.59:1) - original passes
  fg3 = "#ccbb9d",    -- darker fg (7.84:1) - adjusted from #bdae93
  fg4 = "#c6b399",    -- gray (7.24:1) - adjusted from #a89984

  -- Bright colors (adjusted for 7.0-8.6:1 contrast)
  red = "#ff9875",       -- (7.02:1) - adjusted from #fb4934
  green = "#b8bb26",     -- (7.14:1) - original passes
  yellow = "#f4b828",    -- (8.24:1) - adjusted from #fabd2f
  blue = "#a0bfb3",      -- (7.44:1) - adjusted from #83a598
  purple = "#fa9bb6",    -- (7.32:1) - adjusted from #d3869b
  aqua = "#8ec07c",      -- (7.01:1) - original passes
  orange = "#ff9b38",    -- (7.02:1) - adjusted from #fe8019

  -- Neutral colors (adjusted for accessibility)
  gray = "#cbb7a4",      -- (7.62:1) - adjusted from #928374

  -- Dark colors (for light elements on dark bg)
  red_dark = "#cc241d",
  green_dark = "#98971a",
  yellow_dark = "#d79921",
  blue_dark = "#458588",
  purple_dark = "#b16286",
  aqua_dark = "#689d6a",
  orange_dark = "#d65d0e",

  none = "NONE",
}

-- Helper function to set highlight
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal", { fg = colors.fg1, bg = colors.bg0 })
hi("NormalFloat", { fg = colors.fg1, bg = colors.bg0_h })
hi("NormalNC", { fg = colors.fg1, bg = colors.bg0 })

hi("Comment", { fg = colors.gray, italic = use_italics })
hi("ColorColumn", { bg = colors.bg1 })

hi("Cursor", { fg = colors.bg0, bg = colors.fg1 })
hi("CursorLine", { bg = colors.bg1 })
hi("CursorLineNr", { fg = colors.yellow, bg = colors.bg1, bold = true })
hi("CursorColumn", { bg = colors.bg1 })

hi("LineNr", { fg = colors.bg4 })
hi("SignColumn", { fg = colors.bg4, bg = colors.bg0 })
hi("FoldColumn", { fg = colors.gray, bg = colors.bg0 })
hi("Folded", { fg = colors.gray, bg = colors.bg1, italic = use_italics })

hi("MatchParen", { fg = colors.none, bg = colors.bg3, bold = true })

hi("Visual", { bg = colors.bg3 })
hi("VisualNOS", { bg = colors.bg3 })

hi("Search", { fg = colors.bg0, bg = colors.yellow })
hi("IncSearch", { fg = colors.bg0, bg = colors.orange, bold = true })
hi("Substitute", { fg = colors.bg0, bg = colors.orange })

hi("Pmenu", { fg = colors.fg1, bg = colors.bg2 })
hi("PmenuSel", { fg = colors.bg2, bg = colors.blue, bold = true })
hi("PmenuSbar", { bg = colors.bg2 })
hi("PmenuThumb", { bg = colors.bg4 })

hi("StatusLine", { fg = colors.fg1, bg = colors.bg2 })
hi("StatusLineNC", { fg = colors.fg4, bg = colors.bg1 })

hi("TabLine", { fg = colors.fg4, bg = colors.bg1 })
hi("TabLineFill", { bg = colors.bg1 })
hi("TabLineSel", { fg = colors.fg1, bg = colors.bg0, bold = true })

hi("VertSplit", { fg = colors.bg3 })
hi("WinSeparator", { fg = colors.bg3 })

hi("WildMenu", { fg = colors.bg0, bg = colors.blue, bold = true })

hi("Directory", { fg = colors.green, bold = true })
hi("Title", { fg = colors.green, bold = true })

hi("ErrorMsg", { fg = colors.red, bg = colors.bg0, bold = true })
hi("WarningMsg", { fg = colors.yellow, bold = true })
hi("ModeMsg", { fg = colors.fg2 })
hi("MoreMsg", { fg = colors.yellow })
hi("Question", { fg = colors.orange })

hi("SpecialKey", { fg = colors.bg4 })
hi("NonText", { fg = colors.bg2 })
hi("Whitespace", { fg = colors.bg2 })
hi("EndOfBuffer", { fg = colors.bg0 })

hi("Conceal", { fg = colors.blue })

hi("FloatBorder", { fg = colors.bg4, bg = colors.bg0_h })
hi("FloatTitle", { fg = colors.green, bg = colors.bg0_h, bold = true })

hi("QuickFixLine", { bg = colors.bg1 })
hi("qfLineNr", { fg = colors.yellow })
hi("qfFileName", { fg = colors.blue })

hi("Constant", { fg = colors.purple })
hi("String", { fg = colors.green })
hi("Character", { fg = colors.purple })
hi("Number", { fg = colors.purple })
hi("Float", { fg = colors.purple })
hi("Boolean", { fg = colors.purple })

hi("Identifier", { fg = colors.blue })
hi("Function", { fg = colors.green, bold = true })

hi("Statement", { fg = colors.red })
hi("Conditional", { fg = colors.red })
hi("Repeat", { fg = colors.red })
hi("Label", { fg = colors.red })
hi("Operator", { fg = colors.fg1 })
hi("Keyword", { fg = colors.red })
hi("Exception", { fg = colors.red })

hi("PreProc", { fg = colors.aqua })
hi("Include", { fg = colors.aqua })
hi("Define", { fg = colors.aqua })
hi("Macro", { fg = colors.aqua })
hi("PreCondit", { fg = colors.aqua })

hi("Type", { fg = colors.yellow })
hi("StorageClass", { fg = colors.orange })
hi("Structure", { fg = colors.aqua })
hi("Typedef", { fg = colors.yellow })

hi("Special", { fg = colors.orange })
hi("SpecialChar", { fg = colors.orange })
hi("Tag", { fg = colors.aqua })
hi("Delimiter", { fg = colors.fg1 })
hi("SpecialComment", { fg = colors.gray, italic = use_italics, bold = true })
hi("Debug", { fg = colors.red })

hi("Underlined", { fg = colors.blue, underline = true })
hi("Ignore", { fg = colors.bg4 })
hi("Error", { fg = colors.red, bold = true })
hi("Todo", { fg = colors.fg0, bg = colors.yellow, bold = true })

hi("DiffAdd", { fg = colors.green, bg = colors.bg0, reverse = true })
hi("DiffChange", { fg = colors.aqua, bg = colors.bg0, reverse = true })
hi("DiffDelete", { fg = colors.red, bg = colors.bg0, reverse = true })
hi("DiffText", { fg = colors.yellow, bg = colors.bg0, reverse = true })

hi("diffAdded", { fg = colors.green })
hi("diffChanged", { fg = colors.aqua })
hi("diffRemoved", { fg = colors.red })
hi("diffFile", { fg = colors.orange, bold = true })
hi("diffLine", { fg = colors.gray })
hi("diffIndexLine", { fg = colors.gray })

hi("DiagnosticError", { fg = colors.red })
hi("DiagnosticWarn", { fg = colors.yellow })
hi("DiagnosticInfo", { fg = colors.blue })
hi("DiagnosticHint", { fg = colors.aqua })
hi("DiagnosticOk", { fg = colors.green })

hi("DiagnosticUnderlineError", { sp = colors.red, underline = true })
hi("DiagnosticUnderlineWarn", { sp = colors.yellow, underline = true })
hi("DiagnosticUnderlineInfo", { sp = colors.blue, underline = true })
hi("DiagnosticUnderlineHint", { sp = colors.aqua, underline = true })
hi("DiagnosticUnderlineOk", { sp = colors.green, underline = true })

hi("DiagnosticVirtualTextError", { fg = colors.red, italic = use_italics })
hi("DiagnosticVirtualTextWarn", { fg = colors.yellow, italic = use_italics })
hi("DiagnosticVirtualTextInfo", { fg = colors.blue, italic = use_italics })
hi("DiagnosticVirtualTextHint", { fg = colors.aqua, italic = use_italics })

hi("DiagnosticSignError", { fg = colors.red })
hi("DiagnosticSignWarn", { fg = colors.yellow })
hi("DiagnosticSignInfo", { fg = colors.blue })
hi("DiagnosticSignHint", { fg = colors.aqua })

hi("DiagnosticFloatingError", { fg = colors.red, bg = colors.bg0_h })
hi("DiagnosticFloatingWarn", { fg = colors.yellow, bg = colors.bg0_h })
hi("DiagnosticFloatingInfo", { fg = colors.blue, bg = colors.bg0_h })
hi("DiagnosticFloatingHint", { fg = colors.aqua, bg = colors.bg0_h })

hi("LspReferenceText", { bg = colors.bg2 })
hi("LspReferenceRead", { bg = colors.bg2 })
hi("LspReferenceWrite", { bg = colors.bg2 })

hi("LspSignatureActiveParameter", { fg = colors.orange, bold = true })
hi("LspCodeLens", { fg = colors.gray, italic = use_italics })
hi("LspCodeLensSeparator", { fg = colors.bg4 })

hi("@variable", { fg = colors.fg1 })
hi("@variable.builtin", { fg = colors.orange })
hi("@variable.parameter", { fg = colors.fg1 })
hi("@variable.member", { fg = colors.blue })

hi("@constant", { fg = colors.purple })
hi("@constant.builtin", { fg = colors.purple })
hi("@constant.macro", { fg = colors.aqua })

hi("@module", { fg = colors.yellow })
hi("@module.builtin", { fg = colors.orange })
hi("@label", { fg = colors.red })

hi("@string", { fg = colors.green })
hi("@string.documentation", { fg = colors.green, italic = use_italics })
hi("@string.escape", { fg = colors.orange })
hi("@string.regexp", { fg = colors.purple })
hi("@string.special", { fg = colors.orange })

hi("@character", { fg = colors.purple })
hi("@character.special", { fg = colors.orange })

hi("@number", { fg = colors.purple })
hi("@number.float", { fg = colors.purple })
hi("@boolean", { fg = colors.purple })

hi("@function", { fg = colors.green, bold = true })
hi("@function.builtin", { fg = colors.yellow, bold = true })
hi("@function.call", { fg = colors.green })
hi("@function.macro", { fg = colors.aqua })
hi("@function.method", { fg = colors.green, bold = true })
hi("@function.method.call", { fg = colors.green })

hi("@constructor", { fg = colors.yellow })

hi("@keyword", { fg = colors.red })
hi("@keyword.coroutine", { fg = colors.red })
hi("@keyword.function", { fg = colors.red })
hi("@keyword.operator", { fg = colors.red })
hi("@keyword.import", { fg = colors.aqua })
hi("@keyword.repeat", { fg = colors.red })
hi("@keyword.return", { fg = colors.red })
hi("@keyword.conditional", { fg = colors.red })
hi("@keyword.exception", { fg = colors.red })
hi("@keyword.directive", { fg = colors.aqua })
hi("@keyword.type", { fg = colors.yellow })

hi("@operator", { fg = colors.fg1 })

hi("@punctuation.delimiter", { fg = colors.fg2 })
hi("@punctuation.bracket", { fg = colors.fg2 })
hi("@punctuation.special", { fg = colors.orange })

hi("@comment", { fg = colors.gray, italic = use_italics })
hi("@comment.documentation", { fg = colors.gray, italic = use_italics })
hi("@comment.error", { fg = colors.red, bold = true })
hi("@comment.warning", { fg = colors.yellow, bold = true })
hi("@comment.todo", { fg = colors.fg0, bg = colors.yellow, bold = true })
hi("@comment.note", { fg = colors.blue, bold = true })

hi("@markup.strong", { fg = colors.fg1, bold = true })
hi("@markup.italic", { fg = colors.fg1, italic = use_italics })
hi("@markup.strikethrough", { fg = colors.gray, strikethrough = true })
hi("@markup.underline", { fg = colors.fg1, underline = true })
hi("@markup.heading", { fg = colors.green, bold = true })
hi("@markup.quote", { fg = colors.gray, italic = use_italics })
hi("@markup.math", { fg = colors.purple })
hi("@markup.link", { fg = colors.blue, underline = true })
hi("@markup.link.label", { fg = colors.purple })
hi("@markup.link.url", { fg = colors.blue, underline = true })
hi("@markup.raw", { fg = colors.aqua })
hi("@markup.list", { fg = colors.red })
hi("@markup.list.checked", { fg = colors.green })
hi("@markup.list.unchecked", { fg = colors.gray })

hi("@tag", { fg = colors.red })
hi("@tag.attribute", { fg = colors.aqua })
hi("@tag.delimiter", { fg = colors.fg2 })

hi("@type", { fg = colors.yellow })
hi("@type.builtin", { fg = colors.yellow })
hi("@type.definition", { fg = colors.yellow })
hi("@type.qualifier", { fg = colors.red })

hi("@attribute", { fg = colors.aqua })
hi("@property", { fg = colors.blue })

hi("@diff.plus", { fg = colors.green })
hi("@diff.minus", { fg = colors.red })
hi("@diff.delta", { fg = colors.aqua })

hi("GitSignsAdd", { fg = colors.green })
hi("GitSignsChange", { fg = colors.aqua })
hi("GitSignsDelete", { fg = colors.red })
hi("GitSignsCurrentLineBlame", { fg = colors.gray, italic = use_italics })

hi("CmpItemAbbr", { fg = colors.fg1 })
hi("CmpItemAbbrDeprecated", { fg = colors.gray, strikethrough = true })
hi("CmpItemAbbrMatch", { fg = colors.yellow, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = colors.orange, bold = true })

hi("CmpItemKindDefault", { fg = colors.fg2 })
hi("CmpItemKindKeyword", { fg = colors.red })
hi("CmpItemKindVariable", { fg = colors.blue })
hi("CmpItemKindConstant", { fg = colors.purple })
hi("CmpItemKindReference", { fg = colors.blue })
hi("CmpItemKindValue", { fg = colors.purple })
hi("CmpItemKindFunction", { fg = colors.green })
hi("CmpItemKindMethod", { fg = colors.green })
hi("CmpItemKindConstructor", { fg = colors.yellow })
hi("CmpItemKindClass", { fg = colors.yellow })
hi("CmpItemKindInterface", { fg = colors.yellow })
hi("CmpItemKindStruct", { fg = colors.yellow })
hi("CmpItemKindEvent", { fg = colors.orange })
hi("CmpItemKindEnum", { fg = colors.yellow })
hi("CmpItemKindUnit", { fg = colors.purple })
hi("CmpItemKindModule", { fg = colors.yellow })
hi("CmpItemKindProperty", { fg = colors.blue })
hi("CmpItemKindField", { fg = colors.blue })
hi("CmpItemKindTypeParameter", { fg = colors.yellow })
hi("CmpItemKindEnumMember", { fg = colors.purple })
hi("CmpItemKindOperator", { fg = colors.fg1 })
hi("CmpItemKindSnippet", { fg = colors.aqua })
hi("CmpItemKindText", { fg = colors.fg1 })
hi("CmpItemKindFile", { fg = colors.blue })
hi("CmpItemKindFolder", { fg = colors.blue })
hi("CmpItemKindColor", { fg = colors.orange })

hi("CmpItemMenu", { fg = colors.gray, italic = use_italics })

hi("TelescopeBorder", { fg = colors.bg4, bg = colors.bg0_h })
hi("TelescopeNormal", { fg = colors.fg1, bg = colors.bg0_h })
hi("TelescopePromptNormal", { fg = colors.fg1, bg = colors.bg2 })
hi("TelescopePromptBorder", { fg = colors.bg4, bg = colors.bg2 })
hi("TelescopePromptTitle", { fg = colors.green, bg = colors.bg2, bold = true })
hi("TelescopePromptPrefix", { fg = colors.yellow, bg = colors.bg2, bold = true })
hi("TelescopeResultsTitle", { fg = colors.fg2, bg = colors.bg0_h, bold = true })
hi("TelescopePreviewTitle", { fg = colors.aqua, bg = colors.bg0_h, bold = true })

hi("TelescopeSelection", { fg = colors.fg0, bg = colors.bg2, bold = true })
hi("TelescopeSelectionCaret", { fg = colors.yellow, bg = colors.bg2, bold = true })

hi("TelescopeMatching", { fg = colors.yellow, bold = true })

hi("TelescopeResultsNormal", { fg = colors.fg1, bg = colors.bg0_h })
hi("TelescopeResultsComment", { fg = colors.gray, italic = use_italics })
hi("TelescopeResultsSpecialComment", { fg = colors.gray, italic = use_italics, bold = true })
hi("TelescopeResultsDiffAdd", { fg = colors.green })
hi("TelescopeResultsDiffChange", { fg = colors.aqua })
hi("TelescopeResultsDiffDelete", { fg = colors.red })

hi("TelescopeMultiSelection", { fg = colors.orange, bold = true })
hi("TelescopeMultiIcon", { fg = colors.yellow })

-- ============================================================================
-- NvimTree / Neo-tree
-- ============================================================================
hi("NvimTreeNormal", { fg = colors.fg1, bg = colors.bg0_h })
hi("NvimTreeNormalNC", { fg = colors.fg1, bg = colors.bg0_h })
hi("NvimTreeRootFolder", { fg = colors.yellow, bold = true })
hi("NvimTreeFolderName", { fg = colors.blue })
hi("NvimTreeFolderIcon", { fg = colors.blue })
hi("NvimTreeEmptyFolderName", { fg = colors.gray })
hi("NvimTreeOpenedFolderName", { fg = colors.green, bold = true })
hi("NvimTreeSymlink", { fg = colors.aqua, italic = use_italics })
hi("NvimTreeExecFile", { fg = colors.green, bold = true })
hi("NvimTreeSpecialFile", { fg = colors.orange, bold = true })
hi("NvimTreeImageFile", { fg = colors.purple })

hi("NvimTreeGitDirty", { fg = colors.yellow })
hi("NvimTreeGitStaged", { fg = colors.green })
hi("NvimTreeGitMerge", { fg = colors.purple })
hi("NvimTreeGitRenamed", { fg = colors.orange })
hi("NvimTreeGitNew", { fg = colors.green })
hi("NvimTreeGitDeleted", { fg = colors.red })

hi("NvimTreeIndentMarker", { fg = colors.bg4 })
hi("NvimTreeWinSeparator", { fg = colors.bg3 })

hi("NeoTreeNormal", { fg = colors.fg1, bg = colors.bg0_h })
hi("NeoTreeNormalNC", { fg = colors.fg1, bg = colors.bg0_h })
hi("NeoTreeDirectoryName", { fg = colors.blue })
hi("NeoTreeDirectoryIcon", { fg = colors.blue })
hi("NeoTreeFileName", { fg = colors.fg1 })
hi("NeoTreeFileIcon", { fg = colors.fg2 })
hi("NeoTreeRootName", { fg = colors.yellow, bold = true })
hi("NeoTreeGitAdded", { fg = colors.green })
hi("NeoTreeGitConflict", { fg = colors.red, bold = true })
hi("NeoTreeGitDeleted", { fg = colors.red })
hi("NeoTreeGitIgnored", { fg = colors.gray, italic = use_italics })
hi("NeoTreeGitModified", { fg = colors.yellow })
hi("NeoTreeGitUntracked", { fg = colors.orange })
hi("NeoTreeIndentMarker", { fg = colors.bg4 })

hi("BufferLineFill", { bg = colors.bg0_h })
hi("BufferLineBackground", { fg = colors.gray, bg = colors.bg1 })
hi("BufferLineBuffer", { fg = colors.gray, bg = colors.bg1 })
hi("BufferLineBufferSelected", { fg = colors.fg1, bg = colors.bg0, bold = true })
hi("BufferLineBufferVisible", { fg = colors.fg2, bg = colors.bg2 })
hi("BufferLineTab", { fg = colors.gray, bg = colors.bg1 })
hi("BufferLineTabSelected", { fg = colors.fg1, bg = colors.bg0, bold = true })
hi("BufferLineSeparator", { fg = colors.bg0_h, bg = colors.bg1 })
hi("BufferLineSeparatorSelected", { fg = colors.bg0_h, bg = colors.bg0 })
hi("BufferLineSeparatorVisible", { fg = colors.bg0_h, bg = colors.bg2 })
hi("BufferLineModified", { fg = colors.yellow, bg = colors.bg1 })
hi("BufferLineModifiedSelected", { fg = colors.yellow, bg = colors.bg0, bold = true })
hi("BufferLineModifiedVisible", { fg = colors.yellow, bg = colors.bg2 })

hi("IndentBlanklineChar", { fg = colors.bg2 })
hi("IndentBlanklineContextChar", { fg = colors.gray })
hi("IndentBlanklineContextStart", { sp = colors.gray, underline = true })
hi("IndentBlanklineSpaceChar", { fg = colors.bg2 })

hi("NotifyERRORBorder", { fg = colors.red, bg = colors.bg0_h })
hi("NotifyWARNBorder", { fg = colors.yellow, bg = colors.bg0_h })
hi("NotifyINFOBorder", { fg = colors.blue, bg = colors.bg0_h })
hi("NotifyDEBUGBorder", { fg = colors.gray, bg = colors.bg0_h })
hi("NotifyTRACEBorder", { fg = colors.purple, bg = colors.bg0_h })
hi("NotifyERRORIcon", { fg = colors.red })
hi("NotifyWARNIcon", { fg = colors.yellow })
hi("NotifyINFOIcon", { fg = colors.blue })
hi("NotifyDEBUGIcon", { fg = colors.gray })
hi("NotifyTRACEIcon", { fg = colors.purple })
hi("NotifyERRORTitle", { fg = colors.red, bold = true })
hi("NotifyWARNTitle", { fg = colors.yellow, bold = true })
hi("NotifyINFOTitle", { fg = colors.blue, bold = true })
hi("NotifyDEBUGTitle", { fg = colors.gray, bold = true })
hi("NotifyTRACETitle", { fg = colors.purple, bold = true })

-- Python
hi("pythonBuiltin", { fg = colors.orange })
hi("pythonDecorator", { fg = colors.aqua })
hi("pythonException", { fg = colors.red })

-- JavaScript/TypeScript
hi("jsFunction", { fg = colors.red })
hi("jsArrowFunction", { fg = colors.aqua })
hi("jsThis", { fg = colors.purple, italic = use_italics })
hi("tsxTag", { fg = colors.red })
hi("tsxTagName", { fg = colors.red })
hi("tsxAttrib", { fg = colors.aqua })

-- Rust
hi("rustModPath", { fg = colors.yellow })
hi("rustMacro", { fg = colors.aqua })
hi("rustLifetime", { fg = colors.orange, italic = use_italics })
hi("rustAttribute", { fg = colors.gray })

-- Go
hi("goPackage", { fg = colors.red })
hi("goImport", { fg = colors.red })
hi("goBuiltins", { fg = colors.orange })

-- C/C++
hi("cInclude", { fg = colors.aqua })
hi("cppSTLnamespace", { fg = colors.yellow })

-- Lua
hi("luaFunc", { fg = colors.green })
hi("luaTable", { fg = colors.yellow })

-- HTML/CSS
hi("htmlTag", { fg = colors.red })
hi("htmlTagName", { fg = colors.red })
hi("htmlArg", { fg = colors.aqua })
hi("cssClassName", { fg = colors.green })
hi("cssProp", { fg = colors.fg2 })
hi("cssColor", { fg = colors.purple })

-- Markdown
hi("markdownH1", { fg = colors.green, bold = true })
hi("markdownH2", { fg = colors.green, bold = true })
hi("markdownH3", { fg = colors.yellow, bold = true })
hi("markdownH4", { fg = colors.yellow, bold = true })
hi("markdownCode", { fg = colors.aqua })
hi("markdownCodeBlock", { fg = colors.aqua })
hi("markdownUrl", { fg = colors.blue, underline = true })
hi("markdownLinkText", { fg = colors.purple })

-- Bash
hi("shDerefVar", { fg = colors.fg2 })
hi("shQuote", { fg = colors.green })

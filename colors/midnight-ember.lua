vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "midnight-ember"

local use_italics = true
local ok, config = pcall(require, "ember.config")
if ok and config.config and config.config.ui then
  use_italics = config.config.ui.italics ~= false
end

local colors = {
  bg         = "#222831",
  bg_dark    = "#1B262C",
  bg_darker  = "#313131",
  bg_light   = "#393E46",
  bg_medium  = "#414141",

  fg         = "#c1c1c1",
  fg_soft    = "#d2bf98",
  fg_bright  = "#d3c3a3",

  amber_bright = "#e9bd47",
  amber_medium = "#ECB365",
  amber_deep   = "#efaf56",

  gold       = "#e5b732",
  red_error  = "#ff9a91",
  red_keyword = "#ff9773",
  red_operator = "#ff95ac",
  blue_type  = "#9db9da",
  green_success = "#88c4a8",
  comment    = "#b8b8b8",
  comment_dim = "#bfbfbf",

  selection  = "#362222",
  border     = "#393E46",
  visual     = "#30475E",
  cursor_line = "#313131",
  line_nr    = "#b8b8b8",
  match_paren = "#e9bd47",
  search     = "#efaf56",

  none       = "NONE",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("NormalFloat", { fg = colors.fg, bg = colors.bg_dark })
hi("NormalNC", { fg = colors.fg, bg = colors.bg })

hi("Comment", { fg = colors.comment, italic = use_italics })
hi("ColorColumn", { bg = colors.bg_darker })

hi("Cursor", { fg = colors.bg, bg = colors.fg })
hi("CursorLine", { bg = colors.cursor_line })
hi("CursorLineNr", { fg = colors.amber_bright, bg = colors.cursor_line, bold = true })
hi("CursorColumn", { bg = colors.cursor_line })

hi("LineNr", { fg = colors.line_nr })
hi("SignColumn", { fg = colors.line_nr })
hi("FoldColumn", { fg = colors.comment })
hi("Folded", { fg = colors.comment, bg = colors.bg_darker, italic = use_italics })

hi("MatchParen", { fg = colors.match_paren, bold = true })

hi("Visual", { bg = colors.visual })
hi("VisualNOS", { bg = colors.visual })

hi("Search", { fg = colors.bg, bg = colors.search })
hi("IncSearch", { fg = colors.bg, bg = colors.amber_bright, bold = true })
hi("Substitute", { fg = colors.bg, bg = colors.amber_bright })

hi("Pmenu", { fg = colors.fg, bg = colors.bg_light })
hi("PmenuSel", { fg = colors.bg, bg = colors.amber_medium, bold = true })
hi("PmenuSbar", { bg = colors.bg_medium })
hi("PmenuThumb", { bg = colors.comment })

hi("StatusLine", { fg = colors.fg, bg = colors.bg_light })
hi("StatusLineNC", { fg = colors.comment, bg = colors.bg_medium })

hi("TabLine", { fg = colors.comment, bg = colors.bg_medium })
hi("TabLineFill", { bg = colors.bg_medium })
hi("TabLineSel", { fg = colors.fg, bg = colors.bg_light, bold = true })

hi("VertSplit", { fg = colors.border })
hi("WinSeparator", { fg = colors.border })

hi("WildMenu", { fg = colors.bg, bg = colors.amber_medium, bold = true })

hi("Directory", { fg = colors.blue_type })
hi("Title", { fg = colors.amber_bright, bold = true })

hi("ErrorMsg", { fg = colors.red_error, bold = true })
hi("WarningMsg", { fg = colors.amber_bright, bold = true })
hi("ModeMsg", { fg = colors.fg_soft })
hi("MoreMsg", { fg = colors.green_success })
hi("Question", { fg = colors.green_success })

hi("SpecialKey", { fg = colors.comment })
hi("NonText", { fg = colors.comment_dim })
hi("Whitespace", { fg = colors.comment_dim })
hi("EndOfBuffer", { fg = colors.bg })

hi("Conceal", { fg = colors.comment })

hi("FloatBorder", { fg = colors.border, bg = colors.bg_dark })
hi("FloatTitle", { fg = colors.amber_bright, bg = colors.bg_dark, bold = true })

hi("QuickFixLine", { bg = colors.cursor_line })
hi("qfLineNr", { fg = colors.amber_medium })
hi("qfFileName", { fg = colors.blue_type })

hi("Constant", { fg = colors.amber_medium })
hi("String", { fg = colors.amber_bright })
hi("Character", { fg = colors.amber_bright })
hi("Number", { fg = colors.amber_deep })
hi("Float", { fg = colors.amber_deep })
hi("Boolean", { fg = colors.amber_deep })

hi("Identifier", { fg = colors.fg_soft })
hi("Function", { fg = colors.amber_deep })

hi("Statement", { fg = colors.red_keyword })
hi("Conditional", { fg = colors.red_keyword })
hi("Repeat", { fg = colors.red_keyword })
hi("Label", { fg = colors.red_keyword })
hi("Operator", { fg = colors.red_operator })
hi("Keyword", { fg = colors.red_keyword })
hi("Exception", { fg = colors.red_keyword })

hi("PreProc", { fg = colors.red_operator })
hi("Include", { fg = colors.red_operator })
hi("Define", { fg = colors.red_operator })
hi("Macro", { fg = colors.red_operator })
hi("PreCondit", { fg = colors.red_operator })

hi("Type", { fg = colors.blue_type })
hi("StorageClass", { fg = colors.blue_type })
hi("Structure", { fg = colors.blue_type })
hi("Typedef", { fg = colors.blue_type })

hi("Special", { fg = colors.red_operator })
hi("SpecialChar", { fg = colors.red_operator })
hi("Tag", { fg = colors.red_keyword })
hi("Delimiter", { fg = colors.fg })
hi("SpecialComment", { fg = colors.comment, italic = use_italics, bold = true })
hi("Debug", { fg = colors.red_error })

hi("Underlined", { fg = colors.blue_type, underline = true })
hi("Ignore", { fg = colors.comment_dim })
hi("Error", { fg = colors.red_error, bold = true })
hi("Todo", { fg = colors.amber_bright, bold = true, italic = use_italics })

hi("DiffAdd", { fg = colors.green_success, bg = colors.bg_darker })
hi("DiffChange", { fg = colors.amber_deep, bg = colors.bg_darker })
hi("DiffDelete", { fg = colors.red_error, bg = colors.bg_darker })
hi("DiffText", { fg = colors.amber_bright, bg = colors.bg_medium, bold = true })

hi("diffAdded", { fg = colors.green_success })
hi("diffChanged", { fg = colors.amber_deep })
hi("diffRemoved", { fg = colors.red_error })
hi("diffFile", { fg = colors.blue_type, bold = true })
hi("diffLine", { fg = colors.comment })
hi("diffIndexLine", { fg = colors.comment })

hi("DiagnosticError", { fg = colors.red_error })
hi("DiagnosticWarn", { fg = colors.amber_bright })
hi("DiagnosticInfo", { fg = colors.amber_medium })
hi("DiagnosticHint", { fg = colors.green_success })
hi("DiagnosticOk", { fg = colors.green_success })

hi("DiagnosticUnderlineError", { sp = colors.red_error, underline = true })
hi("DiagnosticUnderlineWarn", { sp = colors.amber_bright, underline = true })
hi("DiagnosticUnderlineInfo", { sp = colors.amber_medium, underline = true })
hi("DiagnosticUnderlineHint", { sp = colors.green_success, underline = true })
hi("DiagnosticUnderlineOk", { sp = colors.green_success, underline = true })

hi("DiagnosticVirtualTextError", { fg = colors.red_error, italic = use_italics })
hi("DiagnosticVirtualTextWarn", { fg = colors.amber_bright, italic = use_italics })
hi("DiagnosticVirtualTextInfo", { fg = colors.amber_medium, italic = use_italics })
hi("DiagnosticVirtualTextHint", { fg = colors.green_success, italic = use_italics })

hi("DiagnosticSignError", { fg = colors.red_error })
hi("DiagnosticSignWarn", { fg = colors.amber_bright })
hi("DiagnosticSignInfo", { fg = colors.amber_medium })
hi("DiagnosticSignHint", { fg = colors.green_success })

hi("DiagnosticFloatingError", { fg = colors.red_error, bg = colors.bg_dark })
hi("DiagnosticFloatingWarn", { fg = colors.amber_bright, bg = colors.bg_dark })
hi("DiagnosticFloatingInfo", { fg = colors.amber_medium, bg = colors.bg_dark })
hi("DiagnosticFloatingHint", { fg = colors.green_success, bg = colors.bg_dark })

hi("LspReferenceText", { bg = colors.bg_light })
hi("LspReferenceRead", { bg = colors.bg_light })
hi("LspReferenceWrite", { bg = colors.bg_light })

hi("LspSignatureActiveParameter", { fg = colors.amber_bright, bold = true })
hi("LspCodeLens", { fg = colors.comment, italic = use_italics })
hi("LspCodeLensSeparator", { fg = colors.comment_dim })

hi("@variable", { link = "Identifier" })
hi("@variable.builtin", { link = "Constant" })
hi("@variable.parameter", { link = "Identifier" })
hi("@variable.member", { link = "Identifier" })

hi("@constant", { link = "Constant" })
hi("@constant.builtin", { link = "Constant" })
hi("@constant.macro", { link = "Macro" })

hi("@module", { fg = colors.blue_type })
hi("@module.builtin", { fg = colors.green_success })
hi("@label", { link = "Label" })

hi("@string", { link = "String" })
hi("@string.documentation", { fg = colors.amber_medium, italic = use_italics })
hi("@string.escape", { fg = colors.amber_medium })
hi("@string.regexp", { fg = colors.amber_deep })
hi("@string.special", { fg = colors.amber_medium })

hi("@character", { link = "Character" })
hi("@character.special", { fg = colors.amber_medium })

hi("@number", { link = "Number" })
hi("@number.float", { link = "Float" })
hi("@boolean", { link = "Boolean" })

hi("@function", { link = "Function" })
hi("@function.builtin", { link = "Function" })
hi("@function.call", { fg = colors.amber_deep })
hi("@function.macro", { link = "Macro" })
hi("@function.method", { link = "Function" })
hi("@function.method.call", { fg = colors.amber_deep })

hi("@constructor", { fg = colors.blue_type })

hi("@keyword", { link = "Keyword" })
hi("@keyword.coroutine", { fg = colors.red_keyword })
hi("@keyword.function", { link = "Keyword" })
hi("@keyword.operator", { fg = colors.red_operator })
hi("@keyword.import", { link = "Include" })
hi("@keyword.repeat", { link = "Repeat" })
hi("@keyword.return", { link = "Keyword" })
hi("@keyword.conditional", { link = "Conditional" })
hi("@keyword.exception", { link = "Exception" })
hi("@keyword.directive", { link = "PreProc" })
hi("@keyword.type", { link = "Type" })

hi("@operator", { link = "Operator" })

hi("@punctuation.delimiter", { link = "Delimiter" })
hi("@punctuation.bracket", { link = "Delimiter" })
hi("@punctuation.special", { fg = colors.red_operator })

hi("@comment", { link = "Comment" })
hi("@comment.documentation", { fg = colors.comment, italic = use_italics, bold = true })
hi("@comment.error", { link = "DiagnosticError" })
hi("@comment.warning", { link = "DiagnosticWarn" })
hi("@comment.todo", { link = "Todo" })
hi("@comment.note", { link = "SpecialComment" })

hi("@markup.strong", { fg = colors.fg, bold = true })
hi("@markup.italic", { fg = colors.fg, italic = use_italics })
hi("@markup.strikethrough", { fg = colors.comment, strikethrough = true })
hi("@markup.underline", { fg = colors.fg, underline = true })
hi("@markup.heading", { fg = colors.amber_bright, bold = true })
hi("@markup.quote", { fg = colors.comment, italic = use_italics })
hi("@markup.math", { fg = colors.amber_medium })
hi("@markup.link", { fg = colors.blue_type, underline = true })
hi("@markup.link.label", { fg = colors.amber_deep })
hi("@markup.link.url", { fg = colors.blue_type, underline = true })
hi("@markup.raw", { fg = colors.green_success })
hi("@markup.list", { fg = colors.red_operator })
hi("@markup.list.checked", { fg = colors.green_success })
hi("@markup.list.unchecked", { fg = colors.comment })

hi("@tag", { link = "Tag" })
hi("@tag.attribute", { fg = colors.amber_deep })
hi("@tag.delimiter", { link = "Delimiter" })

hi("@type", { link = "Type" })
hi("@type.builtin", { link = "Type" })
hi("@type.definition", { fg = colors.blue_type })
hi("@type.qualifier", { fg = colors.red_keyword })

hi("@attribute", { fg = colors.amber_deep })
hi("@property", { fg = colors.fg_soft })

hi("@diff.plus", { link = "DiffAdd" })
hi("@diff.minus", { link = "DiffDelete" })
hi("@diff.delta", { link = "DiffChange" })

hi("GitSignsAdd", { fg = colors.green_success })
hi("GitSignsChange", { fg = colors.amber_bright })
hi("GitSignsDelete", { fg = colors.red_error })
hi("GitSignsCurrentLineBlame", { fg = colors.comment, italic = use_italics })

hi("CmpItemAbbr", { fg = colors.fg })
hi("CmpItemAbbrDeprecated", { fg = colors.comment, strikethrough = true })
hi("CmpItemAbbrMatch", { fg = colors.amber_bright, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = colors.amber_deep, bold = true })

hi("CmpItemKindDefault", { fg = colors.fg_soft })
hi("CmpItemKindKeyword", { fg = colors.red_keyword })
hi("CmpItemKindVariable", { fg = colors.fg_soft })
hi("CmpItemKindConstant", { fg = colors.amber_medium })
hi("CmpItemKindReference", { fg = colors.fg_soft })
hi("CmpItemKindValue", { fg = colors.amber_medium })
hi("CmpItemKindFunction", { fg = colors.amber_deep })
hi("CmpItemKindMethod", { fg = colors.amber_deep })
hi("CmpItemKindConstructor", { fg = colors.blue_type })
hi("CmpItemKindClass", { fg = colors.blue_type })
hi("CmpItemKindInterface", { fg = colors.blue_type })
hi("CmpItemKindStruct", { fg = colors.blue_type })
hi("CmpItemKindEvent", { fg = colors.red_operator })
hi("CmpItemKindEnum", { fg = colors.blue_type })
hi("CmpItemKindUnit", { fg = colors.amber_medium })
hi("CmpItemKindModule", { fg = colors.blue_type })
hi("CmpItemKindProperty", { fg = colors.fg_soft })
hi("CmpItemKindField", { fg = colors.fg_soft })
hi("CmpItemKindTypeParameter", { fg = colors.blue_type })
hi("CmpItemKindEnumMember", { fg = colors.amber_medium })
hi("CmpItemKindOperator", { fg = colors.red_operator })
hi("CmpItemKindSnippet", { fg = colors.green_success })
hi("CmpItemKindText", { fg = colors.fg })
hi("CmpItemKindFile", { fg = colors.blue_type })
hi("CmpItemKindFolder", { fg = colors.blue_type })
hi("CmpItemKindColor", { fg = colors.amber_medium })

hi("CmpItemMenu", { fg = colors.comment, italic = use_italics })

hi("TelescopeBorder", { fg = colors.border, bg = colors.bg_dark })
hi("TelescopeNormal", { fg = colors.fg, bg = colors.bg_dark })
hi("TelescopePromptNormal", { fg = colors.fg, bg = colors.bg_light })
hi("TelescopePromptBorder", { fg = colors.border, bg = colors.bg_light })
hi("TelescopePromptTitle", { fg = colors.amber_bright, bg = colors.bg_light, bold = true })
hi("TelescopePromptPrefix", { fg = colors.amber_bright, bg = colors.bg_light, bold = true })
hi("TelescopeResultsTitle", { fg = colors.fg_soft, bg = colors.bg_dark, bold = true })
hi("TelescopePreviewTitle", { fg = colors.green_success, bg = colors.bg_dark, bold = true })

hi("TelescopeSelection", { fg = colors.fg_bright, bg = colors.cursor_line, bold = true })
hi("TelescopeSelectionCaret", { fg = colors.amber_bright, bg = colors.cursor_line, bold = true })

hi("TelescopeMatching", { fg = colors.amber_bright, bold = true })

hi("TelescopeResultsNormal", { fg = colors.fg, bg = colors.bg_dark })
hi("TelescopeResultsComment", { fg = colors.comment, italic = use_italics })
hi("TelescopeResultsSpecialComment", { fg = colors.comment, italic = use_italics, bold = true })
hi("TelescopeResultsDiffAdd", { fg = colors.green_success })
hi("TelescopeResultsDiffChange", { fg = colors.amber_deep })
hi("TelescopeResultsDiffDelete", { fg = colors.red_error })

hi("TelescopeMultiSelection", { fg = colors.amber_medium, bold = true })
hi("TelescopeMultiIcon", { fg = colors.amber_bright })

hi("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_dark })
hi("NvimTreeNormalNC", { fg = colors.fg, bg = colors.bg_dark })
hi("NvimTreeRootFolder", { fg = colors.amber_bright, bold = true })
hi("NvimTreeFolderName", { fg = colors.blue_type })
hi("NvimTreeFolderIcon", { fg = colors.blue_type })
hi("NvimTreeEmptyFolderName", { fg = colors.comment })
hi("NvimTreeOpenedFolderName", { fg = colors.amber_deep, bold = true })
hi("NvimTreeSymlink", { fg = colors.blue_type, italic = use_italics })
hi("NvimTreeExecFile", { fg = colors.green_success, bold = true })
hi("NvimTreeSpecialFile", { fg = colors.amber_bright, bold = true })
hi("NvimTreeImageFile", { fg = colors.red_operator })

hi("NvimTreeGitDirty", { fg = colors.amber_bright })
hi("NvimTreeGitStaged", { fg = colors.green_success })
hi("NvimTreeGitMerge", { fg = colors.red_operator })
hi("NvimTreeGitRenamed", { fg = colors.amber_deep })
hi("NvimTreeGitNew", { fg = colors.green_success })
hi("NvimTreeGitDeleted", { fg = colors.red_error })

hi("NvimTreeIndentMarker", { fg = colors.comment_dim })
hi("NvimTreeWinSeparator", { fg = colors.border })

hi("NeoTreeNormal", { fg = colors.fg, bg = colors.bg_dark })
hi("NeoTreeNormalNC", { fg = colors.fg, bg = colors.bg_dark })
hi("NeoTreeDirectoryName", { fg = colors.blue_type })
hi("NeoTreeDirectoryIcon", { fg = colors.blue_type })
hi("NeoTreeFileName", { fg = colors.fg })
hi("NeoTreeFileIcon", { fg = colors.fg_soft })
hi("NeoTreeRootName", { fg = colors.amber_bright, bold = true })
hi("NeoTreeGitAdded", { fg = colors.green_success })
hi("NeoTreeGitConflict", { fg = colors.red_error, bold = true })
hi("NeoTreeGitDeleted", { fg = colors.red_error })
hi("NeoTreeGitIgnored", { fg = colors.comment, italic = use_italics })
hi("NeoTreeGitModified", { fg = colors.amber_bright })
hi("NeoTreeGitUntracked", { fg = colors.amber_deep })
hi("NeoTreeIndentMarker", { fg = colors.comment_dim })

hi("BufferLineFill", { bg = colors.bg_darker })
hi("BufferLineBackground", { fg = colors.comment, bg = colors.bg_medium })
hi("BufferLineBuffer", { fg = colors.comment, bg = colors.bg_medium })
hi("BufferLineBufferSelected", { fg = colors.fg, bg = colors.bg, bold = true })
hi("BufferLineBufferVisible", { fg = colors.fg_soft, bg = colors.bg_light })
hi("BufferLineTab", { fg = colors.comment, bg = colors.bg_medium })
hi("BufferLineTabSelected", { fg = colors.fg, bg = colors.bg, bold = true })
hi("BufferLineSeparator", { fg = colors.bg_darker, bg = colors.bg_medium })
hi("BufferLineSeparatorSelected", { fg = colors.bg_darker, bg = colors.bg })
hi("BufferLineSeparatorVisible", { fg = colors.bg_darker, bg = colors.bg_light })
hi("BufferLineModified", { fg = colors.amber_bright, bg = colors.bg_medium })
hi("BufferLineModifiedSelected", { fg = colors.amber_bright, bg = colors.bg, bold = true })
hi("BufferLineModifiedVisible", { fg = colors.amber_bright, bg = colors.bg_light })

hi("IndentBlanklineChar", { fg = colors.bg_light })
hi("IndentBlanklineContextChar", { fg = colors.comment })
hi("IndentBlanklineContextStart", { sp = colors.comment, underline = true })
hi("IndentBlanklineSpaceChar", { fg = colors.bg_light })

hi("NotifyERRORBorder", { fg = colors.red_error, bg = colors.bg_dark })
hi("NotifyWARNBorder", { fg = colors.amber_bright, bg = colors.bg_dark })
hi("NotifyINFOBorder", { fg = colors.amber_medium, bg = colors.bg_dark })
hi("NotifyDEBUGBorder", { fg = colors.comment, bg = colors.bg_dark })
hi("NotifyTRACEBorder", { fg = colors.blue_type, bg = colors.bg_dark })
hi("NotifyERRORIcon", { fg = colors.red_error })
hi("NotifyWARNIcon", { fg = colors.amber_bright })
hi("NotifyINFOIcon", { fg = colors.amber_medium })
hi("NotifyDEBUGIcon", { fg = colors.comment })
hi("NotifyTRACEIcon", { fg = colors.blue_type })
hi("NotifyERRORTitle", { fg = colors.red_error, bold = true })
hi("NotifyWARNTitle", { fg = colors.amber_bright, bold = true })
hi("NotifyINFOTitle", { fg = colors.amber_medium, bold = true })
hi("NotifyDEBUGTitle", { fg = colors.comment, bold = true })
hi("NotifyTRACETitle", { fg = colors.blue_type, bold = true })

hi("pythonBuiltin", { fg = colors.green_success })
hi("pythonDecorator", { fg = colors.amber_deep })
hi("pythonException", { fg = colors.red_keyword })

hi("jsFunction", { fg = colors.red_keyword })
hi("jsArrowFunction", { fg = colors.red_operator })
hi("jsThis", { fg = colors.red_keyword, italic = use_italics })
hi("tsxTag", { fg = colors.red_keyword })
hi("tsxTagName", { fg = colors.red_keyword })
hi("tsxAttrib", { fg = colors.amber_deep })

hi("rustModPath", { fg = colors.blue_type })
hi("rustMacro", { fg = colors.amber_deep })
hi("rustLifetime", { fg = colors.red_operator, italic = use_italics })
hi("rustAttribute", { fg = colors.comment })

hi("goPackage", { fg = colors.red_keyword })
hi("goImport", { fg = colors.red_keyword })
hi("goBuiltins", { fg = colors.green_success })

hi("cInclude", { fg = colors.red_operator })
hi("cppSTLnamespace", { fg = colors.blue_type })

hi("luaFunc", { fg = colors.amber_deep })
hi("luaTable", { fg = colors.blue_type })

hi("htmlTag", { fg = colors.red_keyword })
hi("htmlTagName", { fg = colors.red_keyword })
hi("htmlArg", { fg = colors.amber_deep })
hi("cssClassName", { fg = colors.amber_deep })
hi("cssProp", { fg = colors.fg_soft })
hi("cssColor", { fg = colors.amber_medium })

hi("markdownH1", { fg = colors.amber_bright, bold = true })
hi("markdownH2", { fg = colors.amber_bright, bold = true })
hi("markdownH3", { fg = colors.amber_deep, bold = true })
hi("markdownH4", { fg = colors.amber_deep, bold = true })
hi("markdownCode", { fg = colors.green_success })
hi("markdownCodeBlock", { fg = colors.green_success })
hi("markdownUrl", { fg = colors.blue_type, underline = true })
hi("markdownLinkText", { fg = colors.amber_deep })

hi("shDerefVar", { fg = colors.fg_soft })
hi("shQuote", { fg = colors.amber_bright })

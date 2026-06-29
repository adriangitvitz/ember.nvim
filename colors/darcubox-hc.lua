vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "darcubox-hc"

-- stylua: ignore
local p = {
  -- UI / structural (kept from darcubox)
  contrast   = "#0A0D0F",
  bg         = "#0E1214",
  surface1   = "#25262C",
  surface2   = "#404146",
  black      = "#16181C",

  fg         = "#D0C6A5", -- kept (11.0:1)
  sunshine   = "#FFD072", -- kept (13.0:1)
  gold       = "#FB982E", -- kept (8.6:1)
  ember      = "#FF773D", -- raised from #DD4E21
  sand       = "#E6A96B", -- kept (9.2:1)
  meadow     = "#4DB262", -- raised from #52A260
  lime       = "#9CD750", -- kept (11.0:1)
  sapphire   = "#64A7BE", -- raised from #0F829D
  crimson    = "#FF7365", -- raised from #D01C26
  lilac      = "#D690C4", -- raised from #CD80B9
  silver     = "#A9A09C", -- raised from #8F8682
  alabaster  = "#EFEAD9", -- kept (15.6:1)

  -- diff, git and diagnostic colors
  error      = "#FF7480", -- raised from #EB5F6A
  warning    = "#FF9B0A", -- kept (8.9:1)
  plus       = "#67AC8E", -- raised from #5A9F81
  info       = "#AEA7A7", -- raised from #878080
  hint       = "#3EA2FF", -- raised from #287BDE
  error_bg   = "#9E2927",
  warning_bg = "#42321B",
  plus_bg    = "#32593D",
  info_bg    = "#484040",
  hint_bg    = "#263C50",
}

local bg = p.bg
local contrastbg = p.contrast

-- stylua: ignore
local groups = {
  -- Editor
  ColorColumn                          = { bg = bg },
  Conceal                              = { fg = p.fg },
  Cursor                               = { fg = p.gold, reverse = true },
  lCursor                              = { fg = p.gold, reverse = true },
  CursorIM                             = { fg = p.gold, reverse = true },
  CursorColumn                         = { link = "CursorLine" },
  CursorLine                           = { bg = p.surface1 },
  Directory                            = { fg = p.silver },
  EndOfBuffer                          = { fg = p.surface2 },
  TermCursor                           = { fg = p.gold, reverse = true },
  TermCursorNC                         = { fg = p.gold, reverse = true },
  VertSplit                            = { fg = p.surface2 },
  WinSeparator                         = { link = "VertSplit" },
  Folded                               = { fg = p.surface2, italic = true },
  FoldColumn                           = { fg = p.surface2 },
  SignColumn                           = { fg = p.fg },
  SignColumnSB                         = { link = "ColorColumn" },
  Substitute                           = { fg = p.black, bg = p.sunshine },
  LineNr                               = { fg = p.surface2 },
  CursorLineNr                         = { fg = p.alabaster },
  MatchParen                           = { special = p.gold, undercurl = true },
  MsgArea                              = { link = "Normal" },
  MsgSeparator                         = { fg = p.fg, bg = bg },
  NonText                              = { fg = p.surface2 },
  Normal                               = { fg = p.fg, bg = bg },
  NormalSB                             = { fg = p.surface2, bg = contrastbg },
  NormalNC                             = { fg = p.surface1, bg = contrastbg },
  NormalFloat                          = { link = "Normal" },
  FloatBorder                          = { fg = p.sand, bg = contrastbg },
  FloatTitle                           = { fg = p.alabaster, bg = contrastbg },
  Pmenu                                = { fg = p.fg, bg = p.surface1 },
  PmenuSel                             = { fg = p.sunshine, bg = p.surface2 },
  PmenuSbar                            = { fg = p.silver, bg = p.surface2 },
  PmenuThumb                           = { fg = p.alabaster, bg = p.silver },
  Question                             = { fg = p.meadow },
  QuickFixLine                         = { fg = p.ember, bg = p.silver, reverse = true },
  Search                               = { fg = p.sunshine, reverse = true },
  IncSearch                            = { fg = p.black, bg = p.gold },
  CurSearch                            = { link = "IncSearch" },
  SpecialKey                           = { fg = p.sunshine },
  SpellBad                             = { fg = p.crimson, italic = true, undercurl = true },
  SpellCap                             = { fg = p.sand, italic = true, undercurl = true },
  SpellLocal                           = { fg = p.sapphire, italic = true, undercurl = true },
  SpellRare                            = { fg = p.lilac, italic = true, undercurl = true },
  TabLine                              = { link = "StatusLine" },
  TabLineFill                          = { fg = p.fg },
  TabLineSel                           = { fg = p.black, bg = p.fg },
  Title                                = { fg = p.alabaster },
  Visual                               = { bg = p.surface2 },
  VisualNOS                            = { bg = p.sand },
  Whitespace                           = { fg = p.surface2 },
  WildMenu                             = { fg = p.ember, bold = true },
  WinBar                               = { link = "StatusLine" },
  WinBarNC                             = { link = "StatusLineNC" },

  qfLineNr                             = { fg = p.ember, bg = p.silver, reverse = true },
  ToolbarLine                          = { fg = p.fg, bg = p.contrast },
  ToolbarButton                        = { fg = p.fg, bold = true },
  NormalMode                           = { fg = p.sunshine, reverse = true },
  InsertMode                           = { fg = p.lime },
  ReplaceMode                          = { fg = p.crimson },
  VisualMode                           = { fg = p.alabaster },
  CommandMode                          = { fg = p.silver },
  Warnings                             = { fg = p.warning },
  menuSel                              = { bg = p.surface2, fg = p.alabaster },

  healthError                          = { link = "Error" },
  healthSuccess                        = { fg = p.lime },
  healthWarning                        = { fg = p.warning },

  -- Syntax
  Comment                              = { fg = p.silver },
  Constant                             = { fg = p.meadow },
  String                               = { link = "Constant" },
  Character                            = { link = "Constant" },
  Number                               = { fg = p.lime },
  Boolean                              = { link = "Number" },
  Float                                = { link = "Number" },

  Identifier                           = { fg = p.fg },
  Function                             = { fg = p.gold },

  Statement                            = { fg = p.gold },
  Conditional                          = { link = "Keyword" },
  Repeat                               = { link = "Keyword" },
  Label                                = { fg = p.lilac },
  Operator                             = { fg = p.alabaster },
  Keyword                              = { fg = p.ember },
  Exception                            = { fg = p.sapphire },

  PreProc                              = { fg = p.sunshine },
  Include                              = { link = "Keyword" },
  Define                               = { link = "Keyword" },
  Macro                                = { fg = p.sapphire },
  PreCondit                            = { fg = p.sapphire },

  Type                                 = { fg = p.sapphire },
  StorageClass                         = { fg = p.sunshine },
  Structure                            = { fg = p.sand },
  Typedef                              = { fg = p.lilac },

  Special                              = { fg = p.sand },
  SpecialChar                          = { fg = p.lilac },
  Tag                                  = { fg = p.gold },
  Delimiter                            = { link = "Tag" },
  SpecialComment                       = { fg = p.surface2 },
  Debug                                = { fg = p.crimson },
  htmlH1                               = { fg = p.sunshine, bold = true },
  htmlH2                               = { fg = p.sapphire, bold = true },

  Underlined                           = { fg = p.meadow, underline = true },
  Ignore                               = { fg = p.surface1 },
  Error                                = { fg = p.error, bold = true, underline = true },
  Todo                                 = { fg = p.sunshine, bold = true, italic = true },
  Parameter                            = { fg = p.sunshine },
  Field                                = { fg = p.sunshine },
  Namespace                            = { fg = p.sapphire },
  Warn                                 = { fg = p.crimson },

  -- Treesitter
  ["@annotation"]                      = { link = "PreProc" },
  ["@attribute"]                       = { link = "PreProc" },
  ["@boolean"]                         = { link = "Boolean" },
  ["@character"]                       = { link = "Character" },
  ["@character.special"]               = { link = "SpecialChar" },
  ["@comment"]                         = { link = "Comment" },
  ["@conditional"]                     = { link = "Conditional" },
  ["@keyword.conditional"]             = { link = "Conditional" },
  ["@constant"]                        = { link = "Constant" },
  ["@constant.builtin"]                = { link = "Special" },
  ["@constant.macro"]                  = { link = "Define" },
  ["@debug"]                           = { link = "Debug" },
  ["@define"]                          = { link = "Define" },
  ["@exception"]                       = { link = "Exception" },
  ["@field"]                           = { link = "Field" },
  ["@float"]                           = { link = "Float" },
  ["@keyword.debug"]                   = { link = "Debug" },
  ["@keyword.directive.define"]        = { link = "Define" },
  ["@keyword.exception"]               = { link = "Exception" },
  ["@number.float"]                    = { link = "Float" },
  ["@function"]                        = { link = "Function" },
  ["@function.builtin"]                = { link = "Special" },
  ["@function.call"]                   = { link = "@function" },
  ["@function.macro"]                  = { link = "Macro" },
  ["@keyword.import"]                  = { link = "Include" },
  ["@keyword.coroutine"]               = { link = "@keyword" },
  ["@keyword.operator"]                = { link = "@operator" },
  ["@keyword.return"]                  = { link = "@keyword" },
  ["@method"]                          = { link = "Function" },
  ["@method.call"]                     = { link = "@method" },
  ["@function.method"]                 = { link = "Function" },
  ["@function.method.call"]            = { link = "@function.method" },
  ["@namespace.builtin"]               = { link = "@variable.builtin" },
  ["@none"]                            = {},
  ["@number"]                          = { link = "Number" },
  ["@keyword.directive"]               = { link = "PreProc" },
  ["@keyword.repeat"]                  = { link = "Repeat" },
  ["@keyword.storage"]                 = { link = "StorageClass" },
  ["@storageclass"]                    = { link = "StorageClass" },
  ["@string"]                          = { link = "String" },
  ["@markup.link.label"]               = { link = "SpecialChar" },
  ["@markup.link.label.symbol"]        = { link = "Identifier" },
  ["@tag"]                             = { link = "Label" },
  ["@tag.attribute"]                   = { link = "@property" },
  ["@tag.delimiter"]                   = { link = "Delimiter" },
  ["@markup"]                          = { link = "@none" },
  ["@markup.environment"]              = { link = "Macro" },
  ["@markup.environment.name"]         = { link = "Type" },
  ["@markup.raw"]                      = { link = "String" },
  ["@markup.math"]                     = { link = "Special" },
  ["@markup.strong"]                   = { bold = true },
  ["@markup.italic"]                   = { italic = true },
  ["@markup.strikethrough"]            = { strikethrough = true },
  ["@markup.underline"]                = { underline = true },
  ["@markup.heading"]                  = { link = "Title" },
  ["@comment.note"]                    = { fg = p.hint },
  ["@comment.error"]                   = { fg = p.error },
  ["@comment.hint"]                    = { fg = p.hint },
  ["@comment.info"]                    = { fg = p.info },
  ["@comment.warning"]                 = { fg = p.warning },
  ["@comment.todo"]                    = { fg = p.plus },
  ["@markup.link.url"]                 = { link = "Underlined" },
  ["@type"]                            = { link = "Type" },
  ["@type.definition"]                 = { link = "Typedef" },
  ["@type.qualifier"]                  = { link = "@keyword" },

  -- Misc
  ["@comment.documentation"]           = { link = "Comment" },
  ["@operator"]                        = { link = "Operator" },
  ["@parameter"]                       = { link = "Parameter" },
  ["@error"]                           = { link = "Error" },
  ["@preproc"]                         = { link = "PreProc" },
  ["@conditional.ternary"]             = { link = "Conditional" },
  ["@repeat"]                          = { link = "Repeat" },
  ["@include"]                         = { link = "Include" },
  ["@namespace"]                       = { link = "Namespace" },
  ["@symbol"]                          = { link = "Namespace" },

  -- Punctuation
  ["@punctuation.delimiter"]           = { fg = p.alabaster },
  ["@punctuation.bracket"]             = { fg = p.alabaster },
  ["@punctuation.special"]             = { fg = p.ember },
  ["@punctuation.special.markdown"]    = { fg = p.ember, bold = true },
  ["@markup.list"]                     = { fg = p.sapphire },
  ["@markup.list.markdown"]            = { fg = p.ember, bold = true },

  -- Literals
  ["@string.documentation"]            = { fg = p.sunshine },
  ["@string.regex"]                    = { fg = p.ember },
  ["@string.escape"]                   = { fg = p.lime },
  ["@string.special"]                  = { fg = p.meadow },

  -- Functions
  ["@constructor"]                     = { fg = p.sunshine },
  ["@variable.parameter"]              = { fg = p.sunshine },
  ["@variable.parameter.builtin"]      = { fg = p.ember },

  -- Keywords
  ["@keyword"]                         = { link = "Keyword" },
  ["@keyword.function"]                = { link = "Keyword" },

  ["@label"]                           = { fg = p.lime },

  -- Types
  ["@type.builtin"]                    = { link = "Type" },
  ["@variable.member"]                 = { fg = p.sand },
  ["@property"]                        = { link = "Identifier" },

  -- Identifiers
  ["@variable"]                        = { link = "Identifier" },
  ["@variable.builtin"]                = { fg = p.gold },
  ["@module.builtin"]                  = { fg = p.gold },

  -- Text
  ["@markup.raw.markdown"]             = { fg = p.sapphire },
  ["@markup.raw.markdown_inline"]      = { fg = p.sand, bg = p.meadow },
  ["@markup.link"]                     = { fg = p.sapphire, underline = true },

  ["@markup.list.unchecked"]           = { fg = p.sand },
  ["@markup.list.checked"]             = { fg = p.lime },

  ["@diff.plus"]                       = { link = "DiffAdd" },
  ["@diff.minus"]                      = { link = "DiffDelete" },
  ["@diff.delta"]                      = { link = "DiffChange" },

  ["@module"]                          = { link = "Include" },

  ["@text"]                            = { fg = p.fg },
  ["@text.strong"]                     = { fg = p.fg, bold = true },
  ["@text.emphasis"]                   = { fg = p.alabaster },
  ["@text.underline"]                  = { fg = p.fg, underline = true },
  ["@text.strike"]                     = {},
  ["@text.title"]                      = { fg = p.alabaster, bold = true },
  ["@text.literal"]                    = { fg = p.fg },
  ["@text.quote"]                      = { fg = p.gold },
  ["@text.uri"]                        = { fg = p.meadow },
  ["@text.math"]                       = { fg = p.lilac },
  ["@text.reference"]                  = { fg = p.gold },

  ["@text.todo"]                       = { link = "Todo" },
  ["@text.note"]                       = { link = "Todo" },
  ["@text.warning"]                    = { link = "Warning" },
  ["@text.danger"]                     = { link = "Error" },

  ["@text.diff.add"]                   = { link = "DiffAdd" },
  ["@text.diff.delete"]                = { link = "DiffDelete" },

  ["@conceal"]                         = { link = "Conceal" },

  -- Legacy Treesitter highlight groups
  TSAnnotation                         = { link = "@annotation" },
  TSAttribute                          = { link = "@attribute" },
  TSBoolean                            = { link = "@boolean" },
  TSCharacter                          = { link = "@character" },
  TSCharacterSpecial                   = { link = "@character.special" },
  TSComment                            = { link = "@comment" },
  TSConditional                        = { link = "@keyword" },
  TSConstant                           = { link = "@constant" },
  TSConstBuiltin                       = { link = "@constant" },
  TSConstMacro                         = { link = "@constant.macro" },
  TSConstructor                        = { link = "@constructor" },
  TSDebug                              = { link = "@debug" },
  TSDefine                             = { link = "@define" },
  TSError                              = { link = "@error" },
  TSException                          = { link = "@exception" },
  TSField                              = { link = "@field" },
  TSFloat                              = { link = "@float" },
  TSFunction                           = { link = "@function" },
  TSFunctionCall                       = { link = "@function.call" },
  TSFuncBuiltin                        = { link = "@function.builtin" },
  TSFuncMacro                          = { link = "@function.macro" },
  TSInclude                            = { link = "@include" },
  TSKeyword                            = { link = "@keyword" },
  TSKeywordFunction                    = { link = "@keyword.function" },
  TSKeywordOperator                    = { link = "@keyword.operator" },
  TSKeywordReturn                      = { link = "@keyword.return" },
  TSLabel                              = { link = "@label" },
  TSMethod                             = { link = "@method" },
  TSMethodCall                         = { link = "@method.call" },
  TSNamespace                          = { link = "@namespace" },
  TSNone                               = { link = "@none" },
  TSNumber                             = { link = "@number" },
  TSOperator                           = { link = "@operator" },
  TSParameter                          = { link = "@parameter" },
  TSParameterReference                 = { link = "@parameter.reference" },
  TSPreProc                            = { link = "@preproc" },
  TSProperty                           = { link = "property" },
  TSPunctDelimiter                     = { link = "@punctuation.delimiter" },
  TSPunctBracket                       = { link = "@punctuation.bracket" },
  TSPunctSpecial                       = { link = "@punctuation.special" },
  TSRepeat                             = { link = "@repeat" },
  TSStorageClass                       = { link = "@storageclass" },
  TSString                             = { link = "@string" },
  TSStringRegex                        = { link = "@string.regex" },
  TSStringEscape                       = { link = "@string.escape" },
  TSStringSpecial                      = { link = "@string.special" },
  TSSymbol                             = { link = "@symbol" },
  TSTag                                = { link = "@tag" },
  TSTagAttribute                       = { link = "@tag.attribute" },
  TSTagDelimiter                       = { link = "@tag.delimiter" },
  TSText                               = { link = "@text" },
  TSStrong                             = { link = "@text.strong" },
  TSEmphasis                           = { link = "@text.emphasis" },
  TSUnderline                          = { link = "@text.underline" },
  TSStrike                             = { link = "@text.strike" },
  TSTitle                              = { link = "@text.title" },
  TSLiteral                            = { link = "@text.literal" },
  TSURI                                = { link = "@text.uri" },
  TSMath                               = { link = "@text.math" },
  TSTextReference                      = { link = "@text.reference" },
  TSEnvironment                        = { link = "@text.environment" },
  TSEnvironmentName                    = { link = "@text.environment.name" },
  TSNote                               = { link = "@text.note" },
  TSWarning                            = { link = "@text.warning" },
  TSDanger                             = { link = "@text.danger" },
  TSTodo                               = { link = "@text.todo" },
  TSType                               = { link = "@type" },
  TSTypeBuiltin                        = { link = "@type.builtin" },
  TSTypeQualifier                      = { link = "@type.qualifier" },
  TSTypeDefinition                     = { link = "@type.definition" },
  TSVariable                           = { link = "@variable" },
  TSVariableBuiltin                    = { link = "@variable.builtin" },

  -- rainbow-delimiters
  RainbowDelimiterRed                  = { fg = p.crimson },
  RainbowDelimiterYellow               = { fg = p.gold },
  RainbowDelimiterBlue                 = { fg = p.alabaster },
  RainbowDelimiterOrange               = { fg = p.sunshine },
  RainbowDelimiterGreen                = { fg = p.meadow },
  RainbowDelimiterViolet               = { fg = p.lilac },
  RainbowDelimiterCyan                 = { fg = p.sapphire },

  -- LSP / Diagnostics
  LspDiagnosticsError                  = { fg = p.error, bg = p.error_bg },
  LspDiagnosticsDefaultError           = { fg = p.error, bg = p.error_bg },
  LspDiagnosticsSignError              = { fg = p.error },
  LspDiagnosticsFloatingError          = { fg = p.error, bg = p.error_bg },
  LspDiagnosticsVirtualTextError       = { fg = p.error, bg = p.error_bg },
  LspDiagnosticsUnderlineError         = { undercurl = true, special = p.error },
  DiagnosticError                      = { fg = p.error },
  DiagnosticSignError                  = { fg = p.error },
  DiagnosticUnderlineError             = { undercurl = true, special = p.error },
  DiagnosticFloatingError              = { fg = p.error, bg = p.error_bg },
  DiagnosticVirtualTextError           = { fg = p.error, bg = p.error_bg },

  LspDiagnosticsWarning                = { fg = p.warning, bg = p.warning_bg },
  LspDiagnosticsDefaultWarning         = { fg = p.warning, bg = p.warning_bg },
  LspDiagnosticsSignWarning            = { fg = p.warning },
  LspDiagnosticsFloatingWarning        = { fg = p.warning, bg = p.warning_bg },
  LspDiagnosticsVirtualTextWarning     = { fg = p.warning, bg = p.warning_bg },
  LspDiagnosticsUnderlineWarning       = { undercurl = true, special = p.warning },
  DiagnosticSignWarning                = { fg = p.warning },
  DiagnosticUnderlineWarn              = { undercurl = true, special = p.warning },
  DiagnosticVirtualTextWarn            = { fg = p.warning, bg = p.warning_bg },
  DiagnosticFloatingWarn               = { fg = p.warning, bg = p.warning_bg },

  LspDiagnosticsInformation            = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsDefaultInformation     = { fg = p.info_bg, bg = p.info_bg },
  LspDiagnosticsSignInformation        = { fg = p.info },
  LspDiagnosticsFloatingInformation    = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsVirtualTextInformation = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsUnderlineInformation   = { undercurl = true, special = p.info_bg },
  DiagnosticSignInformation            = { fg = p.info },

  LspDiagnosticsInfo                   = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsDefaultInfo            = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsSignInfo               = { fg = p.info },
  LspDiagnosticsFloatingInfo           = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsVirtualTextInfo        = { fg = p.info, bg = p.info_bg },
  LspDiagnosticsUnderlineInfo          = { undercurl = true, special = p.info },
  DiagnosticInfo                       = { fg = p.info },
  DiagnosticSignInfo                   = { fg = p.info },
  DiagnosticFloatingInfo               = { fg = p.info, bg = p.info_bg },
  DiagnosticVirtualTextInfo            = { fg = p.info, bg = p.info_bg },
  DiagnosticUnderlineInfo              = { undercurl = true, special = p.info },

  LspDiagnosticsHint                   = { fg = p.hint, bg = p.hint_bg },
  LspDiagnosticsDefaultHint            = { fg = p.hint, bg = p.hint_bg },
  LspDiagnosticsSignHint               = { fg = p.hint },
  LspDiagnosticsFloatingHint           = { fg = p.hint, bg = p.hint_bg },
  LspDiagnosticsVirtualTextHint        = { fg = p.hint, bg = p.hint_bg },
  LspDiagnosticsUnderlineHint          = { undercurl = true, special = p.hint },
  DiagnosticHint                       = { fg = p.hint },
  DiagnosticSignHint                   = { fg = p.hint },
  DiagnosticFloatingHint               = { fg = p.hint, bg = p.hint_bg },
  DiagnosticVirtualTextHint            = { fg = p.hint, bg = p.hint_bg },
  DiagnosticUnderlineHint              = { undercurl = true, special = p.hint },

  DiagnosticOther                      = { fg = p.silver },
  DiagnosticSignOther                  = { fg = p.silver },

  LspReferenceRead                     = { bg = p.info_bg },
  LspReferenceText                     = { bg = p.info_bg },
  LspReferenceWrite                    = { bg = p.info_bg },

  -- Git
  DiffAdd                              = { fg = p.plus },
  DiffChange                           = { fg = p.hint },
  DiffDelete                           = { fg = p.error },
  DiffText                             = { fg = p.warning },
  diffAdded                            = { link = "DiffAdd" },
  diffRemoved                          = { link = "DiffDelete" },
  diffChanged                          = { link = "DiffChange" },

  SignAdd                              = { link = "DiffAdd" },
  GitSignsAdd                          = { link = "DiffAdd" },
  GitSignsAddNr                        = { link = "DiffAdd" },
  GitSignsAddLn                        = { link = "DiffAdd" },

  SignChange                           = { link = "DiffChange" },
  GitSignsChange                       = { link = "DiffChange" },
  GitSignsChangeNr                     = { link = "DiffChange" },
  GitSignsChangeLn                     = { link = "DiffChange" },

  SignDelete                           = { link = "DiffDelete" },
  GitSignsDelete                       = { link = "DiffDelete" },
  GitSignsDeleteNr                     = { link = "DiffDelete" },
  GitSignsDeleteLn                     = { link = "DiffDelete" },

  GitSignsAddInline                    = { link = "DiffAdd" },
  GitSignsChangeInline                 = { link = "DiffChange" },
  GitSignsDeleteInline                 = { link = "DiffDelete" },

  -- Telescope
  TelescopePromptBorder                = { fg = p.gold },
  TelescopeResultsBorder               = { fg = p.gold },
  TelescopePreviewBorder               = { fg = p.lime },
  TelescopeSelectionCaret              = { fg = p.sand },
  TelescopeSelection                   = { fg = p.sunshine },
  TelescopeMatching                    = { fg = p.sapphire },
  TelescopeNormal                      = { fg = p.fg, bg = bg },

  -- Whichkey
  WhichKey                             = { fg = p.sunshine, bold = true },
  WhichKeyGroup                        = { fg = p.gold },
  WhichKeyDesc                         = { fg = p.sapphire, italic = true },
  WhichKeySeperator                    = { fg = p.silver },
  WhichKeySeparator                    = { fg = p.silver },
  WhichKeyValue                        = { fg = p.silver },
  WhichKeyNormal                       = { link = "NormalFloat" },
  WhichKeyBorder                       = { link = "FloatBorder" },
  WhichKeyTitle                        = { link = "FloatTitle" },
  WhichKeyFloating                     = { link = "NormalFloat" },
  WhichKeyFloat                        = { link = "NormalFloat" },

  -- LspSaga
  DiagnosticWarning                    = { fg = p.warning },
  DiagnosticInformation                = { fg = p.info },
  DiagnosticTruncateLine               = { fg = p.fg },
  LspFloatWinNormal                    = { fg = p.contrast },
  LspFloatWinBorder                    = { fg = p.sunshine },
  LspSagaBorderTitle                   = { fg = p.sapphire },
  LspSagaHoverBorder                   = { fg = p.gold },
  LspSagaRenameBorder                  = { fg = p.meadow },
  LspSagaDefPreviewBorder              = { fg = p.meadow },
  LspSagaCodeActionBorder              = { fg = p.sapphire },
  LspSagaFinderSelection               = { fg = p.meadow },
  LspSagaCodeActionTitle               = { fg = p.sunshine },
  LspSagaCodeActionContent             = { fg = p.sunshine },
  LspSagaSignatureHelpBorder           = { fg = p.lilac },
  ReferencesCount                      = { fg = p.sunshine },
  DefinitionCount                      = { fg = p.sunshine },
  DefinitionIcon                       = { fg = p.sapphire },
  ReferencesIcon                       = { fg = p.sapphire },
  TargetWord                           = { fg = p.ember },

  -- StatusLine
  StatusLine                           = { fg = p.silver, bg = p.black },
  StatusLineNC                         = { fg = p.fg, bg = p.black },
  StatusLineTerm                       = { fg = p.fg, bg = p.contrast },
  StatusLineTermNC                     = { fg = p.fg, bg = p.black },

  -- BufferLine
  BufferLineIndicatorSelected          = { fg = p.alabaster },
  BufferLineFill                       = { bg = p.black },

  -- IndentBlankline v2
  IndentBlanklineChar                  = { fg = p.surface2 },
  IndentBlanklineContextChar           = { fg = p.gold },

  -- IndentBlankline v3
  IblIndent                            = { link = "IndentBlanklineChar" },
  IblScope                             = { link = "IndentBlanklineContextChar" },

  -- Dashboard
  DashboardShortCut                    = { fg = p.sunshine },
  DashboardHeader                      = { fg = p.crimson },
  DashboardCenter                      = { fg = p.sapphire },
  DashboardFooter                      = { fg = p.meadow, italic = true },

  -- alerts
  ErrorMsg                             = { fg = p.error },
  ModeMsg                              = { fg = p.sapphire },
  MoreMsg                              = { fg = p.sapphire },
  WarningMsg                           = { fg = p.warning },
}

for group, settings in pairs(groups) do
  vim.api.nvim_set_hl(0, group, settings)
end

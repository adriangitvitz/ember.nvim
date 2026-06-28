set background=dark
hi! clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name="midnight-ember"
let colors_name="midnight-ember"

" Background
let s:bg         = "#222831"
let s:bg_dark    = "#1B262C"
let s:bg_darker  = "#313131"
let s:bg_light   = "#393E46"
let s:bg_medium  = "#414141"

" Foreground
let s:fg         = "#c1c1c1"
let s:fg_soft    = "#d2bf98"
let s:fg_bright  = "#ECDBBA"

" Amber gradient (smooth transitions)
let s:amber_bright = "#e9bd47"
let s:amber_medium = "#ECB365"
let s:amber_deep   = "#efaf56"

" Colors
let s:gold       = "#e5b732"
let s:red_error  = "#ff9a91"
let s:red_keyword = "#ff9773"
let s:red_operator = "#ff95ac"
let s:blue_type  = "#9db9da"
let s:green_success = "#88c4a8"
let s:comment    = "#b8b8b8"
let s:comment_dim = "#8a8a8a"

" UI
let s:selection  = "#362222"
let s:border     = "#393E46"
let s:visual     = "#30475E"
let s:cursor_line = "#313131"
let s:line_nr    = "#b8b8b8"
let s:match_paren = "#e9bd47"
let s:search     = "#efaf56"

" None
let s:none       = "NONE"

exe 'hi Normal guifg=' . s:fg . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NormalFloat guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NormalNC guifg=' . s:fg . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi Comment guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi ColorColumn guifg=NONE guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi Cursor guifg=' . s:bg . ' guibg=' . s:fg . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi CursorLine guifg=NONE guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi CursorLineNr guifg=' . s:amber_bright . ' guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=bold'
exe 'hi CursorColumn guifg=NONE guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi LineNr guifg=' . s:line_nr . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi SignColumn guifg=' . s:line_nr . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi FoldColumn guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Folded guifg=' . s:comment . ' guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=italic'

exe 'hi MatchParen guifg=' . s:match_paren . ' guibg=NONE guisp=NONE blend=NONE gui=bold'

exe 'hi Visual guifg=NONE guibg=' . s:visual . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi VisualNOS guifg=NONE guibg=' . s:visual . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi Search guifg=' . s:bg . ' guibg=' . s:search . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi IncSearch guifg=' . s:bg . ' guibg=' . s:amber_bright . ' guisp=NONE blend=NONE gui=bold'
exe 'hi Substitute guifg=' . s:bg . ' guibg=' . s:amber_bright . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi Pmenu guifg=' . s:fg . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi PmenuSel guifg=' . s:bg . ' guibg=' . s:amber_medium . ' guisp=NONE blend=NONE gui=bold'
exe 'hi PmenuSbar guifg=NONE guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi PmenuThumb guifg=NONE guibg=' . s:comment . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi StatusLine guifg=' . s:fg . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi StatusLineNC guifg=' . s:comment . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi TabLine guifg=' . s:comment . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TabLineFill guifg=NONE guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TabLineSel guifg=' . s:fg . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=bold'

exe 'hi VertSplit guifg=' . s:border . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi WinSeparator guifg=' . s:border . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi WildMenu guifg=' . s:bg . ' guibg=' . s:amber_medium . ' guisp=NONE blend=NONE gui=bold'

exe 'hi Directory guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Title guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'

exe 'hi ErrorMsg guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi WarningMsg guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi ModeMsg guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi MoreMsg guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Question guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi SpecialKey guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NonText guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Whitespace guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi EndOfBuffer guifg=' . s:bg . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Conceal guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi FloatBorder guifg=' . s:border . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi FloatTitle guifg=' . s:amber_bright . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=bold'

exe 'hi QuickFixLine guifg=NONE guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi qfLineNr guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi qfFileName guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Constant guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi String guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Character guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Number guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Float guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Boolean guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Identifier guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Function guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Statement guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Conditional guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Repeat guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Label guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Operator guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Keyword guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Exception guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi PreProc guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Include guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Define guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Macro guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi PreCondit guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Type guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi StorageClass guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Structure guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Typedef guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Special guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi SpecialChar guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Tag guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Delimiter guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi SpecialComment guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic,bold'
exe 'hi Debug guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi Underlined guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=underline'
exe 'hi Ignore guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi Error guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi Todo guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold,italic'

exe 'hi DiffAdd guifg=' . s:green_success . ' guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiffChange guifg=' . s:amber_deep . ' guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiffDelete guifg=' . s:red_error . ' guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiffText guifg=' . s:amber_bright . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=bold'

exe 'hi diffAdded guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi diffChanged guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi diffRemoved guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi diffFile guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi diffLine guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi diffIndexLine guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi DiagnosticError guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticWarn guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticInfo guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticHint guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticOk guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi DiagnosticUnderlineError guifg=NONE guibg=NONE guisp=' . s:red_error . ' blend=NONE gui=underline'
exe 'hi DiagnosticUnderlineWarn guifg=NONE guibg=NONE guisp=' . s:amber_bright . ' blend=NONE gui=underline'
exe 'hi DiagnosticUnderlineInfo guifg=NONE guibg=NONE guisp=' . s:amber_medium . ' blend=NONE gui=underline'
exe 'hi DiagnosticUnderlineHint guifg=NONE guibg=NONE guisp=' . s:green_success . ' blend=NONE gui=underline'
exe 'hi DiagnosticUnderlineOk guifg=NONE guibg=NONE guisp=' . s:green_success . ' blend=NONE gui=underline'

exe 'hi DiagnosticVirtualTextError guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi DiagnosticVirtualTextWarn guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi DiagnosticVirtualTextInfo guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi DiagnosticVirtualTextHint guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=italic'

exe 'hi DiagnosticSignError guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticSignWarn guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticSignInfo guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticSignHint guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi DiagnosticFloatingError guifg=' . s:red_error . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticFloatingWarn guifg=' . s:amber_bright . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticFloatingInfo guifg=' . s:amber_medium . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi DiagnosticFloatingHint guifg=' . s:green_success . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi LspReferenceText guifg=NONE guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi LspReferenceRead guifg=NONE guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi LspReferenceWrite guifg=NONE guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi LspSignatureActiveParameter guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi LspCodeLens guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi LspCodeLensSeparator guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @variable Identifier
hi! link @variable.builtin Constant
hi! link @variable.parameter Identifier
hi! link @variable.member Identifier

hi! link @constant Constant
hi! link @constant.builtin Constant
hi! link @constant.macro Macro

exe 'hi @module guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @module.builtin guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
hi! link @label Label

hi! link @string String
exe 'hi @string.documentation guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi @string.escape guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @string.regexp guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @string.special guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @character Character
exe 'hi @character.special guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @number Number
hi! link @number.float Float
hi! link @boolean Boolean

hi! link @function Function
hi! link @function.builtin Function
exe 'hi @function.call guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
hi! link @function.macro Macro
hi! link @function.method Function
exe 'hi @function.method.call guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi @constructor guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @keyword Keyword
exe 'hi @keyword.coroutine guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
hi! link @keyword.function Keyword
exe 'hi @keyword.operator guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
hi! link @keyword.import Include
hi! link @keyword.repeat Repeat
hi! link @keyword.return Keyword
hi! link @keyword.conditional Conditional
hi! link @keyword.exception Exception
hi! link @keyword.directive PreProc
hi! link @keyword.type Type

hi! link @operator Operator

hi! link @punctuation.delimiter Delimiter
hi! link @punctuation.bracket Delimiter
exe 'hi @punctuation.special guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @comment Comment
exe 'hi @comment.documentation guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic,bold'
hi! link @comment.error DiagnosticError
hi! link @comment.warning DiagnosticWarn
hi! link @comment.todo Todo
hi! link @comment.note SpecialComment

exe 'hi @markup.strong guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi @markup.italic guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi @markup.strikethrough guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=strikethrough'
exe 'hi @markup.underline guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=underline'
exe 'hi @markup.heading guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi @markup.quote guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi @markup.math guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @markup.link guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=underline'
exe 'hi @markup.link.label guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @markup.link.url guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=underline'
exe 'hi @markup.raw guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @markup.list guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @markup.list.checked guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @markup.list.unchecked guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @tag Tag
exe 'hi @tag.attribute guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
hi! link @tag.delimiter Delimiter

hi! link @type Type
hi! link @type.builtin Type
exe 'hi @type.definition guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @type.qualifier guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi @attribute guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi @property guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

hi! link @diff.plus DiffAdd
hi! link @diff.minus DiffDelete
hi! link @diff.delta DiffChange

exe 'hi GitSignsAdd guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi GitSignsChange guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi GitSignsDelete guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi GitSignsCurrentLineBlame guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'

exe 'hi CmpItemAbbr guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemAbbrDeprecated guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=strikethrough'
exe 'hi CmpItemAbbrMatch guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi CmpItemAbbrMatchFuzzy guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=bold'

exe 'hi CmpItemKindDefault guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindKeyword guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindVariable guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindConstant guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindReference guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindValue guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindFunction guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindMethod guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindConstructor guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindClass guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindInterface guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindStruct guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindEvent guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindEnum guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindUnit guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindModule guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindProperty guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindField guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindTypeParameter guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindEnumMember guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindOperator guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindSnippet guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindText guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindFile guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindFolder guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi CmpItemKindColor guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi CmpItemMenu guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'

exe 'hi TelescopeBorder guifg=' . s:border . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopeNormal guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopePromptNormal guifg=' . s:fg . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopePromptBorder guifg=' . s:border . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopePromptTitle guifg=' . s:amber_bright . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=bold'
exe 'hi TelescopePromptPrefix guifg=' . s:amber_bright . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=bold'
exe 'hi TelescopeResultsTitle guifg=' . s:fg_soft . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=bold'
exe 'hi TelescopePreviewTitle guifg=' . s:green_success . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=bold'

exe 'hi TelescopeSelection guifg=' . s:fg_bright . ' guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=bold'
exe 'hi TelescopeSelectionCaret guifg=' . s:amber_bright . ' guibg=' . s:cursor_line . ' guisp=NONE blend=NONE gui=bold'

exe 'hi TelescopeMatching guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'

exe 'hi TelescopeResultsNormal guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopeResultsComment guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi TelescopeResultsSpecialComment guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic,bold'
exe 'hi TelescopeResultsDiffAdd guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopeResultsDiffChange guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi TelescopeResultsDiffDelete guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi TelescopeMultiSelection guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi TelescopeMultiIcon guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi NvimTreeNormal guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeNormalNC guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeRootFolder guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NvimTreeFolderName guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeFolderIcon guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeEmptyFolderName guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeOpenedFolderName guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NvimTreeSymlink guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi NvimTreeExecFile guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NvimTreeSpecialFile guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NvimTreeImageFile guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi NvimTreeGitDirty guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeGitStaged guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeGitMerge guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeGitRenamed guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeGitNew guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeGitDeleted guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi NvimTreeIndentMarker guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NvimTreeWinSeparator guifg=' . s:border . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi NeoTreeNormal guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeNormalNC guifg=' . s:fg . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeDirectoryName guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeDirectoryIcon guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeFileName guifg=' . s:fg . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeFileIcon guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeRootName guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NeoTreeGitAdded guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeGitConflict guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NeoTreeGitDeleted guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeGitIgnored guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi NeoTreeGitModified guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeGitUntracked guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NeoTreeIndentMarker guifg=' . s:comment_dim . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi BufferLineFill guifg=NONE guibg=' . s:bg_darker . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineBackground guifg=' . s:comment . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineBuffer guifg=' . s:comment . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineBufferSelected guifg=' . s:fg . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=bold'
exe 'hi BufferLineBufferVisible guifg=' . s:fg_soft . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineTab guifg=' . s:comment . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineTabSelected guifg=' . s:fg . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=bold'
exe 'hi BufferLineSeparator guifg=' . s:bg_darker . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineSeparatorSelected guifg=' . s:bg_darker . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineSeparatorVisible guifg=' . s:bg_darker . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineModified guifg=' . s:amber_bright . ' guibg=' . s:bg_medium . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi BufferLineModifiedSelected guifg=' . s:amber_bright . ' guibg=' . s:bg . ' guisp=NONE blend=NONE gui=bold'
exe 'hi BufferLineModifiedVisible guifg=' . s:amber_bright . ' guibg=' . s:bg_light . ' guisp=NONE blend=NONE gui=NONE'

exe 'hi IndentBlanklineChar guifg=' . s:bg_light . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi IndentBlanklineContextChar guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi IndentBlanklineContextStart guifg=NONE guibg=NONE guisp=' . s:comment . ' blend=NONE gui=underline'
exe 'hi IndentBlanklineSpaceChar guifg=' . s:bg_light . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

exe 'hi NotifyERRORBorder guifg=' . s:red_error . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyWARNBorder guifg=' . s:amber_bright . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyINFOBorder guifg=' . s:amber_medium . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyDEBUGBorder guifg=' . s:comment . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyTRACEBorder guifg=' . s:blue_type . ' guibg=' . s:bg_dark . ' guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyERRORIcon guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyWARNIcon guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyINFOIcon guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyDEBUGIcon guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyTRACEIcon guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi NotifyERRORTitle guifg=' . s:red_error . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NotifyWARNTitle guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NotifyINFOTitle guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NotifyDEBUGTitle guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi NotifyTRACETitle guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=bold'

" Python
exe 'hi pythonBuiltin guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi pythonDecorator guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi pythonException guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" JavaScript/TypeScript
exe 'hi jsFunction guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi jsArrowFunction guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi jsThis guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi tsxTag guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi tsxTagName guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi tsxAttrib guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" Rust
exe 'hi rustModPath guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi rustMacro guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi rustLifetime guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=italic'
exe 'hi rustAttribute guifg=' . s:comment . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" Go
exe 'hi goPackage guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi goImport guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi goBuiltins guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" C/C++
exe 'hi cInclude guifg=' . s:red_operator . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi cppSTLnamespace guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" Lua
exe 'hi luaFunc guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi luaTable guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" HTML/CSS
exe 'hi htmlTag guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi htmlTagName guifg=' . s:red_keyword . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi htmlArg guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi cssClassName guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi cssProp guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi cssColor guifg=' . s:amber_medium . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" Markdown
exe 'hi markdownH1 guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi markdownH2 guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi markdownH3 guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi markdownH4 guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=bold'
exe 'hi markdownCode guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi markdownCodeBlock guifg=' . s:green_success . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi markdownUrl guifg=' . s:blue_type . ' guibg=NONE guisp=NONE blend=NONE gui=underline'
exe 'hi markdownLinkText guifg=' . s:amber_deep . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" Bash
exe 'hi shDerefVar guifg=' . s:fg_soft . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'
exe 'hi shQuote guifg=' . s:amber_bright . ' guibg=NONE guisp=NONE blend=NONE gui=NONE'

" vim:foldmethod=marker:foldlevel=0

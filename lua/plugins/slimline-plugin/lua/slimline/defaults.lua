local M = {
  bold = false,
  style = 'fg',
  components = {
    left = {
      'mode',
      'path',
      'git',
    },
    center = {},
    right = {
      'diagnostics',
      'filetype_lsp',
      'pm',
      'progress',
    },
  },
  components_inactive = {},
  configs = {
    mode = {
      style = 'bg',
      sep = { left = '', right = '' },
      verbose = false,
      hl = {
        normal = 'Type',
        visual = 'Keyword',
        insert = 'Function',
        replace = 'Statement',
        command = 'String',
        other = 'Function',
      },
      format = {
        ['n'] = { verbose = 'NORMAL', short = 'N' },
        ['v'] = { verbose = 'VISUAL', short = 'V' },
        ['V'] = { verbose = 'V-LINE', short = 'V-L' },
        ['\22'] = { verbose = 'V-BLOCK', short = 'V-B' },
        ['s'] = { verbose = 'SELECT', short = 'S' },
        ['S'] = { verbose = 'S-LINE', short = 'S-L' },
        ['\19'] = { verbose = 'S-BLOCK', short = 'S-B' },
        ['i'] = { verbose = 'INSERT', short = 'I' },
        ['R'] = { verbose = 'REPLACE', short = 'R' },
        ['c'] = { verbose = 'COMMAND', short = 'C' },
        ['r'] = { verbose = 'PROMPT', short = 'P' },
        ['!'] = { verbose = 'SHELL', short = 'S' },
        ['t'] = { verbose = 'TERMINAL', short = 'T' },
        ['U'] = { verbose = 'UNKNOWN', short = 'U' },
      },
    },
    path = {
      trunc_width = 60,
      directory = true,
      truncate = {
        chars = 1,
        full_dirs = 2,
      },
      icons = {
        folder = ' ',
        modified = '',
        read_only = '',
      },
    },
    git = {
      trunc_width = 120,
      icons = {
        branch = '',
        added = '+',
        modified = '~',
        removed = '-',
      },
    },
    diagnostics = {
      trunc_width = 75,
      workspace = false,
      icons = {
        ERROR = ' ',
        WARN = ' ',
        HINT = ' ',
        INFO = ' ',
      },
      severity = {
        min = vim.diagnostic.severity.HINT,
      },
      hl = {
        error = 'DiagnosticError',
        warn = 'DiagnosticWarn',
        hint = 'DiagnosticHint',
        info = 'DiagnosticInfo',
      },
    },
    filetype_lsp = {
      trunc_width = 95,
      map_lsps = {},
      lsp_sep = ',',
      show_status = true,
      show_progress = true,
      icons = {
        ready = '*',
        error = '!',
      },
    },
    pm = {
      trunc_width = 140,
      icon = '',
      hl = { primary = 'SlimlinePm' },
    },
    selectioncount = {
      hl = {
        primary = 'Special',
      },
      icon = '󰔌 ',
    },
    searchcount = {
      hl = {
        primary = 'Special',
      },
      icon = ' ',
      options = {
        recompute = true,
      },
    },
    progress = {
      style = 'bg',
      follow = 'mode',
      column = false,
      icon = ' ',
    },
    recording = {
      icon = ' ',
      hl = {
        primary = 'Special',
      },
    },
  },
  spaces = {
    components = ' ',
    left = ' ',
    right = ' ',
  },
  sep = {
    hide = {
      first = false,
      last = false,
    },
    left = '',
    right = '',
  },
  hl = {
    base = 'Normal',
    base_inactive = 'Normal',
    primary = 'Normal',
    secondary = 'Comment',
  },
  disabled_filetypes = {},
}
return M

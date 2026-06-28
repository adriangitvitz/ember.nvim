# ember.nvim

A minimal, self-contained Neovim framework. Everything is bundled — there is no
plugin manager to bootstrap and nothing to download at startup. Plugins, LSP
setup, Treesitter, formatting, the statusline, and the colorschemes all ship in
the repo and load instantly. Drop it in as your config and it just runs.

## Requirements

These are needed for the core experience:

- **Neovim 0.10+** (0.11+ recommended for the latest Treesitter APIs)
- **git** — version signs, git tools, and Treesitter parser installs
- **ripgrep** (`rg`) — grep / live search
- **fd** (`fd-find`) — file finding
- **A C compiler** (`cc`/`clang`/`gcc`) — Treesitter compiles parsers on first run
- **A Nerd Font** — for the icons in the UI and statusline

Run `:checkhealth ember` after launching to see exactly what's present and what's
missing on your system.

## Recommended

ember detects these at runtime and silently skips whatever isn't installed —
install only what you need for the languages you use.

**Fuzzy finder previews:** `fzf` and `bat` (used by the bundled picker for live
search and syntax-highlighted previews).

**Language servers:** `pyright`, `lua-language-server`, `typescript-language-server`,
`zls`, `clangd`, `rust-analyzer`, `gopls`, `crystalline`, `ols` (Odin),
`nimlangserver`.

**Formatters:** `ruff` (Python), `stylua` (Lua), `prettierd` (JS/TS),
`rustfmt` (Rust), `gofumpt` (Go), `clang-format` (C/C++).

**Optional CLI tools:** `lazygit` and `lazydocker` (terminal toggles), plus
`pm` and `dn-tui` for the project/notes integrations.

## What's included

Native Neovim LSP wired up for **Python, Lua, TypeScript, Zig, C/C++, Rust, Go,
Crystal, Odin, and Nim** — servers that aren't installed are skipped
automatically. Treesitter is set up with auto-installed parsers plus
Treesitter-based folding and indentation, and formatting is handled per language.

It ships with three colorschemes (`deep-teal-calm` — the default —
`midnight-ember`, and `gruvbox`) and a set of bundled plugins, all written for
or vendored into the framework:

- **picker** — fuzzy finder for files, live grep, and LSP symbols
- **lsp-enhanced** — richer LSP hover and UI
- **bento** — buffer manager and bufferline
- **emberline** — statusline
- **miniterm** — floating and split terminals, with lazygit / lazydocker toggles
- **gitsigns** + **git-extras** — inline git signs, hunks, and extra git actions
- **format** — on-save and on-demand formatting
- **which-key** — keymap discovery
- **quicksearch** + **searchr** — quickfix search and project search/replace
- **kb / notelinks** + **orgdown** + **render-markdown** — notes, wiki-links,
  backlinks, and in-buffer Markdown rendering
- **pm** — project and task management
- **pyeval** — inline Python evaluation
- **autopairs**, **bookmarks**, and an optional **leetcode** integration

Personal tweaks go in a `lua/user/` directory that ember creates for you on first
launch, so you can override config and add your own plugins without touching the
framework itself.

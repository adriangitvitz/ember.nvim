return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "markdown",
        "markdown_inline",
        "latex",

        "python",
        "lua",
        "javascript",
        "typescript",
        "tsx",
        "zig",
        "c",
        "cpp",
        "rust",
        "go",
        "gomod",
        "gosum",
        "odin",
        "nim",

        "json",
        "jsonc",
        "yaml",
        "toml",
        "html",
        "css",
        "bash",
        "regex",
        "comment",
        "diff",
        "gitcommit",
        "gitignore",
        "vim",
        "vimdoc",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
    })
  end,
}

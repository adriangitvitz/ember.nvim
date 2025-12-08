local M = {}
M.by_extension = {
  lua = { icon = "", color = "#51a0cf", name = "Lua" },
  py = { icon = "", color = "#ffbc03", name = "Python" },
  rs = { icon = "", color = "#dea584", name = "Rust" },
  go = { icon = "", color = "#519aba", name = "Go" },
  js = { icon = "", color = "#f7df1e", name = "JavaScript" },
  ts = { icon = "", color = "#007acc", name = "TypeScript" },
  jsx = { icon = "", color = "#61dafb", name = "React" },
  tsx = { icon = "", color = "#007acc", name = "TypeScript React" },
  c = { icon = "", color = "#599eff", name = "C" },
  cpp = { icon = "", color = "#f34b7d", name = "C++" },
  h = { icon = "", color = "#a074c4", name = "Header" },
  hpp = { icon = "", color = "#a074c4", name = "C++ Header" },
  cs = { icon = "", color = "#596706", name = "C#" },
  java = { icon = "", color = "#cc3e44", name = "Java" },
  rb = { icon = "", color = "#cc342d", name = "Ruby" },
  php = { icon = "", color = "#a074c4", name = "PHP" },
  swift = { icon = "", color = "#e37933", name = "Swift" },
  kt = { icon = "", color = "#f88a02", name = "Kotlin" },
  scala = { icon = "", color = "#cc3e44", name = "Scala" },
  zig = { icon = "", color = "#f69a1b", name = "Zig" },
  nim = { icon = "", color = "#f3d400", name = "Nim" },
  cr = { icon = "", color = "#000000", name = "Crystal" },
  odin = { icon = "", color = "#3882d7", name = "Odin" },
  hs = { icon = "", color = "#a074c4", name = "Haskell" },
  ml = { icon = "λ", color = "#e37933", name = "OCaml" },
  ex = { icon = "", color = "#a074c4", name = "Elixir" },
  exs = { icon = "", color = "#a074c4", name = "Elixir Script" },
  erl = { icon = "", color = "#b83998", name = "Erlang" },
  clj = { icon = "", color = "#8dc149", name = "Clojure" },
  r = { icon = "󰟔", color = "#2266ba", name = "R" },
  jl = { icon = "", color = "#a270ba", name = "Julia" },
  dart = { icon = "", color = "#00b4ab", name = "Dart" },
  v = { icon = "", color = "#5d87bf", name = "V" },
  sh = { icon = "", color = "#4d5a5e", name = "Shell" },
  bash = { icon = "", color = "#4d5a5e", name = "Bash" },
  zsh = { icon = "", color = "#4d5a5e", name = "Zsh" },
  fish = { icon = "", color = "#4d5a5e", name = "Fish" },
  ps1 = { icon = "", color = "#012456", name = "PowerShell" },
  json = { icon = "", color = "#cbcb41", name = "JSON" },
  yaml = { icon = "", color = "#cb171e", name = "YAML" },
  yml = { icon = "", color = "#cb171e", name = "YAML" },
  toml = { icon = "", color = "#9c4221", name = "TOML" },
  xml = { icon = "󰗀", color = "#e37933", name = "XML" },
  csv = { icon = "", color = "#89e051", name = "CSV" },
  sql = { icon = "", color = "#dad8d8", name = "SQL" },
  graphql = { icon = "", color = "#e535ab", name = "GraphQL" },
  prisma = { icon = "", color = "#5a67d8", name = "Prisma" },
  html = { icon = "", color = "#e44d26", name = "HTML" },
  css = { icon = "", color = "#42a5f5", name = "CSS" },
  scss = { icon = "", color = "#f55385", name = "SCSS" },
  sass = { icon = "", color = "#f55385", name = "Sass" },
  less = { icon = "", color = "#563d7c", name = "Less" },
  vue = { icon = "", color = "#8dc149", name = "Vue" },
  svelte = { icon = "", color = "#ff3e00", name = "Svelte" },
  md = { icon = "", color = "#ffffff", name = "Markdown" },
  mdx = { icon = "", color = "#519aba", name = "MDX" },
  org = { icon = "", color = "#77aa99", name = "Org" },
  txt = { icon = "", color = "#89e051", name = "Text" },
  rst = { icon = "", color = "#8dc149", name = "reStructuredText" },
  tex = { icon = "", color = "#3d6117", name = "TeX" },
  pdf = { icon = "", color = "#b30b00", name = "PDF" },
  makefile = { icon = "", color = "#6d8086", name = "Makefile" },
  dockerfile = { icon = "", color = "#458ee6", name = "Dockerfile" },
  cmake = { icon = "", color = "#6d8086", name = "CMake" },
  gitignore = { icon = "", color = "#f54d27", name = "Git Ignore" },
  gitattributes = { icon = "", color = "#f54d27", name = "Git Attributes" },
  gitmodules = { icon = "", color = "#f54d27", name = "Git Modules" },
  env = { icon = "", color = "#faf743", name = "Environment" },
  ini = { icon = "", color = "#6d8086", name = "INI" },
  conf = { icon = "", color = "#6d8086", name = "Config" },
  png = { icon = "", color = "#a074c4", name = "PNG" },
  jpg = { icon = "", color = "#a074c4", name = "JPEG" },
  jpeg = { icon = "", color = "#a074c4", name = "JPEG" },
  gif = { icon = "", color = "#a074c4", name = "GIF" },
  svg = { icon = "", color = "#ffb13b", name = "SVG" },
  ico = { icon = "", color = "#cbcb41", name = "Icon" },
  webp = { icon = "", color = "#a074c4", name = "WebP" },
  zip = { icon = "", color = "#eca517", name = "Zip" },
  tar = { icon = "", color = "#eca517", name = "Tar" },
  gz = { icon = "", color = "#eca517", name = "Gzip" },
  xz = { icon = "", color = "#eca517", name = "XZ" },
  rar = { icon = "", color = "#eca517", name = "RAR" },
  ["7z"] = { icon = "", color = "#eca517", name = "7-Zip" },
  mp3 = { icon = "", color = "#d39ede", name = "MP3" },
  mp4 = { icon = "", color = "#9ea7aa", name = "MP4" },
  wav = { icon = "", color = "#d39ede", name = "WAV" },
  mkv = { icon = "", color = "#9ea7aa", name = "MKV" },
  avi = { icon = "", color = "#9ea7aa", name = "AVI" },
  ttf = { icon = "", color = "#ececec", name = "TrueType Font" },
  otf = { icon = "", color = "#ececec", name = "OpenType Font" },
  woff = { icon = "", color = "#ececec", name = "Web Font" },
  woff2 = { icon = "", color = "#ececec", name = "Web Font 2" },
  lock = { icon = "", color = "#bbbbbb", name = "Lock" },
  log = { icon = "", color = "#ffffff", name = "Log" },
  bak = { icon = "", color = "#6d8086", name = "Backup" },
  license = { icon = "", color = "#d0bf41", name = "License" },
}
M.by_filename = {
  [".gitignore"] = M.by_extension.gitignore,
  [".gitattributes"] = M.by_extension.gitattributes,
  [".gitmodules"] = M.by_extension.gitmodules,
  ["Makefile"] = M.by_extension.makefile,
  ["makefile"] = M.by_extension.makefile,
  ["CMakeLists.txt"] = M.by_extension.cmake,
  ["Dockerfile"] = M.by_extension.dockerfile,
  ["docker-compose.yml"] = { icon = "", color = "#458ee6", name = "Docker Compose" },
  ["docker-compose.yaml"] = { icon = "", color = "#458ee6", name = "Docker Compose" },
  [".env"] = M.by_extension.env,
  [".env.local"] = M.by_extension.env,
  [".env.development"] = M.by_extension.env,
  [".env.production"] = M.by_extension.env,
  ["package.json"] = { icon = "", color = "#e8274b", name = "npm" },
  ["package-lock.json"] = { icon = "", color = "#7a0d21", name = "npm Lock" },
  ["Cargo.toml"] = { icon = "", color = "#dea584", name = "Cargo" },
  ["Cargo.lock"] = { icon = "", color = "#dea584", name = "Cargo Lock" },
  ["go.mod"] = { icon = "", color = "#519aba", name = "Go Module" },
  ["go.sum"] = { icon = "", color = "#519aba", name = "Go Sum" },
  ["pyproject.toml"] = { icon = "", color = "#ffbc03", name = "PyProject" },
  ["requirements.txt"] = { icon = "", color = "#ffbc03", name = "Requirements" },
  ["Gemfile"] = { icon = "", color = "#cc342d", name = "Gemfile" },
  ["Gemfile.lock"] = { icon = "", color = "#cc342d", name = "Gemfile Lock" },
  ["init.lua"] = M.by_extension.lua,
  ["README.md"] = { icon = "", color = "#519aba", name = "Readme" },
  ["LICENSE"] = M.by_extension.license,
  ["LICENSE.md"] = M.by_extension.license,
  ["LICENSE.txt"] = M.by_extension.license,
}
M.default = { icon = "", color = "#6d8086", name = "File" }
M.directory = { icon = "", color = "#7ebae4", name = "Directory" }
function M.get_icon(filename, opts)
  opts = opts or {}
  if not filename or filename == "" then
    return M.default.icon, M.default.color
  end
  local by_name = M.by_filename[filename]
  if by_name then
    return by_name.icon, opts.default and M.default.color or by_name.color
  end
  local basename = vim.fn.fnamemodify(filename, ":t")
  by_name = M.by_filename[basename]
  if by_name then
    return by_name.icon, opts.default and M.default.color or by_name.color
  end
  local ext = vim.fn.fnamemodify(filename, ":e"):lower()
  local by_ext = M.by_extension[ext]
  if by_ext then
    return by_ext.icon, opts.default and M.default.color or by_ext.color
  end
  return M.default.icon, M.default.color
end
function M.get_dir_icon()
  return M.directory.icon, M.directory.color
end
function M.get_icon_by_filetype(ft, opts)
  local ft_to_ext = {
    python = "py",
    javascript = "js",
    typescript = "ts",
    typescriptreact = "tsx",
    javascriptreact = "jsx",
    markdown = "md",
    cpp = "cpp",
    lua = "lua",
    rust = "rs",
    go = "go",
    sh = "sh",
    bash = "bash",
    zsh = "zsh",
    vim = "vim",
    html = "html",
    css = "css",
    json = "json",
    yaml = "yaml",
    toml = "toml",
  }
  local ext = ft_to_ext[ft] or ft
  local icon, color = M.get_icon("file." .. ext, opts)
  return icon, color
end
function M.setup_highlights()
  for ext, info in pairs(M.by_extension) do
    local hl_group = "DevIcon" .. ext:gsub("^%l", string.upper)
    vim.api.nvim_set_hl(0, hl_group, { fg = info.color, default = true })
  end
  vim.api.nvim_set_hl(0, "DevIconDefault", { fg = M.default.color, default = true })
  vim.api.nvim_set_hl(0, "DevIconDirectory", { fg = M.directory.color, default = true })
end
return M

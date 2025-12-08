local M = {}
M.available = {
  "python",
  "lua",
  "typescript",
  "zig",
  "c",
  "rust",
  "go",
  "crystal",
  "odin",
  "nim",
}
function M.setup()
  local config = require("ember.config")
  for _, lang in ipairs(M.available) do
    local lang_config = config.lsp.langs[lang]
    if lang_config and lang_config.enabled ~= false then
      local ok, lang_module = pcall(require, "ember.lsp.langs." .. lang)
      if ok then
        lang_module.setup(lang_config)
      end
    end
  end
end
return M

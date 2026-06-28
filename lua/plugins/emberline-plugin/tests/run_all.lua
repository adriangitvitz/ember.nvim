-- Run all test specs
local M = {}

function M.run()
  -- Load test framework
  require("minimal_init")

  print("Running Emberline Tests")
  print(string.rep("=", 40))

  -- Run each spec file
  local specs = {
    "nodes_spec",
    "utils_spec",
    "state_spec",
    "layout_spec",
    "jump_spec",
    "render_spec",
  }

  for _, spec in ipairs(specs) do
    local ok, err = pcall(require, spec)
    if ok then
      local mod = require(spec)
      if mod.run then
        mod.run()
      end
    else
      print("\nSkipping " .. spec .. " (not found or error)")
      if err then
        print("  " .. tostring(err))
      end
    end
  end

  Test.summary()
end

return M

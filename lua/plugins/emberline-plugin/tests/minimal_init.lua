-- Minimal init for running tests
-- Usage: nvim --headless -u tests/minimal_init.lua -c "lua require('nodes_spec').run(); Test.summary()"

-- Set up runtime path to include the plugin
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(plugin_root)
vim.opt.rtp:prepend(plugin_root .. "/lua")

-- Add to Lua package path
package.path = plugin_root .. "/lua/?.lua;" .. plugin_root .. "/lua/?/init.lua;" .. package.path
package.path = plugin_root .. "/tests/?.lua;" .. package.path

-- Disable swap files for tests
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Simple test framework
_G.Test = {}

local passed = 0
local failed = 0
local current_describe = ""

function Test.describe(name, fn)
  current_describe = name
  print("\n" .. name)
  fn()
  current_describe = ""
end

function Test.it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  ✓ " .. name)
  else
    failed = failed + 1
    print("  ✗ " .. name)
    print("    " .. tostring(err))
  end
end

function Test.expect(value)
  return {
    to_equal = function(expected)
      if value ~= expected then
        error(string.format("Expected %s to equal %s", vim.inspect(value), vim.inspect(expected)))
      end
    end,
    to_be = function(expected)
      if value ~= expected then
        error(string.format("Expected %s to be %s", vim.inspect(value), vim.inspect(expected)))
      end
    end,
    to_be_truthy = function()
      if not value then
        error(string.format("Expected %s to be truthy", vim.inspect(value)))
      end
    end,
    to_be_falsy = function()
      if value then
        error(string.format("Expected %s to be falsy", vim.inspect(value)))
      end
    end,
    to_be_nil = function()
      if value ~= nil then
        error(string.format("Expected %s to be nil", vim.inspect(value)))
      end
    end,
    to_be_type = function(expected_type)
      if type(value) ~= expected_type then
        error(string.format("Expected type %s but got %s", expected_type, type(value)))
      end
    end,
    to_have_length = function(expected_len)
      local actual_len = #value
      if actual_len ~= expected_len then
        error(string.format("Expected length %d but got %d", expected_len, actual_len))
      end
    end,
    to_contain = function(expected)
      if type(value) == "string" then
        if not string.find(value, expected, 1, true) then
          error(string.format("Expected %q to contain %q", value, expected))
        end
      elseif type(value) == "table" then
        local found = false
        for _, v in ipairs(value) do
          if v == expected then
            found = true
            break
          end
        end
        if not found then
          error(string.format("Expected table to contain %s", vim.inspect(expected)))
        end
      else
        error("to_contain only works with strings and tables")
      end
    end,
    to_match = function(pattern)
      if not string.match(value, pattern) then
        error(string.format("Expected %q to match pattern %q", value, pattern))
      end
    end,
  }
end

function Test.summary()
  print("\n" .. string.rep("-", 40))
  print(string.format("Tests: %d passed, %d failed", passed, failed))
  if failed > 0 then
    print("FAILED")
    vim.cmd("cq 1")
  else
    print("PASSED")
    vim.cmd("q")
  end
end

function Test.reset()
  passed = 0
  failed = 0
end

-- Export for global access
_G.describe = Test.describe
_G.it = Test.it
_G.expect = Test.expect

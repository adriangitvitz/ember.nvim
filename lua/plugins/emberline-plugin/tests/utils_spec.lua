-- Tests for emberline.utils module
local M = {}

function M.run()
  local utils = require("emberline.utils")

  describe("emberline.utils", function()
    describe("get_buffer_name()", function()
      it("returns filename from full path", function()
        expect(utils.get_buffer_name("/home/user/project/file.lua")).to_equal("file.lua")
      end)

      it("returns filename from relative path", function()
        expect(utils.get_buffer_name("src/main.lua")).to_equal("main.lua")
      end)

      it("handles path with no directory", function()
        expect(utils.get_buffer_name("file.txt")).to_equal("file.txt")
      end)

      it("returns [No Name] for empty string", function()
        expect(utils.get_buffer_name("")).to_equal("[No Name]")
      end)

      it("returns [No Name] for nil", function()
        expect(utils.get_buffer_name(nil)).to_equal("[No Name]")
      end)
    end)

    describe("truncate()", function()
      it("returns text unchanged if shorter than max", function()
        expect(utils.truncate("hello", 10)).to_equal("hello")
      end)

      it("truncates long text with ellipsis", function()
        local result = utils.truncate("hello world", 8)
        expect(vim.fn.strdisplaywidth(result) <= 8).to_be_truthy()
        expect(result).to_contain("…")
      end)

      it("handles exact length", function()
        expect(utils.truncate("hello", 5)).to_equal("hello")
      end)

      it("handles max_length of 1", function()
        local result = utils.truncate("hello", 1)
        expect(vim.fn.strdisplaywidth(result) <= 1).to_be_truthy()
      end)

      it("handles empty string", function()
        expect(utils.truncate("", 10)).to_equal("")
      end)
    end)

    describe("unique_name()", function()
      it("returns original name when no conflicts", function()
        local names = {
          { path = "/a/b/file.lua", name = "file.lua" },
        }
        local result = utils.unique_name(names, 1)
        expect(result).to_equal("file.lua")
      end)

      it("adds parent directory when names conflict", function()
        local names = {
          { path = "/project/src/init.lua", name = "init.lua" },
          { path = "/project/lib/init.lua", name = "init.lua" },
        }
        local result1 = utils.unique_name(names, 1)
        local result2 = utils.unique_name(names, 2)
        -- Should be different
        expect(result1 ~= result2).to_be_truthy()
        -- Should contain directory info
        expect(result1).to_contain("/")
      end)

      it("adds more path components if needed", function()
        local names = {
          { path = "/a/src/utils/init.lua", name = "init.lua" },
          { path = "/b/src/utils/init.lua", name = "init.lua" },
        }
        local result1 = utils.unique_name(names, 1)
        local result2 = utils.unique_name(names, 2)
        expect(result1 ~= result2).to_be_truthy()
      end)
    end)

    describe("is_valid_buffer()", function()
      it("returns false for invalid bufnr", function()
        expect(utils.is_valid_buffer(-1)).to_be_falsy()
        expect(utils.is_valid_buffer(0)).to_be_falsy()
      end)

      it("returns false for non-existent buffer", function()
        expect(utils.is_valid_buffer(99999)).to_be_falsy()
      end)
    end)

    describe("escape_tabline()", function()
      it("escapes percent signs", function()
        expect(utils.escape_tabline("50%")).to_equal("50%%")
      end)

      it("leaves text without percent unchanged", function()
        expect(utils.escape_tabline("hello")).to_equal("hello")
      end)

      it("escapes multiple percent signs", function()
        expect(utils.escape_tabline("a%b%c")).to_equal("a%%b%%c")
      end)
    end)

    describe("shallow_copy()", function()
      it("creates a copy of a table", function()
        local original = { a = 1, b = 2 }
        local copy = utils.shallow_copy(original)
        expect(copy.a).to_equal(1)
        expect(copy.b).to_equal(2)
        expect(copy ~= original).to_be_truthy()
      end)

      it("modifying copy does not affect original", function()
        local original = { a = 1 }
        local copy = utils.shallow_copy(original)
        copy.a = 999
        expect(original.a).to_equal(1)
      end)
    end)

    describe("index_of()", function()
      it("finds element in array", function()
        local arr = { "a", "b", "c" }
        expect(utils.index_of(arr, "b")).to_equal(2)
      end)

      it("returns nil for missing element", function()
        local arr = { "a", "b", "c" }
        expect(utils.index_of(arr, "z")).to_be_nil()
      end)

      it("handles empty array", function()
        expect(utils.index_of({}, "a")).to_be_nil()
      end)
    end)
  end)
end

return M

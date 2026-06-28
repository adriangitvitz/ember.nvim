-- Tests for emberline.nodes module
local M = {}

function M.run()
  local nodes = require("emberline.nodes")

  describe("emberline.nodes", function()
    describe("create()", function()
      it("returns a node with hl and text fields", function()
        local node = nodes.create("TestHl", "hello")
        expect(node.hl).to_equal("TestHl")
        expect(node.text).to_equal("hello")
      end)

      it("handles empty text", function()
        local node = nodes.create("Hl", "")
        expect(node.text).to_equal("")
      end)

      it("handles nil highlight as empty string", function()
        local node = nodes.create(nil, "text")
        expect(node.hl).to_equal("")
      end)
    end)

    describe("width()", function()
      it("calculates display width of single node", function()
        local node = nodes.create("Hl", "hello")
        expect(nodes.width(node)).to_equal(5)
      end)

      it("handles unicode characters correctly", function()
        local node = nodes.create("Hl", "×")
        expect(nodes.width(node)).to_equal(1)
      end)

      it("handles wide unicode characters", function()
        local node = nodes.create("Hl", "文")
        -- CJK characters are typically 2 cells wide
        expect(nodes.width(node)).to_equal(2)
      end)

      it("returns 0 for empty text", function()
        local node = nodes.create("Hl", "")
        expect(nodes.width(node)).to_equal(0)
      end)
    end)

    describe("list_width()", function()
      it("calculates total width of node list", function()
        local list = {
          nodes.create("Hl1", "abc"),
          nodes.create("Hl2", "de"),
        }
        expect(nodes.list_width(list)).to_equal(5)
      end)

      it("returns 0 for empty list", function()
        expect(nodes.list_width({})).to_equal(0)
      end)
    end)

    describe("insert()", function()
      it("appends node to list", function()
        local list = {}
        nodes.insert(list, nodes.create("Hl", "a"))
        expect(#list).to_equal(1)
        expect(list[1].text).to_equal("a")
      end)

      it("maintains order of insertion", function()
        local list = {}
        nodes.insert(list, nodes.create("Hl", "first"))
        nodes.insert(list, nodes.create("Hl", "second"))
        expect(list[1].text).to_equal("first")
        expect(list[2].text).to_equal("second")
      end)
    end)

    describe("insert_many()", function()
      it("appends multiple nodes to list", function()
        local list = { nodes.create("Hl", "existing") }
        local new_nodes = {
          nodes.create("Hl", "a"),
          nodes.create("Hl", "b"),
        }
        nodes.insert_many(list, new_nodes)
        expect(#list).to_equal(3)
        expect(list[2].text).to_equal("a")
        expect(list[3].text).to_equal("b")
      end)
    end)

    describe("to_string()", function()
      it("produces correct tabline syntax with highlight", function()
        local list = { nodes.create("TestHl", "hello") }
        local result = nodes.to_string(list)
        expect(result).to_equal("%#TestHl#hello")
      end)

      it("handles multiple nodes with different highlights", function()
        local list = {
          nodes.create("Hl1", "a"),
          nodes.create("Hl2", "b"),
        }
        local result = nodes.to_string(list)
        expect(result).to_equal("%#Hl1#a%#Hl2#b")
      end)

      it("escapes percent signs in text", function()
        local list = { nodes.create("Hl", "50%") }
        local result = nodes.to_string(list)
        expect(result).to_contain("50%%")
      end)

      it("returns empty string for empty list", function()
        expect(nodes.to_string({})).to_equal("")
      end)

      it("handles nodes with empty highlight", function()
        local list = { nodes.create("", "text") }
        local result = nodes.to_string(list)
        -- Should still output text even without highlight
        expect(result).to_contain("text")
      end)
    end)

    describe("slice_left()", function()
      it("truncates from right to fit max_width", function()
        local list = {
          nodes.create("Hl", "hello"),
          nodes.create("Hl", "world"),
        }
        local result = nodes.slice_left(list, 7)
        local str = nodes.to_string(result)
        -- Should keep "hello" and part of "world" up to 7 chars total
        expect(#str > 0).to_be_truthy()
      end)

      it("returns full list if max_width exceeds total width", function()
        local list = {
          nodes.create("Hl", "ab"),
          nodes.create("Hl", "cd"),
        }
        local result = nodes.slice_left(list, 100)
        expect(nodes.list_width(result)).to_equal(4)
      end)

      it("returns empty list for max_width 0", function()
        local list = { nodes.create("Hl", "text") }
        local result = nodes.slice_left(list, 0)
        expect(#result).to_equal(0)
      end)
    end)

    describe("slice_right()", function()
      it("truncates from left to fit max_width", function()
        local list = {
          nodes.create("Hl", "hello"),
          nodes.create("Hl", "world"),
        }
        local result = nodes.slice_right(list, 7)
        -- Should keep end portion fitting 7 chars
        expect(nodes.list_width(result) <= 7).to_be_truthy()
      end)

      it("returns full list if max_width exceeds total width", function()
        local list = {
          nodes.create("Hl", "ab"),
          nodes.create("Hl", "cd"),
        }
        local result = nodes.slice_right(list, 100)
        expect(nodes.list_width(result)).to_equal(4)
      end)
    end)
  end)
end

return M

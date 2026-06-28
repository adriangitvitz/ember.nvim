-- Tests for emberline.render module
local M = {}

function M.run()
  local render = require("emberline.render")

  describe("emberline.render", function()
    describe("build_buffer_segment()", function()
      it("creates nodes for a buffer", function()
        local nodes = render.build_buffer_segment({
          bufnr = 1,
          name = "test.lua",
          hl = "EmberlineInactive",
          modified = false,
          pinned = false,
        })
        expect(#nodes > 0).to_be_truthy()
      end)

      it("includes buffer name in output", function()
        local nodes = render.build_buffer_segment({
          bufnr = 1,
          name = "test.lua",
          hl = "EmberlineInactive",
        })
        local str = require("emberline.nodes").to_string(nodes)
        expect(str).to_contain("test.lua")
      end)

      it("includes modified indicator when modified", function()
        local nodes = render.build_buffer_segment({
          bufnr = 1,
          name = "test.lua",
          hl = "EmberlineInactive",
          modified = true,
          modified_icon = "[+]",
        })
        local str = require("emberline.nodes").to_string(nodes)
        expect(str).to_contain("[+]")
      end)

      it("includes pinned indicator when pinned", function()
        local nodes = render.build_buffer_segment({
          bufnr = 1,
          name = "test.lua",
          hl = "EmberlineInactive",
          pinned = true,
          pinned_icon = "",
        })
        local str = require("emberline.nodes").to_string(nodes)
        expect(str).to_contain("")
      end)

      it("includes close button when enabled", function()
        local nodes = render.build_buffer_segment({
          bufnr = 1,
          name = "test.lua",
          hl = "EmberlineInactive",
          show_close = true,
          close_icon = "×",
        })
        local str = require("emberline.nodes").to_string(nodes)
        expect(str).to_contain("×")
      end)
    end)

    describe("build_click_handler()", function()
      it("generates correct click handler syntax", function()
        local handler = render.build_click_handler(5)
        expect(handler).to_contain("%5@")
        expect(handler).to_contain("@")
      end)

      it("includes lua function reference", function()
        local handler = render.build_click_handler(1)
        expect(handler).to_contain("v:lua.EmberlineClick")
      end)
    end)

    describe("generate_tabline()", function()
      it("returns string", function()
        local state = require("emberline.state")
        state.reset()
        local result = render.generate_tabline()
        expect(result).to_be_type("string")
      end)

      it("includes highlight groups", function()
        local state = require("emberline.state")
        state.reset()
        state.add_buffer(1)
        state.set_name(1, "test.lua")
        local result = render.generate_tabline()
        expect(result).to_contain("%#")
      end)

      it("ends with fill highlight", function()
        local state = require("emberline.state")
        state.reset()
        local result = render.generate_tabline()
        expect(result).to_contain("EmberlineFill")
      end)
    end)

    describe("render_jump_letter()", function()
      it("renders letter for buffer in jump mode", function()
        local result = render.render_jump_letter("a", "EmberlineJump")
        expect(result).to_be_type("table")
        expect(#result > 0).to_be_truthy()
      end)

      it("includes the letter", function()
        local nodes = render.render_jump_letter("x", "EmberlineJump")
        local str = require("emberline.nodes").to_string(nodes)
        expect(str).to_contain("x")
      end)
    end)
  end)
end

return M

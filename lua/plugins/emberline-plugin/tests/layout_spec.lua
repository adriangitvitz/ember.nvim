-- Tests for emberline.layout module
local M = {}

function M.run()
  local layout = require("emberline.layout")

  describe("emberline.layout", function()
    describe("calculate()", function()
      it("returns layout data with width fields", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 10, 15, 20 },
          pinned_count = 0,
        })
        expect(result).to_be_type("table")
        expect(result.available_width).to_be_type("number")
      end)

      it("calculates correct available width", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 10, 10, 10 },
          pinned_count = 0,
          left_offset = 0,
          right_offset = 0,
        })
        expect(result.available_width).to_equal(100)
      end)

      it("subtracts sidebar offsets from available width", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 10, 10 },
          pinned_count = 0,
          left_offset = 20,
          right_offset = 10,
        })
        expect(result.available_width).to_equal(70)
      end)

      it("calculates total buffer width", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 10, 15, 20 },
          pinned_count = 0,
        })
        expect(result.total_buffer_width).to_equal(45)
      end)

      it("detects overflow when buffers exceed available width", function()
        local result = layout.calculate({
          total_width = 50,
          buffer_widths = { 20, 20, 20 },
          pinned_count = 0,
        })
        expect(result.overflow).to_be_truthy()
      end)

      it("detects no overflow when buffers fit", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 10, 10, 10 },
          pinned_count = 0,
        })
        expect(result.overflow).to_be_falsy()
      end)
    end)

    describe("calculate() with pinned buffers", function()
      it("separates pinned and unpinned width", function()
        local result = layout.calculate({
          total_width = 100,
          buffer_widths = { 15, 20, 25, 30 },
          pinned_count = 2,
        })
        expect(result.pinned_width).to_equal(35) -- 15 + 20
        expect(result.unpinned_width).to_equal(55) -- 25 + 30
      end)
    end)

    describe("get_scroll_max()", function()
      it("returns 0 when buffers fit", function()
        local result = layout.get_scroll_max({
          available_width = 100,
          total_buffer_width = 50,
        })
        expect(result).to_equal(0)
      end)

      it("returns positive value when overflow", function()
        local result = layout.get_scroll_max({
          available_width = 50,
          total_buffer_width = 100,
        })
        expect(result > 0).to_be_truthy()
      end)

      it("returns difference when overflow", function()
        local result = layout.get_scroll_max({
          available_width = 50,
          total_buffer_width = 80,
        })
        expect(result).to_equal(30)
      end)
    end)

    describe("get_visible_range()", function()
      it("returns full range when no scroll needed", function()
        local start_idx, end_idx = layout.get_visible_range({
          buffer_widths = { 10, 10, 10 },
          available_width = 100,
          scroll_offset = 0,
        })
        expect(start_idx).to_equal(1)
        expect(end_idx).to_equal(3)
      end)

      it("adjusts range based on scroll offset", function()
        local start_idx, end_idx = layout.get_visible_range({
          buffer_widths = { 20, 20, 20, 20, 20 },
          available_width = 50,
          scroll_offset = 20,
        })
        -- Should skip first buffer (width 20) and show what fits
        expect(start_idx).to_equal(2)
      end)

      it("returns empty range for zero width", function()
        local start_idx, end_idx = layout.get_visible_range({
          buffer_widths = { 10, 10 },
          available_width = 0,
          scroll_offset = 0,
        })
        expect(start_idx > end_idx).to_be_truthy()
      end)
    end)

    describe("calculate_buffer_width()", function()
      it("returns width for buffer name with padding", function()
        local width = layout.calculate_buffer_width({
          name = "test.lua",
          padding = 2,
          show_close = true,
          close_width = 2,
        })
        -- name (8) + padding (2*2) + close (2) = 14
        expect(width).to_equal(14)
      end)

      it("excludes close button width when not shown", function()
        local width = layout.calculate_buffer_width({
          name = "test.lua",
          padding = 1,
          show_close = false,
          close_width = 2,
        })
        -- name (8) + padding (1*2) = 10
        expect(width).to_equal(10)
      end)

      it("includes separator width", function()
        local width = layout.calculate_buffer_width({
          name = "test",
          padding = 1,
          show_close = false,
          separator_width = 1,
        })
        -- name (4) + padding (1*2) + separator (1) = 7
        expect(width).to_equal(7)
      end)
    end)
  end)
end

return M

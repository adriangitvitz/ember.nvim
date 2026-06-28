-- Tests for emberline.jump module
local M = {}

function M.run()
  local jump = require("emberline.jump")

  describe("emberline.jump", function()
    describe("assign_letters()", function()
      it("assigns letters to buffers", function()
        jump.reset()
        local letters = jump.assign_letters({ 1, 2, 3 })
        expect(#letters).to_equal(3)
        expect(letters[1]).to_be_type("string")
        expect(letters[2]).to_be_type("string")
        expect(letters[3]).to_be_type("string")
      end)

      it("uses home row keys first", function()
        jump.reset()
        local letters = jump.assign_letters({ 1, 2, 3, 4 })
        -- Home row keys: a, s, d, f, j, k, l, ;
        local home_row = { "a", "s", "d", "f", "j", "k", "l", ";" }
        local is_home_row = false
        for _, hr in ipairs(home_row) do
          if letters[1] == hr then
            is_home_row = true
            break
          end
        end
        expect(is_home_row).to_be_truthy()
      end)

      it("assigns unique letters", function()
        jump.reset()
        local letters = jump.assign_letters({ 1, 2, 3, 4, 5 })
        local seen = {}
        for _, letter in ipairs(letters) do
          expect(seen[letter]).to_be_falsy()
          seen[letter] = true
        end
      end)

      it("assigns stable letters for same buffer", function()
        jump.reset()
        local letters1 = jump.assign_letters({ 1, 2, 3 })
        local letters2 = jump.assign_letters({ 1, 2, 3 })
        -- Letters should be the same for same buffers
        expect(letters1[1]).to_equal(letters2[1])
        expect(letters1[2]).to_equal(letters2[2])
        expect(letters1[3]).to_equal(letters2[3])
      end)

      it("maintains letters when buffer list changes", function()
        jump.reset()
        local letters1 = jump.assign_letters({ 1, 2, 3 })
        local letters2 = jump.assign_letters({ 1, 4, 2, 3 }) -- New buffer 4 inserted
        -- Buffer 1, 2, 3 should keep their original letters
        -- Find indices
        local idx_1_in_2 = nil
        local idx_2_in_2 = nil
        local idx_3_in_2 = nil
        for i, bufnr in ipairs({ 1, 4, 2, 3 }) do
          if bufnr == 1 then idx_1_in_2 = i end
          if bufnr == 2 then idx_2_in_2 = i end
          if bufnr == 3 then idx_3_in_2 = i end
        end
        expect(letters2[idx_1_in_2]).to_equal(letters1[1])
        expect(letters2[idx_2_in_2]).to_equal(letters1[2])
        expect(letters2[idx_3_in_2]).to_equal(letters1[3])
      end)
    end)

    describe("get_letter()", function()
      it("returns assigned letter for buffer", function()
        jump.reset()
        jump.assign_letters({ 1, 2, 3 })
        local letter = jump.get_letter(1)
        expect(letter).to_be_type("string")
        expect(#letter).to_equal(1)
      end)

      it("returns nil for unknown buffer", function()
        jump.reset()
        jump.assign_letters({ 1, 2 })
        local letter = jump.get_letter(999)
        expect(letter).to_be_nil()
      end)
    end)

    describe("get_buffer_for_letter()", function()
      it("returns buffer number for letter", function()
        jump.reset()
        local letters = jump.assign_letters({ 1, 2, 3 })
        local bufnr = jump.get_buffer_for_letter(letters[2])
        expect(bufnr).to_equal(2)
      end)

      it("returns nil for unassigned letter", function()
        jump.reset()
        jump.assign_letters({ 1, 2 })
        local bufnr = jump.get_buffer_for_letter("z")
        expect(bufnr).to_be_nil()
      end)
    end)

    describe("is_active()", function()
      it("returns false by default", function()
        jump.reset()
        expect(jump.is_active()).to_be_falsy()
      end)

      it("returns true after entering jump mode", function()
        jump.reset()
        jump.enter()
        expect(jump.is_active()).to_be_truthy()
        jump.exit()
      end)

      it("returns false after exiting jump mode", function()
        jump.reset()
        jump.enter()
        jump.exit()
        expect(jump.is_active()).to_be_falsy()
      end)
    end)

    describe("toggle()", function()
      it("enters jump mode when inactive", function()
        jump.reset()
        jump.toggle()
        expect(jump.is_active()).to_be_truthy()
        jump.exit()
      end)

      it("exits jump mode when active", function()
        jump.reset()
        jump.enter()
        jump.toggle()
        expect(jump.is_active()).to_be_falsy()
      end)
    end)
  end)
end

return M

return {
  "ThePrimeagen/harpoon",
  enabled = false,
  branch = "harpoon2",
  -- keys = {
  --   {
  --     "<leader>H",
  --     function()
  --       require("harpoon"):list():add()
  --     end,
  --     desc = "Harpoon File",
  --   },
  -- },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({ settings = {
      save_on_toggle = true,
      sync_on_ui_close = true,
    } })
    harpoon:extend({
      UI_CREATE = function(cx)
        vim.keymap.set("n", "<C-v>", function()
          harpoon.ui:select_menu_item({ vsplit = true })
        end, { buffer = cx.bufnr })

        vim.keymap.set("n", "<C-x>", function()
          harpoon.ui:select_menu_item({ split = true })
        end, { buffer = cx.bufnr })

        vim.keymap.set("n", "<C-t>", function()
          harpoon.ui:select_menu_item({ tabedit = true })
        end, { buffer = cx.bufnr })
      end,
    })
  end,
}
